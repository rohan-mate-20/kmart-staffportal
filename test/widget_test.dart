import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kmart_staff_portal/models/models.dart';
import 'package:kmart_staff_portal/screens/login_screen.dart';
import 'package:kmart_staff_portal/theme/app_theme.dart';

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
}
