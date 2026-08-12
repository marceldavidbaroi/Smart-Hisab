import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

class Vendor {
  final String id;
  final String tenantId;
  final String name;
  final String phone;
  final double currentBalance;
  final DateTime updatedAt;

  const Vendor({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.phone,
    required this.currentBalance,
    required this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'phone': phone,
      'current_balance': currentBalance,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Vendor copyWith({
    String? name,
    String? phone,
    double? currentBalance,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      currentBalance: currentBalance ?? this.currentBalance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VendorsState {
  final bool isLoading;
  final List<Vendor> vendors;
  final String? errorMessage;

  const VendorsState({
    this.isLoading = false,
    this.vendors = const [],
    this.errorMessage,
  });

  VendorsState copyWith({
    bool? isLoading,
    List<Vendor>? vendors,
    String? errorMessage,
  }) {
    return VendorsState(
      isLoading: isLoading ?? this.isLoading,
      vendors: vendors ?? this.vendors,
      errorMessage: errorMessage,
    );
  }

  double get totalVendorDebt {
    return vendors.fold(0.0, (sum, item) => sum + item.currentBalance);
  }
}

final vendorsNotifierProvider =
    StateNotifierProvider<VendorsNotifier, VendorsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return VendorsNotifier(tenantId: authState.tenantId);
});

class VendorsNotifier extends StateNotifier<VendorsState> {
  final String? tenantId;

  VendorsNotifier({required this.tenantId}) : super(const VendorsState()) {
    fetchVendors();
  }

  Future<void> fetchVendors() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .from('vendors')
            .select('*')
            .eq('tenant_id', tenantId!)
            .order('name', ascending: true) as List<dynamic>;

        final loaded = res
            .map((e) => Vendor.fromJson(e as Map<String, dynamic>))
            .toList();

        // Cache locally
        await HiveService.cacheBox.put(
            'vendors_$tenantId', loaded.map((e) => e.toJson()).toList());

        state = state.copyWith(isLoading: false, vendors: loaded);
        return;
      }
    } catch (e) {
      debugPrint('Vendors fetch error: $e');
    }

    // Hive offline / demo fallback
    final cached = HiveService.getCache('vendors_$tenantId') as List<dynamic>?;
    if (cached != null && cached.isNotEmpty) {
      final loaded = cached
          .map((e) => Vendor.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = state.copyWith(isLoading: false, vendors: loaded);
      return;
    }

    // Default demo data
    final demoVendors = [
      Vendor(
        id: 'ven-001',
        tenantId: tenantId ?? 'demo-tenant',
        name: 'Rahim Rice Store',
        phone: '01711223344',
        currentBalance: 4500.0,
        updatedAt: DateTime.now(),
      ),
      Vendor(
        id: 'ven-002',
        tenantId: tenantId ?? 'demo-tenant',
        name: 'Dhaka Poultry Enterprise',
        phone: '01899887766',
        currentBalance: 8200.0,
        updatedAt: DateTime.now(),
      ),
      Vendor(
        id: 'ven-003',
        tenantId: tenantId ?? 'demo-tenant',
        name: 'Green Super Oil & Spices',
        phone: '01912345678',
        currentBalance: 1500.0,
        updatedAt: DateTime.now(),
      ),
    ];

    state = state.copyWith(isLoading: false, vendors: demoVendors);
  }

  /// Add a new vendor with optimistic update
  Future<bool> addVendor({required String name, required String phone}) async {
    final newVendor = Vendor(
      id: 'ven-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId ?? 'demo-tenant',
      name: name,
      phone: phone,
      currentBalance: 0.0,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(vendors: [newVendor, ...state.vendors]);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client.from('vendors').insert(newVendor.toJson());
      }
      return true;
    } catch (e) {
      debugPrint('addVendor error: $e');
      return true; // Keep local optimistic state
    }
  }

  /// Record payment to vendor (`record_vendor_payment` RPC) with optimistic update
  Future<bool> recordVendorPayment({
    required String vendorId,
    required double amount,
    String? notes,
  }) async {
    final index = state.vendors.indexWhere((v) => v.id == vendorId);
    if (index == -1) return false;

    final target = state.vendors[index];
    final updatedBalance = (target.currentBalance - amount).clamp(0.0, double.infinity);
    final updatedVendor = target.copyWith(
      currentBalance: updatedBalance,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<Vendor>.from(state.vendors);
    updatedList[index] = updatedVendor;
    state = state.copyWith(vendors: updatedList);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client.rpc('record_vendor_payment', params: {
          'p_tenant_id': tenantId,
          'p_vendor_id': vendorId,
          'p_amount': amount,
          'p_notes': notes ?? '',
        });
      }
      return true;
    } catch (e) {
      debugPrint('recordVendorPayment RPC error: $e');
      return true; // Retain local optimistic balance
    }
  }

  /// Update vendor details with optimistic cache mutation
  Future<bool> updateVendor({
    required String vendorId,
    required String name,
    required String phone,
  }) async {
    final index = state.vendors.indexWhere((v) => v.id == vendorId);
    if (index == -1) return false;

    final updatedVendor = state.vendors[index].copyWith(
      name: name,
      phone: phone,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<Vendor>.from(state.vendors);
    updatedList[index] = updatedVendor;
    state = state.copyWith(vendors: updatedList);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client
            .from('vendors')
            .update({'name': name, 'phone': phone})
            .eq('id', vendorId);
      }
      return true;
    } catch (e) {
      debugPrint('updateVendor error: $e');
      return true;
    }
  }
}

