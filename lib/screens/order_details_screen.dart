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
    final items = isDelivery ? delivery!.items : packer!.items;
    final statusLabel = isDelivery ? delivery!.status.label : packer!.status.label;

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
          // Header Card
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
                      StatusChip.info(statusLabel),
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
                  if (isDelivery && delivery != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 18, color: AppColors.navy),
                        const SizedBox(width: 8),
                        Text(
                          delivery.customerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.call_outlined,
                            size: 18, color: AppColors.navy),
                        const SizedBox(width: 8),
                        Text(
                          delivery.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.navy),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            delivery.addressLine2.isNotEmpty
                                ? '${delivery.addressLine1}, ${delivery.addressLine2}'
                                : delivery.addressLine1,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(),
                    ),
                  ],
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
          const SizedBox(height: 18),
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ProductThumb(name: item.name, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                                if (item.unitMrp != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Unit Price: ${rupees(item.unitMrp!)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
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
