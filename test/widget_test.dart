import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kmart_staff_portal/models/models.dart';
import 'package:kmart_staff_portal/screens/login_screen.dart';
import 'package:kmart_staff_portal/screens/order_details_screen.dart';
import 'package:kmart_staff_portal/screens/profile_screen.dart';
import 'package:kmart_staff_portal/services/native_notification_service.dart';
import 'package:kmart_staff_portal/services/order_monitor_service.dart';
import 'package:kmart_staff_portal/theme/app_theme.dart';
import 'package:kmart_staff_portal/widgets/common_widgets.dart';

void main() {
  testWidgets('renders LoginScreen with branding and form elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );

    expect(find.text('Staff Portal'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('StaffUser models correctly parse initials and roles',
      (WidgetTester tester) async {
    const packer = StaffUser(
      name: 'Ravi Kumar',
      role: StaffRole.packer,
      store: 'Indiranagar Store',
      email: 'ravi.k@kmart.com',
      phone: '+91 98765 43210',
      employeeId: 'EMP-4821',
      storeAddress: '100ft Road, HAL 2nd Stage, Indiranagar',
    );

    expect(packer.initials, 'RK');
    expect(packer.role.label, 'Packer');
  });

  test('OrderItem.fromMap handles both flat view and nested product structures', () {
    // 1. Flat packer view format
    final flatItem = OrderItem.fromMap({
      'product_name': 'Sunflower Oil 1L',
      'quantity': 2,
      'unit_mrp': 150.0,
      'line_total_mrp': 300.0,
    });
    expect(flatItem.name, 'Sunflower Oil 1L');
    expect(flatItem.quantity, 2);
    expect(flatItem.unitMrp, 150.0);
    expect(flatItem.lineTotalMrp, 300.0);

    // 2. Nested order_items format with products join
    final nestedItem = OrderItem.fromMap({
      'quantity': 3,
      'line_total': 180.0,
      'products': {
        'id': 'prod-123',
        'name': 'Basmati Rice 1kg',
        'selling_price': 60.0,
      },
    });
    expect(nestedItem.name, 'Basmati Rice 1kg');
    expect(nestedItem.quantity, 3);
    expect(nestedItem.unitMrp, 60.0);
    expect(nestedItem.lineTotalMrp, 180.0);
  });

  test('DeliveryOrder.fromMap parses customer, default address, and order items correctly', () {
    final orderMap = {
      'id': 'ord-uuid-12345678',
      'order_number': 'ORD-987654',
      'total': 450.0,
      'status': 'OUT_FOR_DELIVERY',
      'created_at': '2026-03-01T10:00:00Z',
      'payment_method': 'COD',
      'customers': {
        'name': 'Priya Patel',
        'phone': '+91 9988776655',
        'addresses': [
          {
            'line1': 'Flat 402, Sunshine Heights',
            'line2': 'Near Metro Station',
            'city': 'Bengaluru',
            'pincode': '560038',
            'is_default': true,
          }
        ],
      },
      'order_items': [
        {
          'quantity': 1,
          'line_total': 450.0,
          'products': {
            'name': 'Olive Oil 1L',
            'selling_price': 450.0,
          }
        }
      ]
    };

    final order = DeliveryOrder.fromMap(orderMap);
    expect(order.id, 'ORD-987654');
    expect(order.customerName, 'Priya Patel');
    expect(order.phone, '+91 9988776655');
    expect(order.addressLine1, 'Flat 402, Sunshine Heights, Near Metro Station');
    expect(order.addressLine2, 'Bengaluru, 560038');
    expect(order.payment, PaymentMode.cod);
    expect(order.status, DeliveryStatus.inProgress);
    expect(order.items.length, 1);
    expect(order.items.first.name, 'Olive Oil 1L');
    expect(order.items.first.quantity, 1);
  });

  test('DeliveryOrder.fromMap correctly parses customer_snapshot and delivery_address_snapshot', () {
    final orderMap = {
      'id': 'ord-snap-112233',
      'order_number': 'KM55228999',
      'total': 688.0,
      'status': 'DELIVERED',
      'created_at': '2026-10-01T11:03:00Z',
      'payment_method': 'COD',
      'customers': null,
      'customer_snapshot': {
        'name': 'Rahul Verma',
        'phone': '+91 91234 56789',
        'email': 'rahul@example.com',
      },
      'delivery_address_snapshot': {
        'addressLine1': 'House #12, 4th Cross',
        'addressLine2': 'HAL 2nd Stage, Indiranagar',
        'city': 'Bengaluru',
        'state': 'Karnataka',
        'pincode': '560038',
      },
      'order_items': [
        {
          'product_name': 'Aashirvaad Atta 5kg',
          'quantity': 2,
          'unit_selling_price': 344.0,
          'line_total': 688.0,
        }
      ]
    };

    final order = DeliveryOrder.fromMap(orderMap);
    expect(order.id, 'KM55228999');
    expect(order.customerName, 'Rahul Verma');
    expect(order.phone, '+91 91234 56789');
    expect(order.addressLine1, 'House #12, 4th Cross, HAL 2nd Stage, Indiranagar');
    expect(order.addressLine2, 'Bengaluru, Karnataka, 560038');
    expect(order.status, DeliveryStatus.delivered);
    expect(order.amount, 688.0);
    expect(order.items.length, 1);
    expect(order.items.first.name, 'Aashirvaad Atta 5kg');
    expect(order.items.first.quantity, 2);
  });

  test('PackerOrder and DeliveryOrder fallback to default sample items when empty and compute dynamic item counts', () {
    final emptyPacker = PackerOrder.fromMap({'id': 'pck-1'});
    expect(emptyPacker.items.isNotEmpty, true);
    expect(emptyPacker.totalItems, greaterThan(0));
    expect(emptyPacker.totalItems, equals(emptyPacker.items.fold<int>(0, (sum, i) => sum + i.quantity)));

    final emptyDelivery = DeliveryOrder.fromMap({'id': 'del-1'});
    expect(emptyDelivery.items.isNotEmpty, true);
    expect(emptyDelivery.itemCount, greaterThan(0));
    expect(emptyDelivery.itemCount, equals(emptyDelivery.items.fold<int>(0, (sum, i) => sum + i.quantity)));
  });

  testWidgets('OrderItemsList renders product name, unit price, and quantity badge', (WidgetTester tester) async {
    const testItems = [
      OrderItem(name: 'Fortune Sunflower Oil 1L', quantity: 2, unitMrp: 140.0, unitPrice: 140.0),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: OrderItemsList(items: testItems),
        ),
      ),
    );

    expect(find.text('Fortune Sunflower Oil 1L'), findsOneWidget);
    expect(find.text('Unit Price: ₹140'), findsOneWidget);
    expect(find.text('Qty: 2'), findsOneWidget);
  });

  testWidgets('OrderTypeChip renders Self Pickup and Delivery chips correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              OrderTypeChip(type: OrderType.selfPickup),
              OrderTypeChip(type: OrderType.delivery),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Self Pickup'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
  });

  testWidgets('OrderDetailsScreen displays summary card, fulfillment card, and order items list', (WidgetTester tester) async {
    final order = DeliveryOrder(
      id: 'KM99887766',
      time: '11:00 AM',
      itemCount: 2,
      customerName: 'Suresh Patel',
      phone: '+91 98765 00000',
      addressLine1: '45 Lake View Road',
      addressLine2: 'Whitefield, Bangalore',
      amount: 450.0,
      payment: PaymentMode.paidOnline,
      items: const [
        OrderItem(name: 'Basmati Rice 1kg', quantity: 2, unitPrice: 225.0),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OrderDetailsScreen(order: order),
      ),
    );

    expect(find.text('Order Details (KM99887766)'), findsOneWidget);
    expect(find.text('KM99887766'), findsOneWidget);
    expect(find.text('Suresh Patel'), findsOneWidget);
    expect(find.text('Basmati Rice 1kg'), findsOneWidget);
    expect(find.text('Unit Price: ₹225'), findsOneWidget);
    expect(find.text('Qty: 2'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders staff details and logout button',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const user = StaffUser(
      id: 'staff-1',
      storeId: 'store-1',
      name: 'Rohan Mate',
      role: StaffRole.packer,
      store: 'Kmart Central',
      email: 'rohan@kmart.com',
      phone: '9876543210',
      employeeId: 'EMP-101',
      storeAddress: 'MG Road, Pune',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ProfileScreen(user: user),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rohan Mate'), findsAtLeastNWidgets(1));
    expect(find.text('EMP-101'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  test('NativeNotificationService handles showNotification and permission check gracefully',
      () async {
    // In test environment, MethodChannels can be called or fall back gracefully
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('kmart_staff/notifications'),
      (MethodCall call) async {
        if (call.method == 'showNotification') return true;
        if (call.method == 'checkNotificationPermission') return true;
        if (call.method == 'requestNotificationPermission') return true;
        return null;
      },
    );

    final sent = await NativeNotificationService.showNotification(
      title: '📦 New Order Alert',
      body: 'Order #KM1001 needs packing',
    );
    expect(sent, isTrue);

    final perm = await NativeNotificationService.checkNotificationPermission();
    expect(perm, isTrue);
  });

  test('OrderMonitorService manages listener registration and stop lifecycle', () {
    final monitor = OrderMonitorService.instance;
    int callCount = 0;
    void listener() => callCount++;

    monitor.addListener(listener);
    monitor.stop();
    expect(monitor.isMonitoring, isFalse);
    monitor.removeListener(listener);
    expect(callCount, 0);
  });
}
