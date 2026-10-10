import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'order_details_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  final StaffUser user;

  const DeliveryDashboardScreen({super.key, required this.user});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  List<DeliveryOrder> _deliveries = [];
  bool _loading = true;
  String? _error;
  String _sortBy = 'Earliest Slot';
  String? _updatingOrderId;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await SupabaseService.getDeliveryOrders(widget.user.storeId);
      if (mounted) {
        setState(() {
          _deliveries = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  int get _inProgress =>
      _deliveries.where((d) => d.status == DeliveryStatus.inProgress).length;

  int get _remaining =>
      _deliveries.where((d) => d.status == DeliveryStatus.ready).length;

  int get _delivered =>
      _deliveries.where((d) => d.status == DeliveryStatus.delivered).length;

  List<DeliveryOrder> get _active {
    final list = List<DeliveryOrder>.from(_deliveries);
    if (_sortBy == 'Highest Amount') {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_sortBy == 'Earliest Slot') {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
    return list;
  }

  Future<void> _advance(DeliveryOrder order) async {
    if (_updatingOrderId != null) return;

    setState(() => _updatingOrderId = order.rawId);

    try {
      if (order.status == DeliveryStatus.ready) {
        // Mark Out For Delivery
        await SupabaseService.markOrderOutForDelivery(order.rawId);
        if (mounted) {
          setState(() {
            order.status = DeliveryStatus.inProgress;
            _updatingOrderId = null;
          });
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.navy,
              content: Text('${order.id} → Out for Delivery'),
            ),
          );
      } else {
        // Mark Delivered
        await SupabaseService.markOrderDelivered(order.rawId);
        if (mounted) {
          setState(() {
            order.status = DeliveryStatus.delivered;
            _updatingOrderId = null;
          });
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: Color(0xFF1976D2),
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Order Delivered Successfully'),
                ],
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updatingOrderId = null);
      }
      if (!mounted) return;
      final errMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            content: Text(errMsg),
          ),
        );
    }
  }

  Future<void> _callCustomer(String phone) async {
    if (phone.isEmpty || phone == 'N/A') return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call to $phone')),
        );
      }
    }
  }

  Future<void> _openMap(String address) async {
    if (address.isEmpty || address == 'Address') return;
    final query = Uri.encodeComponent(address);
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map for $address')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _DeliveryHeader(
            user: widget.user,
            assignedCount: _deliveries.length,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchDeliveries,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: '${_deliveries.length}',
                          label: "Active Assigned",
                          icon: Icons.local_shipping_outlined,
                          iconColor: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          value: '$_inProgress',
                          label: 'In Progress',
                          icon: Icons.access_time,
                          iconColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          value: '$_remaining',
                          label: 'Ready / Remaining',
                          icon: Icons.location_on_outlined,
                          iconColor: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          value: '$_delivered',
                          label: 'Completed Delivered',
                          icon: Icons.check_circle_outline,
                          iconColor: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Your Deliveries',
                    sortValue: _sortBy,
                    sortOptions: const [
                      'Earliest Slot',
                      'Highest Amount',
                    ],
                    onSortChanged: (value) => setState(() => _sortBy = value),
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchDeliveries,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (active.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No deliveries pending. Great work!',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (final delivery in active) ...[
                      _DeliveryCard(
                        delivery: delivery,
                        isUpdating: _updatingOrderId == delivery.rawId,
                        onAction: () => _advance(delivery),
                        onCall: () => _callCustomer(delivery.phone),
                        onMap: () => _openMap(
                          '${delivery.addressLine1}, ${delivery.addressLine2}',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryHeader extends StatelessWidget {
  final StaffUser user;
  final int assignedCount;

  const _DeliveryHeader({required this.user, required this.assignedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const KmartLogo(
                  fontSize: 18,
                  subtitle: 'Delivery Portal',
                  onDark: true,
                ),
                const Spacer(),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No new notifications.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_none,
                          color: Colors.white, size: 24),
                    ),
                    const Positioned(
                      right: 10,
                      top: 8,
                      child: CircleAvatar(
                        radius: 4.5,
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 2),
                InitialsAvatar(initials: user.initials, size: 36),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${user.role.label} • ${user.store}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Day, ${user.name.split(' ').first}!',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'You have $assignedCount deliveries assigned.',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.two_wheeler,
                    size: 46, color: AppColors.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryOrder delivery;
  final bool isUpdating;
  final VoidCallback onAction;
  final VoidCallback? onCall;
  final VoidCallback? onMap;

  const _DeliveryCard({
    required this.delivery,
    this.isUpdating = false,
    required this.onAction,
    this.onCall,
    this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final isCod = delivery.payment == PaymentMode.cod;
    final isDelivered = delivery.status == DeliveryStatus.delivered;
    final isReady = delivery.status == DeliveryStatus.ready;

    // Determine status chip
    final Widget statusChip;
    if (isDelivered) {
      statusChip = StatusChip.delivered('Delivered');
    } else if (isReady) {
      statusChip = StatusChip.info('Ready for Delivery');
    } else {
      statusChip = StatusChip.pending('Out for Delivery');
    }

    // Determine action button properties
    final String buttonText;
    final IconData buttonIcon;
    final Color buttonColor;
    final VoidCallback? buttonOnPressed;

    if (isDelivered) {
      buttonText = 'Delivered';
      buttonIcon = Icons.check_circle;
      buttonColor = const Color(0xFF1976D2); // Professional Blue
      buttonOnPressed = null; // Disabled once delivered
    } else if (isReady) {
      buttonText = 'Out for Delivery';
      buttonIcon = Icons.arrow_forward;
      buttonColor = AppColors.primary;
      buttonOnPressed = isUpdating ? null : onAction;
    } else {
      buttonText = 'Mark Delivered';
      buttonIcon = Icons.check;
      buttonColor = AppColors.primary;
      buttonOnPressed = isUpdating ? null : onAction;
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(
                order: delivery,
                onAction: () => onAction(),
                isUpdating: isUpdating,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        delivery.id,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${delivery.time} • ${delivery.itemCount} items',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                statusChip,
              ],
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconLine(
                          icon: Icons.person_outline,
                          text: delivery.customerName,
                          bold: true,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: onCall,
                          child: _IconLine(
                            icon: Icons.call_outlined,
                            text: delivery.phone,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: onMap,
                          child: _IconLine(
                            icon: Icons.location_on_outlined,
                            text: delivery.addressLine2.isNotEmpty
                                ? '${delivery.addressLine1}\n${delivery.addressLine2}'
                                : delivery.addressLine1,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 22),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              rupees(delivery.amount),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            isCod
                                ? StatusChip.pending('COD')
                                : StatusChip.done('Paid Online'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: isDelivered
                                ? BoxDecoration(
                                    color: const Color(0xFF1976D2),
                                    borderRadius: BorderRadius.circular(10),
                                  )
                                : null,
                            child: ElevatedButton(
                              onPressed: buttonOnPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                disabledBackgroundColor: const Color(0xFF1976D2),
                                disabledForegroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: isUpdating
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          buttonText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          buttonIcon,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            const Text(
              'Items in Delivery Box:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            if (delivery.items.isEmpty)
              const Text(
                'No item details available',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              )
            else
              for (final item in delivery.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      ProductThumb(name: item.name, size: 26),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}
}

class _IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  final int? maxLines;

  const _IconLine({
    required this.icon,
    required this.text,
    this.bold = false,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.navy),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppColors.navy : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
