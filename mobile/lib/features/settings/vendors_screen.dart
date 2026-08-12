import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/app_safe_area.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../../core/widgets/shimmer_loading.dart';
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
      title: "Add New Vendor",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Supplier / Store Name *",
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
                  NotificationService.showSuccess("Vendor added successfully");
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
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    CustomModalBottomSheet.show(
      context: context,
      title: "Pay ${vendor.name}",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Current Outstanding Balance: ৳${vendor.currentBalance.toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: "Payment Amount (৳) *",
              prefixText: "৳ ",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: notesController,
            decoration: InputDecoration(
              labelText: "Notes / Voucher Ref",
              prefixIcon: const Icon(LucideIcons.fileText, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount <= 0) {
                NotificationService.showError("Enter a valid payment amount");
                return;
              }

              final success = await ref.read(vendorsNotifierProvider.notifier).recordVendorPayment(
                    vendorId: vendor.id,
                    amount: amount,
                    notes: notesController.text.trim(),
                  );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  NotificationService.showSuccess("Payment of ৳$amount recorded for ${vendor.name}");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(LucideIcons.checkCircle, color: Colors.white),
            label: const Text('Confirm Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
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
        title: const Text('Vendors Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVendorSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: AppSafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(vendorsNotifierProvider.notifier).fetchVendors(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Accounts Payable',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '৳${vendorsState.totalVendorDebt.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search vendors by name or phone...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                if (vendorsState.isLoading)
                  const Expanded(child: ShimmerListLoader(itemCount: 4))
                else if (filteredVendors.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No vendors found',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
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
                            return false; // Prevent auto remove
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.cardBorderDark : const Color(0xFFE2E8F0),
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
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                vendor.phone.isNotEmpty ? vendor.phone : 'No phone listed',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
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
                                  const Text(
                                    'Tap details',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
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
