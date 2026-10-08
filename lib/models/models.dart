import 'dart:convert';
import 'package:intl/intl.dart';

/// ---------------------------------------------------------------------------
/// Roles
/// ---------------------------------------------------------------------------
enum StaffRole { packer, delivery }

extension StaffRoleX on StaffRole {
  String get label => this == StaffRole.packer ? 'Packer' : 'Delivery';

  static StaffRole fromString(String? role) {
    if (role == null) return StaffRole.packer;
    final r = role.toUpperCase().trim();
    if (r == 'DELIVERY' || r == 'DELIVERY_PERSON') {
      return StaffRole.delivery;
    }
    return StaffRole.packer;
  }
}

/// ---------------------------------------------------------------------------
/// Staff user
/// ---------------------------------------------------------------------------
class StaffUser {
  final String id;
  final String storeId;
  final String name;
  final StaffRole role;
  final String store;
  final String email;
  final String phone;
  final String employeeId;
  final String storeAddress;

  const StaffUser({
    this.id = '',
    this.storeId = '',
    required this.name,
    required this.role,
    required this.store,
    required this.email,
    required this.phone,
    required this.employeeId,
    required this.storeAddress,
  });

  factory StaffUser.fromMap(Map<String, dynamic> map, {required String email}) {
    final storeData = map['stores'] as Map<String, dynamic>? ?? {};
    final storeName = storeData['name'] as String? ?? 'Kmart Store';
    final storeAddr = storeData['address'] as String? ?? '';

    return StaffUser(
      id: map['id']?.toString() ?? '',
      storeId: map['store_id']?.toString() ?? '',
      name: map['name'] as String? ?? 'Staff Member',
      role: StaffRoleX.fromString(map['role'] as String?),
      store: storeName,
      email: email,
      phone: map['phone'] as String? ?? '',
      employeeId: map['employee_id'] as String? ?? 'EMP-000',
      storeAddress: storeAddr,
    );
  }

  /// "Amit Sharma" -> "AS"
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// ---------------------------------------------------------------------------
/// Orders (packer side)
/// ---------------------------------------------------------------------------
class OrderItem {
  final String name;
  final int quantity;
  final double? unitMrp;
  final double? tax;
  final double? lineTotalMrp;

  const OrderItem({
    required this.name,
    required this.quantity,
    this.unitMrp,
    this.tax,
    this.lineTotalMrp,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? prod;
    final rawProd = map['products'];
    if (rawProd is Map<String, dynamic>) {
      prod = rawProd;
    } else if (rawProd is Map) {
      prod = Map<String, dynamic>.from(rawProd);
    } else if (rawProd is List &&
        rawProd.isNotEmpty &&
        rawProd.first is Map) {
      prod = Map<String, dynamic>.from(rawProd.first as Map);
    }

    final name = prod?['name'] ??
        map['product_name'] ??
        map['name'] ??
        map['title'] ??
        map['item_name'] ??
        map['product_title'] ??
        'Item';

    final unitMrp = (prod?['selling_price'] ??
            prod?['mrp'] ??
            map['unit_mrp'] ??
            map['mrp'] ??
            map['price']) as num?;

    final lineTotal =
        (map['line_total_mrp'] ?? map['line_total'] ?? map['total']) as num?;
    final qty = (map['quantity'] ?? map['qty'] ?? 1) as int;

    return OrderItem(
      name: name.toString(),
      quantity: qty,
      unitMrp: unitMrp?.toDouble(),
      tax: (map['tax'] as num?)?.toDouble(),
      lineTotalMrp:
          lineTotal?.toDouble() ?? ((unitMrp?.toDouble() ?? 0.0) * qty),
    );
  }
}

enum PackStatus { toPack, packed }

extension PackStatusX on PackStatus {
  String get label => this == PackStatus.toPack ? 'To Pack' : 'Packed';
}

class PackerOrder {
  final String id;
  final String rawId;
  final String time;
  final String? date;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final int totalItems;
  final double orderValue;
  final String customerName;
  final String phone;
  final String addressLine1;
  PackStatus status;

