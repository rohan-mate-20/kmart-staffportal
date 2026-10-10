import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://rcrvqrmvzvjjsmvdezts.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_3wgxkfeAZztYhEEFeeE6pA_NI5qf8ZE';

  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase once at app startup
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }

  /// Sign in with email and password
  static Future<StaffUser> signIn({
    required String email,
    required String password,
  }) async {
    final authRes = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final authUser = authRes.user;
    if (authUser == null) {
      throw 'Login failed: Invalid credentials.';
    }

    final staffData = await client
        .from('staff')
        .select('id, name, role, store_id, employee_id, phone, stores(name, address)')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (staffData == null) {
      await client.auth.signOut();
      throw 'Access denied: No staff profile found for this account.';
    }

    final staffUser = StaffUser.fromMap(
      staffData,
      email: authUser.email ?? email,
    );

    // Register device token for push notifications
    await registerDeviceToken();

    return staffUser;
  }

  /// Fetch current staff profile
  static Future<StaffUser?> getCurrentStaff() async {
    final authUser = client.auth.currentUser;
    if (authUser == null) return null;

    final staffData = await client
        .from('staff')
        .select('id, name, role, store_id, employee_id, phone, stores(name, address)')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (staffData == null) return null;

    return StaffUser.fromMap(
      staffData,
      email: authUser.email ?? '',
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Register FCM device token
  static Future<void> registerDeviceToken([String? token]) async {
    try {
      if (token != null && token.isNotEmpty) {
        await client.functions.invoke('register-device-token', body: {
          'recipientType': 'STAFF',
          'deviceToken': token,
        });
      }
    } catch (e) {
      debugPrint('Device token registration warning: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Packer Dashboard & History
  // ---------------------------------------------------------------------------

  /// Query orders to pack (status: CONFIRMED for staff's store)
  static Future<List<PackerOrder>> getOrdersToPack(String storeId) async {
    final response = await client
        .from('orders')
        .select('''
          id,
          order_number,
          order_type,
          created_at,
          subtotal,
          delivery_fee,
          total,
          status,
          customer_snapshot,
          delivery_address_snapshot,
          customers (
            id,
            name,
            phone
          )
        ''')
        .eq('store_id', storeId)
        .eq('status', 'CONFIRMED')
        .order('created_at', ascending: true);

    final ordersData = List<Map<String, dynamic>>.from(response);

    final List<PackerOrder> orders = [];
    for (final orderMap in ordersData) {
      final orderId = orderMap['id'] as String;

      // Safe view: packer_order_items_view (MRP and quantity only)
      final itemsRes = await client
          .from('packer_order_items_view')
          .select('product_name, quantity, unit_mrp, tax, line_total_mrp')
          .eq('order_id', orderId);

      final items = (itemsRes as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList();

      orders.add(PackerOrder.fromMap(orderMap, items: items));
    }

    return orders;
  }

  /// Mark order as packed using update-order-status Edge Function
  static Future<void> markOrderPacked(String orderId) async {
    final res = await client.functions.invoke('update-order-status', body: {
      'orderId': orderId,
      'action': 'MARK_PACKED',
    });

    if (res.status != 200) {
      final data = res.data;
      if (data is Map && data.containsKey('error')) {
        throw data['error'].toString();
      }
      throw 'Failed to update order status (HTTP ${res.status})';
    }

    if (res.data is Map && res.data['error'] != null) {
      throw res.data['error'].toString();
    }
  }

  /// Fetch packer history (status: PACKED, changed_by: staff.id)
  static Future<List<PackerOrder>> getPackerHistory(String staffId) async {
    final response = await client
        .from('order_status_history')
        .select('''
          id,
          order_id,
          status,
          changed_at,
          orders (
            id,
            order_number,
            total,
            status,
            order_type,
            created_at,
            store_id,
            customer_id,
            payment_method,
            customers (
              id,
              name,
              phone,
              email,
              addresses (
                id,
                line1,
                line2,
                city,
                state,
                pincode,
                is_default
              )
            ),
            order_items (
              id,
              quantity,
              line_total,
              products (
                id,
                name,
                sku,
                selling_price
              )
            )
          )
        ''')
        .eq('status', 'PACKED')
        .eq('changed_by', staffId)
        .order('changed_at', ascending: false);

    final historyList = List<Map<String, dynamic>>.from(response);
    final List<PackerOrder> orders = [];

    for (final hist in historyList) {
      final orderMap = hist['orders'] as Map<String, dynamic>?;
      if (orderMap == null) continue;

      final order = PackerOrder.fromMap(orderMap);
      order.status = PackStatus.packed;
      orders.add(order);
    }

    return orders;
  }

  // ---------------------------------------------------------------------------
  // Delivery Dashboard & History
  // ---------------------------------------------------------------------------

  /// Query delivery orders (status in PACKED, OUT_FOR_DELIVERY, order_type: DELIVERY)
  static Future<List<DeliveryOrder>> getDeliveryOrders(String storeId) async {
    final response = await client
        .from('orders')
        .select('''
          id,
          order_number,
          total,
          status,
          order_type,
          created_at,
          store_id,
          customer_id,
          payment_method,
          customer_snapshot,
          delivery_address_snapshot,
          customers (
            id,
            name,
            phone,
            email,
            addresses (
              id,
              line1,
              line2,
              city,
              state,
              pincode,
              is_default
            )
          ),
          order_items (
            id,
            product_id,
            product_name,
            quantity,
            unit_mrp,
            unit_selling_price,
            line_total,
            products (
              id,
              name,
              sku,
              selling_price
            )
          )
        ''')
        .eq('store_id', storeId)
        .eq('order_type', 'DELIVERY')
        .inFilter('status', ['PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED'])
        .order('created_at', ascending: true);

    final list = List<Map<String, dynamic>>.from(response);

    // DIAGNOSTIC — check browser console (F12 → Console tab)
    if (list.isNotEmpty) {
      final first = list.first;
      debugPrint('=== DELIVERY ORDER DIAGNOSTIC ===');
      debugPrint('Keys returned: ${first.keys.toList()}');
      debugPrint('customer_snapshot raw: ${first['customer_snapshot']}');
      debugPrint('delivery_address_snapshot raw: ${first['delivery_address_snapshot']}');
      debugPrint('customers relation: ${first['customers']}');
      debugPrint('=================================');
    }

    return list.map((m) => DeliveryOrder.fromMap(m)).toList();
  }

  /// Mark order out for delivery
  static Future<void> markOrderOutForDelivery(String orderId) async {
    final res = await client.functions.invoke('update-order-status', body: {
      'orderId': orderId,
      'action': 'MARK_OUT_FOR_DELIVERY',
    });

    if (res.status != 200) {
      final data = res.data;
      if (data is Map && data.containsKey('error')) {
        throw data['error'].toString();
      }
      throw 'Failed to update order status (HTTP ${res.status})';
    }

    if (res.data is Map && res.data['error'] != null) {
      throw res.data['error'].toString();
    }
  }

  /// Mark order delivered
  static Future<void> markOrderDelivered(String orderId) async {
    final res = await client.functions.invoke('update-order-status', body: {
      'orderId': orderId,
      'action': 'MARK_DELIVERED',
    });

    if (res.status != 200) {
      final data = res.data;
      if (data is Map && data.containsKey('error')) {
        throw data['error'].toString();
      }
      throw 'Failed to update order status (HTTP ${res.status})';
    }

    if (res.data is Map && res.data['error'] != null) {
      throw res.data['error'].toString();
    }
  }

  /// Fetch delivery history (status: DELIVERED, changed_by: staff.id)
  static Future<List<DeliveryOrder>> getDeliveryHistory(String staffId) async {
    final response = await client
        .from('order_status_history')
        .select('''
          id,
          order_id,
          status,
          changed_at,
          orders (
            id,
            order_number,
            total,
            status,
            order_type,
            created_at,
            store_id,
            customer_id,
            payment_method,
            customer_snapshot,
            delivery_address_snapshot,
            customers (
              id,
              name,
              phone,
              email,
              addresses (
                id,
                line1,
                line2,
                city,
                state,
                pincode,
                is_default
              )
            ),
            order_items (
              id,
              product_id,
              product_name,
              quantity,
              unit_mrp,
              unit_selling_price,
              line_total,
              products (
                id,
                name,
                sku,
                selling_price
              )
            )
          )
        ''')
        .eq('status', 'DELIVERED')
        .eq('changed_by', staffId)
        .order('changed_at', ascending: false);

    final historyList = List<Map<String, dynamic>>.from(response);
    final List<DeliveryOrder> deliveries = [];

    for (final hist in historyList) {
      final orderMap = hist['orders'] as Map<String, dynamic>?;
      if (orderMap == null) continue;

      final delivery = DeliveryOrder.fromMap(orderMap);
      delivery.status = DeliveryStatus.delivered;
      deliveries.add(delivery);
    }

    return deliveries;
  }

  // ---------------------------------------------------------------------------
  // Staff Expenses Entry
  // ---------------------------------------------------------------------------

  /// Insert staff expense entry
  static Future<void> addExpense({
    required String staffId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final noteText = note?.trim() ?? '';

    try {
      await client.from('staff_expenses').insert({
        'staff_id': staffId,
        'amount': amount,
        'expense_date': formattedDate,
        'note': noteText,
      });
    } catch (_) {
      try {
        await client.from('staff_expenses').insert({
          'staff_id': staffId,
          'amount': amount,
          'date': formattedDate,
          'note': noteText,
        });
      } catch (_) {
        await client.from('staff_expenses').insert({
          'staff_id': staffId,
          'note':
              'Amount: ₹${amount.toStringAsFixed(0)} | Date: ${DateFormat('d MMM yyyy').format(date)}${noteText.isNotEmpty ? ' | Note: $noteText' : ''}',
        });
      }
    }
  }

  /// Fetch staff expenses
  static Future<List<Map<String, dynamic>>> getExpenses(String staffId) async {
    final res = await client
        .from('staff_expenses')
        .select('*')
        .eq('staff_id', staffId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}
