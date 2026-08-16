import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'add_vendor_baki_bottom_sheet.dart';
import 'edit_vendor_bottom_sheet.dart';
import 'record_vendor_payment_bottom_sheet.dart';
import 'vendors_notifier.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  bool _isLoadingLedger = true;
  List<Map<String, dynamic>> _ledgerEntries = [];

  @override
  void initState() {
    super.initState();
    _fetchVendorLedger();
  }

  Future<void> _fetchVendorLedger() async {
    if (!mounted) return;
    setState(() => _isLoadingLedger = true);

    try {
      final res = await ref
          .read(vendorsNotifierProvider.notifier)
          .fetchVendorStatement(vendorId: widget.vendorId);

      if (mounted) {
        setState(() {
          _ledgerEntries =
              List<Map<String, dynamic>>.from(res['entries'] as List? ?? []);
          _isLoadingLedger = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('_fetchVendorLedger error: $e');
    }

    if (mounted) {
      setState(() {
        _ledgerEntries = [];
        _isLoadingLedger = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    if (phone.trim().isEmpty) {
      NotificationService.showError("No phone number registered for this vendor");
      return;
    }
    final uri = Uri.parse('tel:${phone.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      NotificationService.showError("Could not launch phone dialer");
    }
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerCard(Map<String, dynamic> entry, bool isDark) {
    final type = (entry['type'] as String? ?? 'purchase').toLowerCase();
    final isPurchase = type == 'purchase';
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    final notes = entry['notes'] as String? ?? '';
    final rawDate = entry['created_at']?.toString() ?? '';
    final formattedDate = rawDate.isNotEmpty && rawDate.length >= 10
        ? rawDate.substring(0, 10)
        : 'Recent';
    final staffName = entry['recorded_by_staff_name'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: isPurchase
                ? AppColors.danger.withValues(alpha: 0.12)
                : AppColors.success.withValues(alpha: 0.12),
            radius: 20,
            child: Icon(
              isPurchase ? LucideIcons.shoppingBag : LucideIcons.checkCircle,
              color: isPurchase ? AppColors.danger : AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPurchase
                            ? AppColors.danger.withValues(alpha: 0.15)
                            : AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPurchase ? 'BAKI PURCHASE' : 'PAYMENT PAID',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPurchase ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notes.isNotEmpty
                      ? notes
                      : (isPurchase ? 'Wholesale credit purchase' : 'Payment settlement'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                if (staffName != null && staffName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Recorded by: $staffName',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isPurchase ? '+' : '-'}৳${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPurchase ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(vendorsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final vendor = vendorsState.vendors.firstWhere(
      (v) => v.id == widget.vendorId,
      orElse: () => Vendor(
        id: widget.vendorId,
        tenantId: '',
        name: 'Vendor',
        phone: '',
        currentBalance: 0.0,
        updatedAt: DateTime.now(),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          vendor.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.edit3,
              size: 20,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: () => EditVendorBottomSheet.show(context, vendor),
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.trash2,
              size: 20,
              color: AppColors.danger,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Supplier?'),
                  content: Text(
                    'Are you sure you want to delete ${vendor.name}? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                final success = await ref.read(vendorsNotifierProvider.notifier).deleteVendor(vendor.id);
                if (context.mounted) {
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Supplier ${vendor.name} deleted'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  } else {
                    final err = ref.read(vendorsNotifierProvider).errorMessage ?? 'Failed to delete vendor';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(vendorsNotifierProvider.notifier).fetchVendors();
            await _fetchVendorLedger();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card - We Owe This Vendor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                        : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      vendor.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (vendor.phone.isNotEmpty)
                      InkWell(
                        onTap: () => _makePhoneCall(vendor.phone),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.phone, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                vendor.phone,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Text(
                        'No phone listed',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Outstanding Debt (আমরা মহাজনকে কত দেব)',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳${vendor.currentBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: vendor.currentBalance > 0
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons: Pay Due vs Add Baki
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: LucideIcons.plusCircle,
                      label: 'Add Baki (বাকি ক্রয়)',
                      color: AppColors.danger,
                      onTap: () async {
                        await AddVendorBakiBottomSheet.show(context, vendor);
                        _fetchVendorLedger();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      context: context,
                      icon: LucideIcons.checkCircle2,
                      label: 'Pay Due (পরিশোধ)',
                      color: AppColors.success,
                      onTap: () async {
                        await RecordVendorPaymentBottomSheet.show(context, vendor);
                        _fetchVendorLedger();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Transaction Ledger
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Passbook (খতিয়ান)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (_ledgerEntries.isNotEmpty)
                    Text(
                      '${_ledgerEntries.length} entries',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoadingLedger)
                const ShimmerListLoader(itemCount: 4)
              else if (_ledgerEntries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.fileText,
                        size: 36,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No Ledger Entries Yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Add Baki" or "Pay Due" to start recording transactions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._ledgerEntries.map((entry) => _buildLedgerCard(entry, isDark)),
            ],
          ),
        ),
      ),
    );
  }
}
