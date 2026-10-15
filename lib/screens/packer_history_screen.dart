import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'order_details_screen.dart';

class PackerHistoryScreen extends StatefulWidget {
  final StaffUser? user;

  const PackerHistoryScreen({super.key, this.user});

  @override
  State<PackerHistoryScreen> createState() => _PackerHistoryScreenState();
}

class _PackerHistoryScreenState extends State<PackerHistoryScreen> {
  List<PackerOrder> _allHistory = [];
  bool _loading = true;
  String? _error;
  late String _month;
  late List<String> _monthOptions;
  String _sortBy = 'Newest First';
  String _typeFilter = 'All'; // 'All', 'Delivery', 'Self Pickup'
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
      final history = await SupabaseService.getPackerHistory(
          staffId, widget.user?.storeId);
      if (mounted) {
        setState(() {
          _allHistory = history;
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

  List<PackerOrder> get _filteredHistory {
    var list = _allHistory;
    if (_month != 'All Time') {
      list = list.where((o) {
        if (o.createdAt == null) return true;
        final m = DateFormat('MMMM yyyy').format(o.createdAt!);
        return m == _month;
      }).toList();
    }

    if (_typeFilter == 'Delivery') {
      list = list.where((o) => o.orderType == OrderType.delivery).toList();
    } else if (_typeFilter == 'Self Pickup') {
      list = list.where((o) => o.orderType == OrderType.selfPickup).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((o) {
        final idMatch = o.id.toLowerCase().contains(q);
        final nameMatch = o.customerName.toLowerCase().contains(q);
        final phoneMatch = o.phone.toLowerCase().contains(q);
        return idMatch || nameMatch || phoneMatch;
      }).toList();
    }

    return list;
  }

  List<PackerOrder> get _sorted {
    final list = List<PackerOrder>.from(_filteredHistory);
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
    } else if (_sortBy == 'Highest Value') {
      list.sort((a, b) => b.orderValue.compareTo(a.orderValue));
    } else if (_sortBy == 'Lowest Value') {
      list.sort((a, b) => a.orderValue.compareTo(b.orderValue));
    } else if (_sortBy == 'Most Items') {
      list.sort((a, b) => b.totalItems.compareTo(a.totalItems));
    }
    return list;
  }

  int get _totalOrdersPacked => _filteredHistory.length;

  int get _totalItemsPacked =>
      _filteredHistory.fold<int>(0, (sum, o) => sum + o.totalItems);

  double get _totalPackedValue =>
      _filteredHistory.fold<double>(0.0, (sum, o) => sum + o.orderValue);

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const _DarkHeader(
            title: 'Packer History',
            subtitle: 'View all the orders you have packed.',
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
                    hintText: 'Search packed orders by #, customer...',
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  FilterChipsRow<String>(
                    options: const ['All', 'Delivery', 'Self Pickup'],
                    selected: _typeFilter,
                    onSelected: (val) => setState(() => _typeFilter = val),
                    labelBuilder: (opt) {
                      if (opt == 'All') return 'All (${_allHistory.length})';
                      if (opt == 'Delivery') {
                        final cnt = _allHistory.where((o) => o.orderType == OrderType.delivery).length;
                        return 'Delivery ($cnt)';
                      }
                      final cnt = _allHistory.where((o) => o.orderType == OrderType.selfPickup).length;
                      return 'Self Pickup ($cnt)';
                    },
                  ),
                  const SizedBox(height: 16),
                  SummaryStrip(
                    items: [
                      SummaryStripItem(
                        icon: Icons.inventory_2_outlined,
                        value: '$_totalOrdersPacked',
                        label: 'Orders Packed',
                      ),
                      SummaryStripItem(
                        icon: Icons.shopping_cart_outlined,
                        value: '$_totalItemsPacked',
                        label: 'Items Packed',
                      ),
                      SummaryStripItem(
                        icon: Icons.currency_rupee,
                        value: rupees(_totalPackedValue),
                        label: 'Total Value',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Orders',
                    sortValue: _sortBy,
                    sortOptions: const [
                      'Newest First',
                      'Oldest First',
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
                          'No packed orders in this period.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    for (final order in sorted) ...[
                      _HistoryOrderTile(order: order),
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

class _DarkHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DarkHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                KmartLogo(fontSize: 18, subtitle: 'Staff Portal', onDark: true),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13.5, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryOrderTile extends StatelessWidget {
  final PackerOrder order;

  const _HistoryOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(order: order),
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
                          order.id,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.date ?? ''} • ${order.time}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderTypeChip(type: order.orderType),
                  const SizedBox(width: 8),
                  StatusChip.done('Packed'),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              OrderItemsList(items: order.items),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.totalItems} items',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    rupees(order.orderValue),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
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

