import '../models/models.dart';

/// Static demo data. Swap these out for API calls when wiring a backend.
class MockData {
  MockData._();

  // ------------------------- Users -------------------------
  static const StaffUser packer = StaffUser(
    name: 'Ravi Kumar',
    role: StaffRole.packer,
    store: 'Store 1',
    email: 'ravi.kumar@kmart.com',
    phone: '+91 98765 43211',
    employeeId: 'KM-PCK-001',
    storeAddress: '123, MG Road, Near Central Mall,\nPune, Maharashtra 411001',
  );

  static const StaffUser deliveryStaff = StaffUser(
    name: 'Amit Sharma',
    role: StaffRole.delivery,
    store: 'Store 1',
    email: 'amit.sharma@kmart.com',
    phone: '+91 98765 43210',
    employeeId: 'KM-DEL-001',
    storeAddress: '123, MG Road, Near Central Mall,\nPune, Maharashtra 411001',
  );

  // ------------------------- Packer -------------------------
  static const int packerItemsToday = 12;

  static List<PackerOrder> packerOrders() => [
        PackerOrder(
          id: '#KM1024',
          time: '10:24 AM',
          totalItems: 4,
          orderValue: 890,
          items: const [
            OrderItem(name: 'Colgate Toothpaste', quantity: 2),
            OrderItem(name: 'Aashirvaad Atta', quantity: 1),
            OrderItem(name: 'Saffola Oil', quantity: 1),
          ],
        ),
        PackerOrder(
          id: '#KM1025',
          time: '10:24 AM',
          totalItems: 5,
          orderValue: 650,
          items: const [
            OrderItem(name: 'Maggi Noodles', quantity: 3),
            OrderItem(name: 'Amul Milk', quantity: 2),
          ],
        ),
        PackerOrder(
          id: '#KM1026',
          time: '11:45 AM',
          totalItems: 1,
          orderValue: 220,
          items: const [
            OrderItem(name: 'Tata Tea', quantity: 1),
          ],
        ),
        PackerOrder(
          id: '#KM1027',
          time: '12:10 PM',
          totalItems: 3,
          orderValue: 1150,
          items: const [
            OrderItem(name: 'Fortune Sunflower Oil', quantity: 1),
            OrderItem(name: 'Kissan Jam', quantity: 2),
          ],
        ),
        PackerOrder(
          id: '#KM1028',
          time: '12:40 PM',
          totalItems: 2,
          orderValue: 430,
          items: const [
            OrderItem(name: 'Britannia Biscuits', quantity: 2),
          ],
        ),
      ];

  static List<PackerOrder> packerHistory() => [
        PackerOrder(
          id: '#KM1042',
          date: '15 Sep 2026',
          time: '06:12 PM',
          totalItems: 4,
          orderValue: 780,
          status: PackStatus.packed,
          items: const [
            OrderItem(name: 'Aashirvaad Atta', quantity: 1),
            OrderItem(name: 'Saffola Oil', quantity: 1),
            OrderItem(name: 'Amul Milk', quantity: 2),
          ],
        ),
        PackerOrder(
          id: '#KM1041',
          date: '15 Sep 2026',
          time: '04:35 PM',
          totalItems: 3,
          orderValue: 510,
          status: PackStatus.packed,
          items: const [
            OrderItem(name: 'Colgate Toothpaste', quantity: 1),
            OrderItem(name: 'Maggi Noodles', quantity: 1),
            OrderItem(name: 'Tata Tea', quantity: 1),
          ],
        ),
        PackerOrder(
          id: '#KM1040',
          date: '15 Sep 2026',
          time: '01:20 PM',
          totalItems: 4,
          orderValue: 640,
          status: PackStatus.packed,
          items: const [
            OrderItem(name: 'Lays Chips', quantity: 2),
            OrderItem(name: 'Amul Milk', quantity: 1),
            OrderItem(name: 'Saffola Oil', quantity: 1),
          ],
        ),
        PackerOrder(
          id: '#KM1039',
          date: '15 Sep 2026',
          time: '11:08 AM',
          totalItems: 3,
          orderValue: 460,
          status: PackStatus.packed,
          items: const [
            OrderItem(name: 'Maggi Noodles', quantity: 1),
            OrderItem(name: 'Kissan Jam', quantity: 1),
            OrderItem(name: 'Amul Milk', quantity: 1),
          ],
        ),
        PackerOrder(
          id: '#KM1038',
          date: '15 Sep 2026',
          time: '09:24 AM',
          totalItems: 3,
          orderValue: 580,
          status: PackStatus.packed,
          items: const [
            OrderItem(name: 'Tata Tea', quantity: 1),
            OrderItem(name: 'Kissan Ketchup', quantity: 1),
            OrderItem(name: 'Amul Milk', quantity: 1),
          ],
        ),
      ];

