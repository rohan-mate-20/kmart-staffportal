import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'order_details_screen.dart';

class PackerDashboardScreen extends StatefulWidget {
  final StaffUser user;

  const PackerDashboardScreen({super.key, required this.user});

  @override
  State<PackerDashboardScreen> createState() => _PackerDashboardScreenState();
}

class _PackerDashboardScreenState extends State<PackerDashboardScreen> {
  List<PackerOrder> _orders = [];
  bool _loading = true;
  String? _error;
  String _sortBy = 'Oldest First';
  String _typeFilter = 'All'; // 'All', 'Delivery', 'Self Pickup'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await SupabaseService.getOrdersToPack(widget.user.storeId);
      if (mounted) {
        setState(() {
          _orders = orders;
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

  List<PackerOrder> get _visibleOrders {
    var pending =
        _orders.where((o) => o.status == PackStatus.toPack).toList();

    // 1. Order Type Filter
    if (_typeFilter == 'Delivery') {
      pending =
          pending.where((o) => o.orderType == OrderType.delivery).toList();
    } else if (_typeFilter == 'Self Pickup') {
      pending =
          pending.where((o) => o.orderType == OrderType.selfPickup).toList();
    }

    // 2. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      pending = pending.where((o) {
        final idMatch = o.id.toLowerCase().contains(q);
        final nameMatch = o.customerName.toLowerCase().contains(q);
        final phoneMatch = o.phone.toLowerCase().contains(q);
        return idMatch || nameMatch || phoneMatch;
      }).toList();
    }

    // 3. Sorting
    if (_sortBy == 'Oldest First') {
      pending.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return a.createdAt!.compareTo(b.createdAt!);
        }
        return a.time.compareTo(b.time);
      });
    } else if (_sortBy == 'Newest First') {
      pending.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.time.compareTo(a.time);
      });
    } else if (_sortBy == 'Highest Value') {
      pending.sort((a, b) => b.orderValue.compareTo(a.orderValue));
    } else if (_sortBy == 'Lowest Value') {
      pending.sort((a, b) => a.orderValue.compareTo(b.orderValue));
    } else if (_sortBy == 'Most Items') {
      pending.sort((a, b) => b.totalItems.compareTo(a.totalItems));
    }

    return pending;
  }

  int get _totalItemsToPack =>
      _orders.fold<int>(0, (sum, o) => sum + o.totalItems);

  Future<void> _markAsPacked(PackerOrder order) async {
    try {
      // Call shared Edge Function
      await SupabaseService.markOrderPacked(order.rawId);

      setState(() => order.status = PackStatus.packed);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Order ${order.id} marked as packed.'),
            backgroundColor: AppColors.navy,
            behavior: SnackBarBehavior.floating,
          ),
        );

      // Refresh orders list from backend
      _fetchOrders();
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _visibleOrders;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _fetchOrders,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Header(user: widget.user),
              const SizedBox(height: 16),
              _GreetingBanner(name: widget.user.name.split(' ').first),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '${orders.length}',
                      label: 'Orders to Pack',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      value: '$_totalItemsToPack',
                      label: 'Items to Pack',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      value: widget.user.store,
                      label: 'Your Store',
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OrderSearchBar(
                controller: _searchController,
                hintText: 'Search by Order #, Customer, Phone...',
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 10),
              FilterChipsRow<String>(
                options: const ['All', 'Delivery', 'Self Pickup'],
                selected: _typeFilter,
                onSelected: (val) => setState(() => _typeFilter = val),
                labelBuilder: (opt) {
                  if (opt == 'All') return 'All Orders (${_orders.where((o) => o.status == PackStatus.toPack).length})';
                  if (opt == 'Delivery') {
                    final cnt = _orders.where((o) => o.status == PackStatus.toPack && o.orderType == OrderType.delivery).length;
                    return 'Delivery ($cnt)';
                  }
                  final cnt = _orders.where((o) => o.status == PackStatus.toPack && o.orderType == OrderType.selfPickup).length;
                  return 'Self Pickup ($cnt)';
                },
              ),
              const SizedBox(height: 18),
              SectionHeader(
                title: 'Orders to Pack',
                sortValue: _sortBy,
                sortOptions: const [
                  'Oldest First',
                  'Newest First',
                  'Highest Value',
                  'Lowest Value',
                  'Most Items',
                ],
                onSortChanged: (value) => setState(() => _sortBy = value),
              ),
              const SizedBox(height: 12),
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
                        onPressed: _fetchOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (orders.isEmpty)
                const _EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'All caught up!',
                  message: 'No orders left to pack right now.',
                )
              else
                for (final order in orders) ...[
                  _PackerOrderCard(
                    order: order,
                    onMarkPacked: () => _markAsPacked(order),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final StaffUser user;

  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const KmartLogo(fontSize: 20, subtitle: 'Packer Dashboard'),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new notifications.')),
                );
              },
              icon: const Icon(Icons.notifications_none,
                  color: AppColors.navy, size: 26),
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
        const SizedBox(width: 4),
        InitialsAvatar(initials: user.initials, size: 38),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            Text(
              '${user.role.label} • ${user.store}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GreetingBanner extends StatelessWidget {
  final String name;

  const _GreetingBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Good Morning, $name!',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Let's pack some orders.",
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.inventory_2, size: 44, color: Color(0xFFD9A066)),
        ],
      ),
    );
  }
}

class _PackerOrderCard extends StatelessWidget {
  final PackerOrder order;
  final VoidCallback onMarkPacked;

  const _PackerOrderCard({required this.order, required this.onMarkPacked});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => OrderDetailsScreen(
                order: order,
                onAction: () {
                  onMarkPacked();
                  Navigator.of(ctx).pop();
                },
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
                          order.id,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.time} • ${order.totalItems} items',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderTypeChip(type: order.orderType),
                  const SizedBox(width: 8),
                  StatusChip.pending(order.status.label),
                ],
              ),
              if (order.customerName != 'Customer' ||
                  order.phone != 'N/A' ||
                  order.addressLine1.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (order.customerName != 'Customer')
                  _IconLine(
                    icon: Icons.person_outline,
                    text: order.customerName,
                    bold: true,
                  ),
                if (order.phone != 'N/A') ...[
                  const SizedBox(height: 6),
                  _IconLine(icon: Icons.call_outlined, text: order.phone),
                ],
                if (order.addressLine1.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _IconLine(
                    icon: Icons.location_on_outlined,
                    text: order.addressLine1,
                    maxLines: 2,
                  ),
                ],
              ],
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
                          for (final item in order.items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  ProductThumb(name: item.name),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.navy,
                                          ),
                                        ),
                                        if (item.unitPrice != null ||
                                            item.unitMrp != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Unit Price: ${rupees(item.unitPrice ?? item.unitMrp!)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Qty: ${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _KeyValueRow(
                            label: 'Total Items',
                            value: '${order.totalItems}',
                          ),
                          const SizedBox(height: 6),
                          _KeyValueRow(
                            label: 'Order Value',
                            value: rupees(order.orderValue),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onMarkPacked,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                textStyle: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Mark as Packed'),
                            ),
                          ),
                        ],
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

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _KeyValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 52, color: AppColors.primary.withValues(alpha: .7)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
