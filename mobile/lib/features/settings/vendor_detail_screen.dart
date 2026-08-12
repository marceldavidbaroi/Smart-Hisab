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
      appBar: AppBar(
        title: Text(vendor.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, size: 20),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorderDark),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.phone, size: 14, color: AppColors.textSecondaryDark),
                        const SizedBox(width: 6),
                        Text(
                          vendor.phone.isNotEmpty ? vendor.phone : 'No phone listed',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.cardBorderDark),
                    const SizedBox(height: 16),
                    const Text('We Owe This Vendor', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark)),
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

              const Text(
                'Transaction History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),

              if (vendorsState.isLoading)
                const ShimmerListLoader(itemCount: 4)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorderDark),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x1A10B981),
                          child: Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
                        ),
                        title: const Text('Vendor Account Initialized', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(
                          'Recorded ${vendor.updatedAt.toString().substring(0, 10)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                        ),
                        trailing: Text(
                          '৳${vendor.currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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
