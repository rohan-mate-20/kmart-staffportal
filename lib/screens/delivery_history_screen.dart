import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'order_details_screen.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  final StaffUser? user;

  const DeliveryHistoryScreen({super.key, this.user});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  List<DeliveryOrder> _allHistory = [];
  bool _loading = true;
  String? _error;
  late String _month;
  late List<String> _monthOptions;
  String _sortBy = 'Newest First';
  String _paymentFilter = 'All'; // 'All', 'COD', 'Paid Online'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final currentMonthStr = DateFormat('MMMM yyyy').format(now);
    final prevMonth1 = DateFormat('MMMM yyyy').format(DateTime(now.year, now.month - 1));
    final prevMonth2 = DateFormat('MMMM yyyy').format(DateTime(now.year, now.month - 2));

    _monthOptions = [currentMonthStr, prevMonth1, prevMonth2, 'All Time'];
    _month = currentMonthStr;

    _fetchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final staffId = widget.user?.id ?? '';
      final list = await SupabaseService.getDeliveryHistory(
          staffId, widget.user?.storeId);
      if (mounted) {
        setState(() {
          _allHistory = list;
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

  List<DeliveryOrder> get _filteredHistory {
    var list = _allHistory;
    if (_month != 'All Time') {
      list = list.where((d) {
        if (d.createdAt == null) return true;
        final m = DateFormat('MMMM yyyy').format(d.createdAt!);
        return m == _month;
      }).toList();
    }

    if (_paymentFilter == 'COD') {
      list = list.where((d) => d.isCod).toList();
    } else if (_paymentFilter == 'Paid Online') {
      list = list.where((d) => !d.isCod).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((d) {
        final idMatch = d.id.toLowerCase().contains(q);
        final nameMatch = d.customerName.toLowerCase().contains(q);
        final phoneMatch = d.phone.toLowerCase().contains(q);
        final addrMatch =
            '${d.addressLine1} ${d.addressLine2}'.toLowerCase().contains(q);
        return idMatch || nameMatch || phoneMatch || addrMatch;
      }).toList();
    }

    return list;
  }

  List<DeliveryOrder> get _sorted {
    final list = List<DeliveryOrder>.from(_filteredHistory);
    if (_sortBy == 'Newest First') {
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }
        return b.time.compareTo(a.time);
      });
    } else if (_sortBy == 'Oldest First') {
      list.sort((a, b) {
        if (a.createdAt != null && b.createdAt != null) {
          return a.createdAt!.compareTo(b.createdAt!);
        }
        return a.time.compareTo(b.time);
      });
    } else if (_sortBy == 'Highest Amount') {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_sortBy == 'Lowest Amount') {
      list.sort((a, b) => a.amount.compareTo(b.amount));
    } else if (_sortBy == 'Most Items') {
      list.sort((a, b) => b.itemCount.compareTo(a.itemCount));
    }
    return list;
  }

  double get _totalValue =>
      _filteredHistory.fold<double>(0.0, (sum, d) => sum + d.amount);

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: const SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KmartLogo(
                    fontSize: 18,
                    subtitle: 'Staff Portal',
                    onDark: true,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Delivery History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View all your completed deliveries.',
                    style: TextStyle(fontSize: 13.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _fetchHistory,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  MonthPicker(
                    value: _month,
                    options: _monthOptions,
                    onChanged: (value) => setState(() => _month = value),
                  ),
                  const SizedBox(height: 14),
                  OrderSearchBar(
                    controller: _searchController,
                    hintText: 'Search completed orders by #, customer...',
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  FilterChipsRow<String>(
                    options: const ['All', 'COD', 'Paid Online'],
                    selected: _paymentFilter,
                    onSelected: (val) => setState(() => _paymentFilter = val),
                    labelBuilder: (opt) => opt == 'All' ? 'All Payments' : opt,
                  ),
                  const SizedBox(height: 16),
                  SummaryStrip(
                    items: [
                      SummaryStripItem(
                        icon: Icons.local_shipping_outlined,
                        value: '${_filteredHistory.length}',
                        label: 'Deliveries\nCompleted',
                      ),
                      SummaryStripItem(
                        icon: Icons.shopping_bag_outlined,
                        value:
                            '${_filteredHistory.fold<int>(0, (sum, d) => sum + d.itemCount)}',
                        label: 'Items\nDelivered',
                      ),
                      SummaryStripItem(
                        icon: Icons.currency_rupee,
                        value: rupees(_totalValue),
                        label: 'Total Order\nValue',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Completed Deliveries',
                    sortValue: _sortBy,
                    sortOptions: const [
                      'Newest First',
                      'Oldest First',
                      'Highest Amount',
                      'Lowest Amount',
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
                            onPressed: _fetchHistory,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (sorted.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'No completed deliveries in this period.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (final delivery in sorted) ...[
                      _CompletedDeliveryTile(delivery: delivery),
                      const SizedBox(height: 12),
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

class _CompletedDeliveryTile extends StatelessWidget {
  final DeliveryOrder delivery;

  const _CompletedDeliveryTile({required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(order: delivery),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.id,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${delivery.date ?? ''} • ${delivery.time}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderTypeChip(type: delivery.orderType),
                  const SizedBox(width: 8),
                  StatusChip.done('Delivered'),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              OrderItemsList(items: delivery.items),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 15, color: AppColors.navy),
                            const SizedBox(width: 6),
                            Text(
                              delivery.customerName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                delivery.shortAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        rupees(delivery.amount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        delivery.payment.label,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