  PackerOrder({
    required this.id,
    String? rawId,
    required this.time,
    this.date,
    this.createdAt,
    required this.items,
    required this.totalItems,
    required this.orderValue,
    this.customerName = 'Customer',
    this.phone = 'N/A',
    this.addressLine1 = '',
    this.status = PackStatus.toPack,
  }) : rawId = rawId ?? id;

  factory PackerOrder.fromMap(
    Map<String, dynamic> map, {
    List<OrderItem> items = const [],
  }) {
    final dtStr = map['created_at'] as String?;
    DateTime? dt;
    String formattedTime = 'Just now';
    String? formattedDate;

    if (dtStr != null) {
      dt = DateTime.tryParse(dtStr)?.toLocal();
      if (dt != null) {
        formattedTime = DateFormat('h:mm a').format(dt);
        formattedDate = DateFormat('d MMM yyyy').format(dt);
      }
    }

    // Helper: normalise any map-like value
    Map<String, dynamic>? toMap(dynamic val) {
      if (val is Map<String, dynamic>) return val;
      if (val is Map) return Map<String, dynamic>.from(val);
      if (val is List && val.isNotEmpty && val.first is Map) {
        return Map<String, dynamic>.from(val.first as Map);
      }
      if (val is String && val.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return null;
    }

    String? firstNonEmpty(List<dynamic> candidates) {
      for (final c in candidates) {
        if (c != null) {
          final s = c.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'null' && s.toLowerCase() != 'n/a') {
            return s;
          }
        }
      }
      return null;
    }

    final custMap = toMap(map['customers']) ?? toMap(map['customer']);
    final custSnap = toMap(map['customer_snapshot']);
    final addrSnap = toMap(map['delivery_address_snapshot']) ??
        toMap(map['shipping_address']) ??
        toMap(map['address']);

    final customerName = firstNonEmpty([
          custSnap?['name'],
          custSnap?['full_name'],
          custMap?['name'],
          addrSnap?['name'],
          addrSnap?['full_name'],
          addrSnap?['recipient_name'],
          map['customer_name'],
        ]) ??
        'Customer';

    final phone = firstNonEmpty([
          custSnap?['phone'],
          custSnap?['mobile'],
          custSnap?['phone_number'],
          custMap?['phone'],
          custMap?['mobile'],
          addrSnap?['phone'],
          addrSnap?['mobile'],
          addrSnap?['contact_number'],
          addrSnap?['phone_number'],
          map['customer_phone'],
        ]) ??
        'N/A';

    // Build a short address line from snapshot
    String addressLine1 = '';
    if (addrSnap != null) {
      final parts = [
        addrSnap['addressLine1'] ?? addrSnap['line1'] ?? addrSnap['address_line1'] ?? addrSnap['street'] ?? '',
        addrSnap['addressLine2'] ?? addrSnap['line2'] ?? addrSnap['area'] ?? addrSnap['landmark'] ?? '',
        addrSnap['city'] ?? '',
        addrSnap['pincode'] ?? addrSnap['postalCode'] ?? addrSnap['postal_code'] ?? '',
      ].map((s) => s.toString().trim()).where((s) => s.isNotEmpty && s.toLowerCase() != 'null').toList();
      addressLine1 = parts.join(', ');
    }

    final totalQty = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalVal = (map['total'] as num?)?.toDouble() ?? 0.0;
    final orderNum = map['order_number']?.toString() ??
        'ORD-${map['id']?.toString().substring(0, 8).toUpperCase()}';

    return PackerOrder(
      id: orderNum,
      rawId: map['id']?.toString(),
      time: formattedTime,
      date: formattedDate,
      createdAt: dt,
      items: items,
      totalItems: totalQty > 0 ? totalQty : items.length,
      orderValue: totalVal,
      customerName: customerName,
      phone: phone,
      addressLine1: addressLine1,
      status: map['status'] == 'PACKED' ? PackStatus.packed : PackStatus.toPack,
    );
  }

