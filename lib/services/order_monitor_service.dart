import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'native_notification_service.dart';
import 'supabase_service.dart';

/// Realtime monitoring service that detects new orders and status updates
/// for staff (Packers & Delivery) and fires native Android system notifications.
class OrderMonitorService {
  OrderMonitorService._();
  static final OrderMonitorService instance = OrderMonitorService._();

  StaffUser? _currentUser;
  final Set<String> _knownOrderIds = {};
  final Map<String, String> _knownOrderStatuses = {};
  bool _isPrimed = false;
  RealtimeChannel? _realtimeChannel;
  Timer? _pollTimer;
  final Set<VoidCallback> _listeners = {};

  bool get isMonitoring => _currentUser != null;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      try {
        listener();
      } catch (e) {
        debugPrint('[OrderMonitorService] Listener error: $e');
      }
    }
  }

  /// Start monitoring orders for the logged-in staff member
  Future<void> start(StaffUser user, {VoidCallback? onOrdersChanged}) async {
    if (_currentUser?.id == user.id && _realtimeChannel != null) {
      if (onOrdersChanged != null) addListener(onOrdersChanged);
      return;
    }

    stop();
    _currentUser = user;
    if (onOrdersChanged != null) addListener(onOrdersChanged);

    // 1. Prime the initial cache so existing orders do not trigger spam alerts
    await _primeCache();

    // 2. Subscribe to Supabase Realtime channel on 'orders'
    _subscribeRealtime();

    // 3. Periodic poll fallback (every 20 seconds) for 100% reliability
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _pollOrders(),
    );
  }

  /// Stop monitoring and release resources (e.g. on staff logout)
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;

    if (_realtimeChannel != null) {
      try {
        SupabaseService.client.removeChannel(_realtimeChannel!);
      } catch (e) {
        debugPrint('[OrderMonitorService] removeChannel error: $e');
      }
      _realtimeChannel = null;
    }

    _currentUser = null;
    _knownOrderIds.clear();
    _knownOrderStatuses.clear();
    _isPrimed = false;
    _listeners.clear();
  }

  /// Prime the cache with existing orders on login
  Future<void> _primeCache() async {
    if (_currentUser == null) return;
    try {
      if (_currentUser!.role == StaffRole.packer) {
        final orders =
            await SupabaseService.getOrdersToPack(_currentUser!.storeId);
        for (final o in orders) {
          _knownOrderIds.add(o.id);
          _knownOrderStatuses[o.id] = 'CONFIRMED';
        }
      } else {
        final deliveries =
            await SupabaseService.getDeliveryOrders(_currentUser!.storeId);
        for (final d in deliveries) {
          _knownOrderIds.add(d.id);
          _knownOrderStatuses[d.id] = d.status == DeliveryStatus.inProgress
              ? 'OUT_FOR_DELIVERY'
              : 'PACKED';
        }
      }
    } catch (e) {
      debugPrint('[OrderMonitorService] Error priming cache: $e');
    } finally {
      _isPrimed = true;
    }
  }

  /// Subscribe to Supabase postgres change events
  void _subscribeRealtime() {
    if (_currentUser == null) return;
    final storeId = _currentUser!.storeId;

    try {
      _realtimeChannel = SupabaseService.client
          .channel('staff_orders_realtime_$storeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'store_id',
              value: storeId,
            ),
            callback: (payload) {
              _handleRealtimePayload(payload);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[OrderMonitorService] Realtime subscribe error: $e');
    }
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    final eventType = payload.eventType;
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    if (newRecord.isEmpty) return;

    final storeId = newRecord['store_id']?.toString() ?? '';
    if (_currentUser != null && storeId != _currentUser!.storeId) return;

    final orderId = newRecord['id']?.toString() ?? '';
    final orderNumber = newRecord['order_number']?.toString() ?? orderId;
    final newStatus = newRecord['status']?.toString() ?? '';
    final oldStatus = oldRecord['status']?.toString() ??
        _knownOrderStatuses[orderId] ??
        '';
    final orderType = newRecord['order_type']?.toString() ?? '';

    _processOrderEvent(
      orderId: orderId,
      orderNumber: orderNumber,
      newStatus: newStatus,
      oldStatus: oldStatus,
      orderType: orderType,
      isNewInsert: eventType == PostgresChangeEvent.insert,
    );
  }

  void _processOrderEvent({
    required String orderId,
    required String orderNumber,
    required String newStatus,
    required String oldStatus,
    required String orderType,
    required bool isNewInsert,
  }) {
    if (_currentUser == null) return;
    final role = _currentUser!.role;

    final isNewOrder = !_knownOrderIds.contains(orderId);
    _knownOrderIds.add(orderId);
    final statusChanged = newStatus.isNotEmpty && newStatus != oldStatus;
    if (newStatus.isNotEmpty) {
      _knownOrderStatuses[orderId] = newStatus;
    }

    if (!_isPrimed) return;

    bool shouldNotify = false;
    String title = '';
    String body = '';

    if (role == StaffRole.packer) {
      if ((isNewOrder || statusChanged) && newStatus == 'CONFIRMED') {
        shouldNotify = true;
        title = '📦 New Order to Pack: #$orderNumber';
        body =
            'New order arrived for ${_currentUser!.store}. Open app to pack items.';
      } else if (statusChanged && newStatus == 'CANCELLED') {
        shouldNotify = true;
        title = '⚠️ Order Cancelled: #$orderNumber';
        body = 'Order #$orderNumber was cancelled.';
      }
    } else if (role == StaffRole.delivery) {
      if (orderType == 'DELIVERY' || orderType.isEmpty) {
        if ((isNewOrder || statusChanged) && newStatus == 'PACKED') {
          shouldNotify = true;
          title = '🚚 Order Ready for Delivery: #$orderNumber';
          body = 'Order #$orderNumber is packed and ready for delivery pickup!';
        } else if (statusChanged && newStatus == 'OUT_FOR_DELIVERY') {
          shouldNotify = true;
          title = '🛵 Out for Delivery: #$orderNumber';
          body = 'Order #$orderNumber is on the way.';
        } else if (statusChanged && newStatus == 'DELIVERED') {
          shouldNotify = true;
          title = '✅ Order Delivered: #$orderNumber';
          body = 'Order #$orderNumber was delivered successfully.';
        } else if (statusChanged && newStatus == 'CANCELLED') {
          shouldNotify = true;
          title = '⚠️ Delivery Cancelled: #$orderNumber';
          body = 'Order #$orderNumber has been cancelled.';
        }
      }
    }

    if (shouldNotify) {
      NativeNotificationService.showNotification(
        title: title,
        body: body,
        id: (orderId.hashCode.abs() % 100000),
      );
    }

    _notifyListeners();
  }

  /// Periodic poll ensures no order is missed even if network or WebSocket hiccups
  Future<void> _pollOrders() async {
    if (_currentUser == null || !_isPrimed) return;

    try {
      if (_currentUser!.role == StaffRole.packer) {
        final currentOrders =
            await SupabaseService.getOrdersToPack(_currentUser!.storeId);
        bool hasChanges = false;

        for (final o in currentOrders) {
          if (!_knownOrderIds.contains(o.id)) {
            _knownOrderIds.add(o.id);
            _knownOrderStatuses[o.id] = 'CONFIRMED';
            hasChanges = true;

            NativeNotificationService.showNotification(
              title: '📦 New Order to Pack: #${o.id}',
              body:
                  'New order arrived with ${o.items.length} items. Open app to pack.',
              id: (o.id.hashCode.abs() % 100000),
            );
          }
        }

        if (hasChanges) {
          _notifyListeners();
        }
      } else {
        final currentDeliveries =
            await SupabaseService.getDeliveryOrders(_currentUser!.storeId);
        bool hasChanges = false;

        for (final d in currentDeliveries) {
          final currentStatus = d.status == DeliveryStatus.inProgress
              ? 'OUT_FOR_DELIVERY'
              : 'PACKED';
          final previousStatus = _knownOrderStatuses[d.id];

          if (!_knownOrderIds.contains(d.id)) {
            _knownOrderIds.add(d.id);
            _knownOrderStatuses[d.id] = currentStatus;
            hasChanges = true;

            if (currentStatus == 'PACKED') {
              NativeNotificationService.showNotification(
                title: '🚚 Order Ready for Delivery: #${d.id}',
                body:
                    'Order #${d.id} is packed and ready for delivery pickup!',
                id: (d.id.hashCode.abs() % 100000),
              );
            }
          } else if (previousStatus != null &&
              previousStatus != currentStatus) {
            _knownOrderStatuses[d.id] = currentStatus;
            hasChanges = true;

            if (currentStatus == 'OUT_FOR_DELIVERY') {
              NativeNotificationService.showNotification(
                title: '🛵 Out for Delivery: #${d.id}',
                body: 'Order #${d.id} is on the way.',
                id: (d.id.hashCode.abs() % 100000),
              );
            }
          }
        }

        if (hasChanges) {
          _notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[OrderMonitorService] Poll error: $e');
    }
  }
}
