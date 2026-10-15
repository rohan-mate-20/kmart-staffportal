import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Formats 48620 -> "48,620" using the Indian grouping system.
String formatIndianNumber(num value) {
  final whole = value.round().abs().toString();
  if (whole.length <= 3) return (value < 0 ? '-' : '') + whole;

  final last3 = whole.substring(whole.length - 3);
  var rest = whole.substring(0, whole.length - 3);
  final buffer = <String>[];
  while (rest.length > 2) {
    buffer.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) buffer.insert(0, rest);
  return '${value < 0 ? '-' : ''}${buffer.join(',')},$last3';
}

String rupees(num value) => '₹${formatIndianNumber(value)}';

/// ---------------------------------------------------------------------------
/// Kmart wordmark
/// ---------------------------------------------------------------------------
class KmartLogo extends StatelessWidget {
  final double fontSize;
  final String? subtitle;
  final bool onDark;

  const KmartLogo({
    super.key,
    this.fontSize = 24,
    this.subtitle,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final darkText = onDark ? Colors.white : AppColors.navy;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          width: fontSize * 1.05,
          height: fontSize * 1.35,
          child: CustomPaint(painter: _KmartMarkPainter()),
        ),
        const SizedBox(width: 3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'MART',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.05,
                color: darkText,
              ),
            ),
        if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: fontSize * 0.5,
                    fontWeight: FontWeight.w600,
                    color: onDark ? Colors.white70 : AppColors.navy,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _KmartMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()..color = AppColors.primary;
    final navy = Paint()..color = AppColors.navy;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * .08, h * .08)
      ..lineTo(w * .43, h * .08)
      ..lineTo(w * .30, h * .48)
      ..lineTo(w * .84, h * .08)
      ..lineTo(w, h * .08)
      ..lineTo(w * .38, h * .68)
      ..lineTo(w * .80, h)
      ..lineTo(w * .48, h)
      ..lineTo(w * .25, h * .72)
      ..lineTo(w * .12, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, red);
    final lower = Path()
      ..moveTo(w * .25, h * .72)
      ..lineTo(w * .48, h)
      ..lineTo(w * .80, h)
      ..lineTo(w * .38, h * .68)
      ..close();
    canvas.drawPath(lower, navy);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginIllustration extends StatelessWidget {
  const LoginIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118,
      width: double.infinity,
      child: CustomPaint(painter: _LoginIllustrationPainter()),
    );
  }
}

class _LoginIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pale = Paint()..color = const Color(0xFFF3F6FA);
    final blush = Paint()..color = const Color(0xFFE58A8C);
    final skin = Paint()..color = const Color(0xFFF0B39B);
    final shirt = Paint()..color = const Color(0xFFE86B73);
    final box = Paint()..color = const Color(0xFFE9C89E);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .35, size.width, size.height * .65),
      pale,
    );
    canvas.drawCircle(Offset(size.width * .16, size.height * .48), 14, skin);
    canvas.drawOval(Rect.fromLTWH(size.width * .07, size.height * .57, 38, 52), shirt);
    canvas.drawRect(Rect.fromLTWH(size.width * .09, size.height * .69, 53, 25), box);
    canvas.drawCircle(Offset(size.width * .84, size.height * .43), 14, skin);
    canvas.drawOval(Rect.fromLTWH(size.width * .75, size.height * .53, 45, 62), blush);
    canvas.drawRect(Rect.fromLTWH(size.width * .78, size.height * .71, 62, 30), blush);
    canvas.drawRect(Rect.fromLTWH(size.width * .77, size.height * .29, 20, 6), blush);
    canvas.drawLine(Offset(size.width * .78, size.height * .33),
        Offset(size.width * .89, size.height * .32), blush..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ---------------------------------------------------------------------------
/// Avatar with initials
/// ---------------------------------------------------------------------------
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color? background;
  final Color? foreground;

  const InitialsAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? const Color(0xFFDCE6F7),
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: foreground ?? AppColors.navy,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Small pill-shaped status chip
/// ---------------------------------------------------------------------------
class StatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  factory StatusChip.pending(String label) => StatusChip(
        label: label,
        background: AppColors.primarySoft,
        foreground: AppColors.primary,
      );

  factory StatusChip.done(String label) => StatusChip(
        label: label,
        background: AppColors.successSoft,
        foreground: AppColors.success,
        icon: Icons.check_circle,
      );

  factory StatusChip.delivered(String label) => StatusChip(
        label: label,
        background: const Color(0xFFE3F2FD),
        foreground: const Color(0xFF1976D2),
        icon: Icons.check_circle,
      );

  factory StatusChip.info(String label) => StatusChip(
        label: label,
        background: AppColors.infoSoft,
        foreground: AppColors.navy,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Metric tile used in the dashboard summary rows
/// ---------------------------------------------------------------------------
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor = AppColors.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FA),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: iconColor),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Pink summary strip used at the top of the two History screens
/// ---------------------------------------------------------------------------
class SummaryStripItem {
  final IconData icon;
  final String value;
  final String label;