  factory PackerOrder.fromHistoryMap({
    required Map<String, dynamic> orderMap,
    required Map<String, dynamic> historyMap,
    List<OrderItem> items = const [],
  }) {
    final changedAtStr = historyMap['changed_at'] as String?;
    DateTime? dt;
    String formattedTime = '';
    String? formattedDate;

    if (changedAtStr != null) {
      dt = DateTime.tryParse(changedAtStr)?.toLocal();
      if (dt != null) {
        formattedTime = DateFormat('h:mm a').format(dt);
        formattedDate = DateFormat('d MMM yyyy').format(dt);
      }
    }

    final base = PackerOrder.fromMap(orderMap, items: items);

    return PackerOrder(
      id: base.id,
      rawId: (orderMap['id'] ?? historyMap['order_id'])?.toString(),
      time: formattedTime,
      date: formattedDate,
      createdAt: dt ?? base.createdAt,
      items: base.items,
      totalItems: base.totalItems,
      orderValue: base.orderValue,
      customerName: base.customerName,
      phone: base.phone,
      addressLine1: base.addressLine1,
      status: PackStatus.packed,
    );
  }
}

/// ---------------------------------------------------------------------------
/// Deliveries (delivery side)
/// ---------------------------------------------------------------------------
enum PaymentMode { cod, paidOnline }

extension PaymentModeX on PaymentMode {
  String get label => this == PaymentMode.cod ? 'COD' : 'Paid Online';
}

enum DeliveryStatus { ready, inProgress, delivered }

extension DeliveryStatusX on DeliveryStatus {
  String get label {
    switch (this) {
      case DeliveryStatus.ready:
        return 'Ready for Delivery';
      case DeliveryStatus.inProgress:
        return 'Out for Delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
    }
  }

  static DeliveryStatus fromOrderStatus(String? status) {
    if (status == 'OUT_FOR_DELIVERY') return DeliveryStatus.inProgress;
    if (status == 'DELIVERED') return DeliveryStatus.delivered;
    return DeliveryStatus.ready;
  }
}

class DeliveryOrder {
  final String id;
  final String rawId;
  final String time;
  final String? date;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final int itemCount;
  final String customerName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final double amount;
  final PaymentMode payment;
  DeliveryStatus status;

  DeliveryOrder({
    required this.id,
    String? rawId,
    required this.time,
    this.date,
    this.createdAt,
    this.items = const [],
    required this.itemCount,
    required this.customerName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.amount,
    required this.payment,
    this.status = DeliveryStatus.ready,
  }) : rawId = rawId ?? id;


  static (String, String) _formatAddress(Map<String, dynamic> addr) {
    final line1 = addr['addressLine1'] ??
        addr['line1'] ??
        addr['address_line1'] ??
        addr['street'] ??
        addr['street_address'] ??
        addr['streetAddress'] ??
        addr['house_no'] ??
        addr['houseNo'] ??
        addr['apartment'] ??
        addr['building'] ??
        addr['flat'] ??
        addr['address'] ??
        '';

    final line2 = addr['addressLine2'] ??
        addr['line2'] ??
        addr['address_line2'] ??
        addr['area'] ??
        addr['landmark'] ??
        addr['colony'] ??
        addr['locality'] ??
        '';

    final city = addr['city'] ?? '';
    final state = addr['state'] ?? '';
    final pincode = addr['pincode'] ??
        addr['postalCode'] ??
        addr['postal_code'] ??
        addr['zip'] ??
        addr['zipcode'] ??
        '';

    final primaryParts = [line1.toString(), line2.toString()]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
        .toList();

    final secondaryParts =
        [city.toString(), state.toString(), pincode.toString()]
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.toLowerCase() != 'null')
            .toList();

