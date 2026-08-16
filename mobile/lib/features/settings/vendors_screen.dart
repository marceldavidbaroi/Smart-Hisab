import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'record_vendor_payment_bottom_sheet.dart';
import 'vendor_detail_screen.dart';
import 'vendors_notifier.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddVendorSheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    CustomModalBottomSheet.show(
      context: context,
      title: "Add New Vendor / Supplier",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Supplier / Store Name *",
              hintText: "e.g. Rahim Rice Dealer, Karim Bazar Store",
              prefixIcon: const Icon(LucideIcons.store, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              hintText: "e.g. 017XXXXXXXX",
              prefixIcon: const Icon(LucideIcons.phone, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                NotificationService.showError("Vendor name is required");
                return;
              }

              final success = await ref.read(vendorsNotifierProvider.notifier).addVendor(
                    name: name,
                    phone: phoneController.text.trim(),
                  );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  NotificationService.showSuccess("Vendor '$name' registered with wallet!");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(LucideIcons.plusCircle, color: Colors.white),
            label: const Text('Add Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showRecordVendorPaymentSheet(BuildContext context, Vendor vendor) {
    RecordVendorPaymentBottomSheet.show(context, vendor);
  }

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(vendorsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredVendors = vendorsState.vendors.where((v) {
      return v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.phone.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors & Suppliers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddVendorSheet(context),
            icon: const Icon(LucideIcons.plus, color: AppColors.primary, size: 24),
            tooltip: 'Add Vendor',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(vendorsNotifierProvider.notifier).fetchVendors(),
          color: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Summary & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suppliers Directory (${vendorsState.vendors.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bazar credit accounts & ledger history',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddVendorSheet(context),
                      icon: const Icon(LucideIcons.store, size: 16, color: Colors.white),
                      label: const Text(
                        'Add Vendor',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Total Accounts Payable Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Outstanding Bazar Baki (We Owe)',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '৳${vendorsState.totalVendorDebt.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.alertCircle, color: AppColors.danger, size: 22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Search Bar
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search suppliers by name or phone...',
                    hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13),
                    prefixIcon: Icon(LucideIcons.search, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                  ),
                ),
                const SizedBox(height: 14),

                // Vendors List
                Expanded(
                  child: vendorsState.isLoading
                      ? const ShimmerListLoader(itemCount: 4)
                      : filteredVendors.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.store, size: 40, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No Suppliers Registered',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Register rice dealers, vegetable sellers, grocery stores to track credit accounts.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () => _showAddVendorSheet(context),
                                      icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                                      label: const Text('Add First Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredVendors.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final vendor = filteredVendors[index];
                                return Dismissible(
                                  key: Key(vendor.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.success,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(LucideIcons.creditCard, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    _showRecordVendorPaymentSheet(context, vendor);
                                    return false;
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: Text(
                                          vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ),
                                      title: Text(
                                        vendor.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      subtitle: Text(
                                        vendor.phone.isNotEmpty ? vendor.phone : 'No phone listed',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '৳${vendor.currentBalance.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: vendor.currentBalance > 0 ? AppColors.danger : AppColors.success,
                                            ),
                                          ),
                                          Text(
                                            vendor.currentBalance > 0 ? 'Due (Swipe to Pay)' : 'Settled',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: vendor.currentBalance > 0 ? AppColors.danger : AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => VendorDetailScreen(vendorId: vendor.id),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
