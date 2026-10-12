import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class OrderDetailsScreen extends StatelessWidget {
  final dynamic order; // DeliveryOrder or PackerOrder
  final VoidCallback? onAction;
  final bool isUpdating;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    this.onAction,
    this.isUpdating = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDelivery = order is DeliveryOrder;
    final delivery = isDelivery ? order as DeliveryOrder : null;
    final packer = !isDelivery ? order as PackerOrder : null;

    final id = isDelivery ? delivery!.id : packer!.id;
    final time = isDelivery ? delivery!.time : packer!.time;
    final date = isDelivery ? delivery!.date : packer!.date;
    final amount = isDelivery ? delivery!.amount : packer!.orderValue;
    final rawItems = isDelivery ? delivery!.items : packer!.items;
    final items = rawItems.isNotEmpty ? rawItems : defaultSampleOrderItems;
    final statusLabel =
        isDelivery ? delivery!.status.label : packer!.status.label;
    final orderType = isDelivery ? delivery!.orderType : packer!.orderType;
    final isPickup = orderType == OrderType.selfPickup;

    final customerName = isDelivery
        ? delivery!.customerName
        : (packer!.customerName != 'Customer' ? packer.customerName : 'Customer');
    final phone = isDelivery
        ? delivery!.phone
        : (packer!.phone != 'N/A' ? packer.phone : 'N/A');
    final address = isDelivery
        ? (delivery!.addressLine2.isNotEmpty
            ? '${delivery.addressLine1}, ${delivery.addressLine2}'
            : delivery.addressLine1)
        : packer!.addressLine1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Order Details ($id)',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 1. Top Order Summary Card ──────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        id,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OrderTypeChip(type: orderType),
                          const SizedBox(width: 8),
                          StatusChip.info(statusLabel),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: $time ${date != null ? '• $date' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      Text(
                        rupees(amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  if (isDelivery && delivery != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Mode',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                        delivery.payment == PaymentMode.cod
                            ? StatusChip.pending('COD')
                            : StatusChip.done('Paid Online'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 2. Fulfillment Card (Self Pickup vs Home Delivery) ─────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPickup
                            ? Icons.storefront_outlined
                            : Icons.local_shipping_outlined,
                        size: 20,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPickup
                            ? 'Fulfillment: Store Self Pickup'
                            : 'Fulfillment: Home Delivery',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (customerName != 'Customer') ...[
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 17, color: AppColors.navy),
                        const SizedBox(width: 8),
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (phone != 'N/A') ...[
                    Row(
                      children: [
                        const Icon(Icons.call_outlined,
                            size: 17, color: AppColors.navy),
                        const SizedBox(width: 8),
                        Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (isPickup) ...[
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 17, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Customer will collect this order at store service counter.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (address.isNotEmpty && address != 'Address') ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 17, color: AppColors.navy),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── 3. Complete Order Items List ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              Text(
                '${items.fold<int>(0, (sum, i) => sum + i.quantity)} items',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0) const Divider(height: 16),
                    Row(
                      children: [
                        ProductThumb(name: items[i].name, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i].name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              if (items[i].unitPrice != null ||
                                  items[i].unitMrp != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Unit Price: ${rupees(items[i].unitPrice ?? items[i].unitMrp!)}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Qty: ${items[i].quantity}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── 4. Bottom Action Button ────────────────────────────────
          if (onAction != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating ? null : onAction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isDelivery &&
                          delivery?.status == DeliveryStatus.delivered
                      ? const Color(0xFF1976D2)
                      : AppColors.primary,
                ),
                child: isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isDelivery
                            ? (delivery?.status == DeliveryStatus.ready
                                ? 'Out for Delivery'
                                : (delivery?.status ==
                                        DeliveryStatus.inProgress
                                    ? 'Mark Delivered'
                                    : 'Delivered'))
                            : 'Mark as Packed',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

typedef OrderDetailScreen = OrderDetailsScreen;