    String formattedLine1 = 'Address';
    String formattedLine2 = '';

    if (primaryParts.isNotEmpty) {
      formattedLine1 = primaryParts.join(', ');
      if (secondaryParts.isNotEmpty) {
        formattedLine2 = secondaryParts.join(', ');
      }
    } else if (secondaryParts.isNotEmpty) {
      formattedLine1 = secondaryParts.join(', ');
    } else if (addr['formatted_address'] != null) {
      formattedLine1 = addr['formatted_address'].toString();
    }

    return (formattedLine1, formattedLine2);
  }

  factory DeliveryOrder.fromMap(
    Map<String, dynamic> map, {
    List<OrderItem> items = const [],
  }) {
    final dtStr = map['created_at'] as String?;
    DateTime? dt;
    String formattedTime = 'Just now';
    String? formattedDate;

    if (dtStr != null) {
      dt = DateTime.tryParse(dtStr)?.toLocal();
      if (dt != null) {
        formattedTime = DateFormat('h:mm a').format(dt);
        formattedDate = DateFormat('d MMM yyyy').format(dt);
      }
    }

    Map<String, dynamic>? toMap(dynamic val) {
      if (val is Map<String, dynamic>) return val;
      if (val is Map) return Map<String, dynamic>.from(val);
      if (val is List && val.isNotEmpty && val.first is Map) {
        return Map<String, dynamic>.from(val.first as Map);
      }
      if (val is String && val.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
          if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
            return Map<String, dynamic>.from(decoded.first as Map);
          }
        } catch (_) {}
      }
      return null;
    }

    String? extractFirstNonEmpty(List<dynamic> candidates) {
      for (final c in candidates) {
        if (c != null) {
          final str = c.toString().trim();
          if (str.isNotEmpty &&
              str.toLowerCase() != 'null' &&
              str.toLowerCase() != 'n/a') {
            return str;
          }
        }
      }
      return null;
    }

    // 1. Extract Customer Data from all possible sources
    final custMap = toMap(map['customers']) ?? toMap(map['customer']);
    final custSnap = toMap(map['customer_snapshot']);
    final addrSnap = toMap(map['delivery_address_snapshot']) ??
        toMap(map['shipping_address']) ??
        toMap(map['delivery_address']) ??
        toMap(map['address']);

    final name = extractFirstNonEmpty([
          custSnap?['name'],
          custSnap?['full_name'],
          custMap?['name'],
          custMap?['full_name'],
          addrSnap?['name'],
          addrSnap?['recipient_name'],
          addrSnap?['full_name'],
          map['customer_name'],
          map['recipient_name'],
        ]) ??
        'Customer';

    final phone = extractFirstNonEmpty([
          custSnap?['phone'],
          custSnap?['mobile'],
          custMap?['phone'],
          custMap?['mobile'],
          addrSnap?['phone'],
          addrSnap?['mobile'],
          addrSnap?['contact_number'],
          addrSnap?['phone_number'],
          map['customer_phone'],
          map['phone'],
          map['mobile'],
        ]) ??
        'N/A';

    // 2. Extract Address
    String addressLine1 = 'Address';
    String addressLine2 = '';

    // Check addresses inside custMap
    if (custMap != null && custMap['addresses'] != null) {
      final rawAddrs = custMap['addresses'];
      List<dynamic> addressList = [];
      if (rawAddrs is List) {
        addressList = rawAddrs;
      } else if (rawAddrs is Map) {
        addressList = [rawAddrs];
      }

      final addrMapList = addressList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (addrMapList.isNotEmpty) {
        final defaultAddr = addrMapList.firstWhere(
          (a) => a['is_default'] == true,
          orElse: () => addrMapList.first,
        );
        final (l1, l2) = _formatAddress(defaultAddr);
        if (l1 != 'Address') {
          addressLine1 = l1;
          addressLine2 = l2;
        }
      }
    }