  const SummaryStripItem({
    required this.icon,
    required this.value,
    required this.label,
  });
}

class SummaryStrip extends StatelessWidget {
  final List<SummaryStripItem> items;

  const SummaryStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: AppColors.primary, size: 22),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Section header with a sort dropdown on the right
/// ---------------------------------------------------------------------------
class SectionHeader extends StatelessWidget {
  final String title;
  final String? sortValue;
  final List<String> sortOptions;
  final ValueChanged<String>? onSortChanged;

  const SectionHeader({
    super.key,
    required this.title,
    this.sortValue,
    this.sortOptions = const [],
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        if (sortValue != null) ...[
          const Text(
            'Sort by',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortValue,
                isDense: true,
                borderRadius: BorderRadius.circular(10),
                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
                items: [
                  for (final option in sortOptions)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (value) {
                  if (value != null) onSortChanged?.call(value);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Month selector used on the History screens
/// ---------------------------------------------------------------------------
class MonthPicker extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const MonthPicker({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month_outlined,
              size: 18, color: AppColors.navy),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              borderRadius: BorderRadius.circular(10),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
              items: [
                for (final option in options)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Product thumbnail placeholder (no network assets required)
/// ---------------------------------------------------------------------------
class ProductThumb extends StatelessWidget {
  final String name;
  final double size;

  const ProductThumb({super.key, required this.name, this.size = 34});

  static const _palette = [
    Color(0xFFFFE0B2),
    Color(0xFFC8E6C9),
    Color(0xFFBBDEFB),
    Color(0xFFF8BBD0),
    Color(0xFFD1C4E9),
    Color(0xFFFFF9C4),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: AppColors.navy.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Order Type Chip (Self Pickup vs Home Delivery)
/// ---------------------------------------------------------------------------
class OrderTypeChip extends StatelessWidget {
  final OrderType type;

  const OrderTypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPickup = type == OrderType.selfPickup;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isPickup ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPickup ? const Color(0xFFFFB74D) : const Color(0xFF90CAF9),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPickup ? Icons.storefront_outlined : Icons.delivery_dining_outlined,
            size: 13,
            color: isPickup ? const Color(0xFFE65100) : const Color(0xFF0D47A1),
          ),
          const SizedBox(width: 4),
          Text(
            isPickup ? 'Self Pickup' : 'Delivery',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPickup ? const Color(0xFFE65100) : const Color(0xFF0D47A1),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Order Items List (renders item thumbnail, title, Unit Price, and Qty)
/// Fallback ensures cards are never blank.
/// ---------------------------------------------------------------------------
class OrderItemsList extends StatelessWidget {
  final List<OrderItem> items;
  final int? maxItems;

  const OrderItemsList({
    super.key,
    required this.items,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = items.isNotEmpty ? items : defaultSampleOrderItems;
    final visibleItems = maxItems != null
        ? displayItems.take(maxItems!).toList()
        : displayItems;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < visibleItems.length; i++) ...[
            if (i > 0) const Divider(height: 12, thickness: 0.5),
            Row(
              children: [
                ProductThumb(name: visibleItems[i].name, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visibleItems[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      if (visibleItems[i].unitPrice != null ||
                          visibleItems[i].unitMrp != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Unit Price: ${rupees(visibleItems[i].unitPrice ?? visibleItems[i].unitMrp!)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Qty: ${visibleItems[i].quantity}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (maxItems != null && displayItems.length > maxItems!) ...[
            const SizedBox(height: 6),
            Text(
              '+${displayItems.length - maxItems!} more item(s)',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Reusable Filter Chip row
/// ---------------------------------------------------------------------------
class FilterChipsRow<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;

  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final opt in options) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labelBuilder(opt)),
                selected: selected == opt,
                onSelected: (val) {
                  if (val) onSelected(opt);
                },
                selectedColor: AppColors.navy,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: selected == opt ? FontWeight.w700 : FontWeight.w600,
                  color: selected == opt ? Colors.white : AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: selected == opt ? AppColors.navy : AppColors.border,
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Reusable Order Search Bar
/// ---------------------------------------------------------------------------
class OrderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const OrderSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search by Order # or Customer...',
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.navy),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    onClear?.call();
                  },
                )
              : null,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        ),
      ),
    );
  }
}

