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
    // Check if current_balance is embedded from vendor_wallets join or flat field
    double balance = 0.0;
    if (json['vendor_wallets'] != null) {
      if (json['vendor_wallets'] is List && (json['vendor_wallets'] as List).isNotEmpty) {
        balance = (json['vendor_wallets'][0]['current_balance'] as num?)?.toDouble() ?? 0.0;
      } else if (json['vendor_wallets'] is Map) {
        balance = (json['vendor_wallets']['current_balance'] as num?)?.toDouble() ?? 0.0;
      }
    } else if (json['current_balance'] != null) {
      balance = (json['current_balance'] as num?)?.toDouble() ?? 0.0;
    }

    return Vendor(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      currentBalance: balance,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
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
    String? id,
    String? tenantId,
    String? name,
    String? phone,
    double? currentBalance,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
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
    final tId = tenantId;
    state = state.copyWith(isLoading: true, errorMessage: null);

    if (tId != null && tId.isNotEmpty) {
      // Local Hive cache fallback
      final cached = HiveService.getCache('vendors_$tId');
      if (cached != null && cached['data'] is List) {
        final raw = cached['data'] as List;
        final list = raw
            .map((e) => Vendor.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (list.isNotEmpty) {
          state = state.copyWith(vendors: list, isLoading: false);
        }
      }

      if (SupabaseService.isInitialized) {
        try {
          final res = await SupabaseService.client
              .from('vendors')
              .select('*, vendor_wallets(current_balance)')
              .eq('tenant_id', tId)
              .eq('is_active', true)
              .order('name', ascending: true);

          final vendors = (res as List<dynamic>)
              .map((e) => Vendor.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();

          final jsonList = vendors.map((v) => v.toJson()).toList();
          await HiveService.setCache('vendors_$tId', {'data': jsonList});
          state = state.copyWith(isLoading: false, vendors: vendors);
          return;
        } catch (e) {
          debugPrint('fetchVendors error: $e');
        }
      }
    }

    state = state.copyWith(isLoading: false);
  }

  /// Add a new vendor with backend insert and optimistic cache update
  Future<bool> addVendor({required String name, required String phone}) async {
    final tId = tenantId ?? 'demo-tenant';
    final tempId = 'ven-${DateTime.now().millisecondsSinceEpoch}';

    final newVendor = Vendor(
      id: tempId,
      tenantId: tId,
      name: name,
      phone: phone,
      currentBalance: 0.0,
      updatedAt: DateTime.now(),
    );

    // Optimistic cache mutation
    final updatedVendors = [newVendor, ...state.vendors];
    state = state.copyWith(vendors: updatedVendors);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        final res = await SupabaseService.client.from('vendors').insert({
          'tenant_id': tId,
          'name': name,
          'phone': phone.isEmpty ? null : phone,
          'is_active': true,
        }).select().maybeSingle();

        if (res != null && res['id'] != null) {
          fetchVendors();
          return true;
        }
      }
    } catch (e) {
      debugPrint('addVendor error: $e');
    }

    await HiveService.setCache('vendors_$tId', {
      'data': updatedVendors.map((v) => v.toJson()).toList(),
    });
    return true;
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
        fetchVendors();
      }
      return true;
    } catch (e) {
      debugPrint('recordVendorPayment RPC error: $e');
      return true;
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
            .update({'name': name, 'phone': phone.isEmpty ? null : phone})
            .eq('id', vendorId);
        fetchVendors();
      }
      return true;
    } catch (e) {
      debugPrint('updateVendor error: $e');
      return true;
    }
  }
}