  // ------------------------- Delivery -------------------------
  static List<DeliveryOrder> deliveries() => [
        DeliveryOrder(
          id: '#KM1024',
          time: '10:30 AM',
          itemCount: 5,
          customerName: 'Priya Sharma',
          phone: '+91 98765 43210',
          addressLine1: '123, Green Park',
          addressLine2: 'Pune, Maharashtra',
          amount: 890,
          payment: PaymentMode.cod,
        ),
        DeliveryOrder(
          id: '#KM1025',
          time: '11:15 AM',
          itemCount: 3,
          customerName: 'Rahul Mehta',
          phone: '+91 91234 56789',
          addressLine1: '45, MG Road',
          addressLine2: 'Pune, Maharashtra',
          amount: 650,
          payment: PaymentMode.paidOnline,
        ),
        DeliveryOrder(
          id: '#KM1026',
          time: '12:30 PM',
          itemCount: 4,
          customerName: 'Sneha Kulkarni',
          phone: '+91 99887 76655',
          addressLine1: 'A-101, Sunrise Apartments',
          addressLine2: 'Pune, Maharashtra',
          amount: 1240,
          payment: PaymentMode.cod,
        ),
        DeliveryOrder(
          id: '#KM1027',
          time: '02:00 PM',
          itemCount: 2,
          customerName: 'Vikram Joshi',
          phone: '+91 90000 11223',
          addressLine1: '12, Kothrud',
          addressLine2: 'Pune, Maharashtra',
          amount: 320,
          payment: PaymentMode.paidOnline,
        ),
      ];

  static List<DeliveryOrder> deliveryHistory() => [
        DeliveryOrder(
          id: '#KM1024',
          date: '15 Sep 2026',
          time: '06:12 PM',
          itemCount: 4,
          customerName: 'Priya Sharma',
          phone: '+91 98765 43210',
          addressLine1: 'Green Park, Pune',
          addressLine2: 'Pune, Maharashtra',
          amount: 890,
          payment: PaymentMode.cod,
          status: DeliveryStatus.delivered,
        ),
        DeliveryOrder(
          id: '#KM1021',
          date: '15 Sep 2026',
          time: '04:35 PM',
          itemCount: 3,
          customerName: 'Rahul Mehta',
          phone: '+91 91234 56789',
          addressLine1: 'MG Road, Pune',
          addressLine2: 'Pune, Maharashtra',
          amount: 650,
          payment: PaymentMode.paidOnline,
          status: DeliveryStatus.delivered,
        ),
        DeliveryOrder(
          id: '#KM1018',
          date: '15 Sep 2026',
          time: '02:15 PM',
          itemCount: 5,
          customerName: 'Sneha Kulkarni',
          phone: '+91 99887 76655',
          addressLine1: 'Baner, Pune',
          addressLine2: 'Pune, Maharashtra',
          amount: 1240,
          payment: PaymentMode.cod,
          status: DeliveryStatus.delivered,
        ),
        DeliveryOrder(
          id: '#KM1016',
          date: '15 Sep 2026',
          time: '12:40 PM',
          itemCount: 2,
          customerName: 'Vikram Joshi',
          phone: '+91 90000 11223',
          addressLine1: 'Kothrud, Pune',
          addressLine2: 'Pune, Maharashtra',
          amount: 320,
          payment: PaymentMode.paidOnline,
          status: DeliveryStatus.delivered,
        ),
        DeliveryOrder(
          id: '#KM1013',
          date: '15 Sep 2026',
          time: '10:20 AM',
          itemCount: 3,
          customerName: 'Neha Patil',
          phone: '+91 98000 55443',
          addressLine1: 'Hinjewadi, Pune',
          addressLine2: 'Pune, Maharashtra',
          amount: 780,
          payment: PaymentMode.cod,
          status: DeliveryStatus.delivered,
        ),
      ];
}