    // Fallback to addrSnap (delivery_address_snapshot / shipping_address)
    if (addressLine1 == 'Address' && addrSnap != null && addrSnap.isNotEmpty) {
      final (l1, l2) = _formatAddress(addrSnap);
      if (l1 != 'Address') {
        addressLine1 = l1;
        addressLine2 = l2;
      }
    }

    // 3. Extract Order Items
    List<OrderItem> resolvedItems = List.from(items);
    final rawItems = map['order_items'] ??
        map['items'] ??
        map['line_items'] ??
        map['products'];
    if (resolvedItems.isEmpty) {
      List<dynamic> itemList = [];
      if (rawItems is List) {
        itemList = rawItems;
      } else if (rawItems is Map) {
        itemList = [rawItems];
      } else if (rawItems is String && rawItems.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(rawItems);
          if (decoded is List) itemList = decoded;
        } catch (_) {}
      }

      if (itemList.isNotEmpty) {
        resolvedItems = itemList
            .whereType<Map>()
            .map((item) => OrderItem.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    final totalQty =
        resolvedItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalVal = (map['total'] as num?)?.toDouble() ?? 0.0;
    final orderNum = map['order_number']?.toString() ??
        'ORD-${map['id']?.toString().substring(0, 8).toUpperCase()}';

    final payMethod = (map['payment_method'] as String?)?.toUpperCase();
    final payment = (payMethod == 'COD' ||
            payMethod == 'CASH_ON_DELIVERY' ||
            payMethod == 'CASH')
        ? PaymentMode.cod
        : PaymentMode.paidOnline;

    final st = DeliveryStatusX.fromOrderStatus(map['status'] as String?);

    return DeliveryOrder(
      id: orderNum,
      rawId: map['id']?.toString(),
      time: formattedTime,
      date: formattedDate,
      createdAt: dt,
      items: resolvedItems,
      itemCount: totalQty > 0
          ? totalQty
          : (resolvedItems.isNotEmpty
              ? totalQty
              : ((map['item_count'] ?? 1) as int)),
      customerName: name,
      phone: phone,
      addressLine1: addressLine1.isNotEmpty ? addressLine1 : 'Address',
      addressLine2: addressLine2,
      amount: totalVal,
      payment: payment,
      status: st,
    );
  }

  /// Convenience factory used when building a [DeliveryOrder] from an
  /// `order_status_history` row that embeds the related `orders` record.
  /// The [historyMap] timestamp is used for the display time; all other
  /// fields are sourced from [orderMap] via [DeliveryOrder.fromMap].
  factory DeliveryOrder.fromHistoryMap({
    required Map<String, dynamic> orderMap,
    required Map<String, dynamic> historyMap,
    List<OrderItem> items = const [],
  }) {
    final order = DeliveryOrder.fromMap(orderMap, items: items);

    // Override the time with changed_at from the history row
    final changedAtStr = historyMap['changed_at'] as String?;
    DateTime? dt;
    String formattedTime = order.time;
    String? formattedDate = order.date;

    if (changedAtStr != null) {
      dt = DateTime.tryParse(changedAtStr)?.toLocal();
      if (dt != null) {
        formattedTime = DateFormat('h:mm a').format(dt);
        formattedDate = DateFormat('d MMM yyyy').format(dt);
      }
    }

    return DeliveryOrder(
      id: order.id,
      rawId: order.rawId,
      time: formattedTime,
      date: formattedDate,
      createdAt: dt ?? order.createdAt,
      items: order.items,
      itemCount: order.itemCount,
      customerName: order.customerName,
      phone: order.phone,
      addressLine1: order.addressLine1,
      addressLine2: order.addressLine2,
      amount: order.amount,
      payment: order.payment,
      status: DeliveryStatus.delivered,
    );
  }

  String get shortAddress => addressLine1.contains(',')
      ? addressLine1.split(',').last.trim()
      : addressLine1;
}
