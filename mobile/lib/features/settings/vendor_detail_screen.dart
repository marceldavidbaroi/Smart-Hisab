import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'edit_vendor_bottom_sheet.dart';
import 'vendors_notifier.dart';

class VendorDetailScreen extends ConsumerWidget {
  final String vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsState = ref.watch(vendorsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final vendor = vendorsState.vendors.firstWhere(
      (v) => v.id == vendorId,
      orElse: () => Vendor(
        id: vendorId,
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
        title: Text(vendor.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.edit3, size: 20, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            onPressed: () => EditVendorBottomSheet.show(context, vendor),
          ),
        ],
      ),
      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(vendorsNotifierProvider.notifier).fetchVendors(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card - We Owe This Vendor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                        : const [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      vendor.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.phone, size: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        const SizedBox(width: 6),
                        Text(
                          vendor.phone.isNotEmpty ? vendor.phone : 'No phone listed',
                          style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    const SizedBox(height: 16),
                    Text('We Owe This Vendor', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    const SizedBox(height: 4),
                    Text(
                      '৳${vendor.currentBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: vendor.currentBalance > 0 ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Transaction History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 12),

              if (vendorsState.isLoading)
                const ShimmerListLoader(itemCount: 4)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x1A10B981),
                          child: Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
                        ),
                        title: Text('Vendor Account Initialized', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        subtitle: Text(
                          'Recorded ${vendor.updatedAt.toString().substring(0, 10)}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        trailing: Text(
                          '৳${vendor.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
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
