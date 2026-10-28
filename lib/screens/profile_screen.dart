import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final StaffUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late StaffUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    try {
      final updated = await SupabaseService.getCurrentStaff();
      if (updated != null && mounted) {
        setState(() => _user = updated);
      }
    } catch (_) {}
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await SupabaseService.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showAddExpenseDialog() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final formattedDateStr =
              DateFormat('d MMM yyyy').format(selectedDate);

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Expense',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Expense Amount *',
                        hintText: 'e.g. 500',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) {
                          return 'Please enter expense amount';
                        }
                        final parsed = double.tryParse(text);
                        if (parsed == null || parsed <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: IgnorePointer(
                        child: TextFormField(
                          key: ValueKey(formattedDateStr),
                          initialValue: formattedDateStr,
                          decoration: const InputDecoration(
                            labelText: 'Expense Date *',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            suffixIcon: Icon(Icons.arrow_drop_down),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note / Description (Optional)',
                        hintText: 'e.g. Petrol',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                final amtText = amountController.text.trim();
                                final amount = double.tryParse(amtText) ?? 0.0;
                                final note = noteController.text.trim();

                                setModalState(() => saving = true);
                                try {
                                  await SupabaseService.addExpense(
                                    staffId: _user.id,
                                    amount: amount,
                                    date: selectedDate,
                                    note: note,
                                  );
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Expense saved successfully!',
                                        ),
                                        backgroundColor: AppColors.navy,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to save expense: $e'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setModalState(() => saving = false);
                                  }
                                }
                              },
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Expense',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final isDelivery = user.role == StaffRole.delivery;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const KmartLogo(
                        fontSize: 18,
                        subtitle: 'Staff Portal',
                        onDark: true,
                      ),
                      const Spacer(),
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
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Profile',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View and manage your profile details.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'You\nMove\nK Mart!',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            InitialsAvatar(
                              initials: user.initials,
                              size: 66,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      StatusChip(
                                        label: user.role.label,
                                        background: AppColors.primary,
                                        foreground: Colors.white,
                                        icon: isDelivery
                                            ? Icons.local_shipping
                                            : Icons.inventory_2,
                                      ),
                                      StatusChip.info(user.store),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(),
                        ),
                        _DetailRow(
                          icon: Icons.mail_outline,
                          label: 'Email',
                          value: user.email,
                        ),
                        if (user.phone.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _DetailRow(
                            icon: Icons.call_outlined,
                            label: 'Phone Number',
                            value: user.phone,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _DetailRow(
                          icon: Icons.badge_outlined,
                          label: 'Employee ID',
                          value: user.employeeId,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on,
                          color: AppColors.primary),
                    ),
                    title: Text(
                      '${user.store} Address',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        user.storeAddress.isNotEmpty
                            ? user.storeAddress
                            : 'Assigned store location',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Expense Option
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long,
                          color: AppColors.primary),
                    ),
                    title: const Text(
                      'Expense',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Record petrol, vehicle maintenance, or other work expenses',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary),
                    onTap: _showAddExpenseDialog,
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    onTap: () => _confirmLogout(context),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppColors.primary),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Sign out from your account',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: AppColors.primary),
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }
}
