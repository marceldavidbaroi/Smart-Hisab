import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/customer.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

@immutable
class CustomersState {
  final List<Customer> customers;
  final Set<String> markedCustomerIds;
  final String activeShiftName;
  final double activeShiftRate;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  const CustomersState({
    this.customers = const [],
    this.markedCustomerIds = const {},
    this.activeShiftName = 'Lunch',
    this.activeShiftRate = 80.0,
    this.isLoading = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<Customer> get filteredCustomers {
    if (searchQuery.trim().isEmpty) return customers;
    final query = searchQuery.trim().toLowerCase();
    return customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(query);
      final phoneMatch = (c.phone ?? '').contains(query);
      final instMatch = (c.institution ?? '').toLowerCase().contains(query);
      return nameMatch || phoneMatch || instMatch;
    }).toList();
  }

  double get totalBakiOutstanding {
    return customers.fold(0.0, (sum, c) => sum + (c.currentBalance > 0 ? c.currentBalance : 0.0));
  }

  CustomersState copyWith({
    List<Customer>? customers,
    Set<String>? markedCustomerIds,
    String? activeShiftName,
    double? activeShiftRate,
    bool? isLoading,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      markedCustomerIds: markedCustomerIds ?? this.markedCustomerIds,
      activeShiftName: activeShiftName ?? this.activeShiftName,
      activeShiftRate: activeShiftRate ?? this.activeShiftRate,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

final customersNotifierProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  final tenantId = ref.watch(authNotifierProvider).tenantId;
  final notifier = CustomersNotifier(tenantId: tenantId);
  if (tenantId != null && tenantId.isNotEmpty) {
    notifier.fetchCustomers();
  }
  return notifier;
});

class CustomersNotifier extends StateNotifier<CustomersState> {
  final String? tenantId;

  CustomersNotifier({this.tenantId}) : super(const CustomersState());

  /// Fetch customer list for current tenant from Supabase with local cache fallback
  Future<void> fetchCustomers() async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty) {
      state = state.copyWith(customers: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    // 1. Try fetching from Supabase if initialized
    if (SupabaseService.isInitialized) {
      try {
        final res = await SupabaseService.client
            .from('customers')
            .select('*, customer_wallets(current_balance)')
            .eq('tenant_id', tId)
            .eq('is_active', true)
            .order('created_at', ascending: false);

        final fetchedList = (res as List)
            .map((json) => Customer.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();

        state = state.copyWith(customers: fetchedList, isLoading: false);
        await HiveService.setCache('customers_$tId', {
          'list': fetchedList.map((c) => c.toJson()).toList(),
        });
        return;
      } catch (e) {
        debugPrint('fetchCustomers Supabase fetch error: $e');
      }
    }

    // 2. Offline / Local Cache Fallback if network call unavailable
    final cached = HiveService.getCache('customers_$tId');
    if (cached != null && cached['list'] is List) {
      final rawList = cached['list'] as List;
      final cachedList = rawList
          .map((json) => Customer.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      state = state.copyWith(customers: cachedList, isLoading: false);
      return;
    }

    state = state.copyWith(customers: [], isLoading: false);
  }

  /// Toggle meal attendance for a customer with Optimistic Update & RPC call
  Future<bool> recordMealAttendance(String customerId) async {
    final tId = tenantId ?? 'tenant-demo';
    final isAlreadyMarked = state.markedCustomerIds.contains(customerId);
    final mealCharge = state.activeShiftRate;

    // 1. Optimistic state update
    final newMarkedSet = Set<String>.from(state.markedCustomerIds);
    if (isAlreadyMarked) {
      newMarkedSet.remove(customerId);
    } else {
      newMarkedSet.add(customerId);
    }

    final updatedCustomers = state.customers.map((c) {
      if (c.id == customerId) {
        final newBal = isAlreadyMarked
            ? (c.currentBalance - mealCharge).clamp(0.0, double.infinity)
            : c.currentBalance + mealCharge;
        return c.copyWith(currentBalance: newBal);
      }
      return c;
    }).toList();

    state = state.copyWith(
      markedCustomerIds: newMarkedSet,
      customers: updatedCustomers,
    );

    // 2. Network RPC call
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc('record_meal_attendance', params: {
          'p_tenant_id': tId,
          'p_customer_id': customerId,
        }) as Map<String, dynamic>?;

        if (res != null) {
          final action = res['action'] as String?;
          final newBalance = (res['new_balance'] as num?)?.toDouble();

          if (action == 'added') {
            newMarkedSet.add(customerId);
          } else if (action == 'removed') {
            newMarkedSet.remove(customerId);
          }

          if (newBalance != null) {
            final syncedCustomers = state.customers.map((c) {
              return c.id == customerId ? c.copyWith(currentBalance: newBalance) : c;
            }).toList();
            state = state.copyWith(
              markedCustomerIds: newMarkedSet,
              customers: syncedCustomers,
            );
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('recordMealAttendance network RPC error: $e');
      return true; // Retain optimistic UX for fast canteen operation
    }
  }

  /// Add new customer with Targeted Cache Mutation
  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? address,
    String? institution,
  }) async {
    final tId = tenantId ?? 'tenant-demo';
    final tempId = 'cust-${DateTime.now().millisecondsSinceEpoch}';

    final newCustomer = Customer(
      id: tempId,
      tenantId: tId,
      name: name,
      phone: phone,
      address: address,
      institution: institution,
      currentBalance: 0.0,
      createdAt: DateTime.now(),
    );

    // Targeted Cache Mutation: prepend to state immediately
    final updatedList = [newCustomer, ...state.customers];
    state = state.copyWith(customers: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.from('customers').insert({
          'tenant_id': tId,
          'name': name,
          'phone': phone,
          'address': address,
          'institution': institution,
        }).select('*, customer_wallets(current_balance)').single();

        final created = Customer.fromJson(res);
        // Replace temp customer with database persisted customer
        final finalizedList = state.customers
            .map((c) => c.id == tempId ? created : c)
            .toList();
        state = state.copyWith(customers: finalizedList);
        await HiveService.setCache('customers_$tId', {
          'list': finalizedList.map((c) => c.toJson()).toList(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('addCustomer network error: $e');
    }

    await HiveService.setCache('customers_$tId', {
      'list': updatedList.map((c) => c.toJson()).toList(),
    });
    return true;
  }

  /// Collect Baki payment with Optimistic Update & Targeted Cache Mutation
  Future<bool> collectBaki({
    required String customerId,
    required double amount,
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';

    // 1. Optimistic local targeted cache mutation
    final updatedList = state.customers.map((c) {
      if (c.id == customerId) {
        final newBal = (c.currentBalance - amount).clamp(0.0, double.infinity);
        return c.copyWith(currentBalance: newBal);
      }
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList);
    await HiveService.setCache('customers_$tId', {
      'list': updatedList.map((c) => c.toJson()).toList(),
    });

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc('record_baki_payment', params: {
          'p_tenant_id': tId,
          'p_customer_id': customerId,
          'p_amount': amount,
          'p_notes': notes ?? 'Collected Baki',
        }) as Map<String, dynamic>?;

        if (res != null && res['success'] == true && res['data'] != null) {
          final data = res['data'] as Map<String, dynamic>;
          final newBalance = (data['new_balance'] as num?)?.toDouble();
          if (newBalance != null) {
            // Update with exact backend balance
            final syncedList = state.customers.map((c) {
              return c.id == customerId ? c.copyWith(currentBalance: newBalance) : c;
            }).toList();
            state = state.copyWith(customers: syncedList);
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('collectBaki backend error: $e');
      return true; // Keep local optimistic state intact for high speed POS UX
    }
  }

  /// Soft delete or remove customer with Targeted Cache Mutation
  Future<void> deleteCustomer(String customerId) async {
    final tId = tenantId ?? 'tenant-demo';
    final updatedList = state.customers.where((c) => c.id != customerId).toList();
    state = state.copyWith(customers: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client
            .from('customers')
            .update({'is_active': false})
            .eq('id', customerId);
      }
    } catch (e) {
      debugPrint('deleteCustomer error: $e');
    }

    await HiveService.setCache('customers_$tId', {
      'list': updatedList.map((c) => c.toJson()).toList(),
    });
  }

  /// Update customer details with targeted optimistic cache mutation
  Future<bool> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    String? address,
    String? institution,
  }) async {
    final tId = tenantId ?? 'tenant-demo';

    final updatedList = state.customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(
          name: name,
          phone: phone,
          address: address,
          institution: institution,
        );
      }
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList);
    await HiveService.setCache('customers_$tId', {
      'list': updatedList.map((c) => c.toJson()).toList(),
    });

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('customers').update({
          'name': name,
          'phone': phone,
          'address': address,
          'institution': institution,
        }).eq('id', customerId);
      }
      return true;
    } catch (e) {
      debugPrint('updateCustomer error: $e');
      return true;
    }
  }

  /// Update search filter string
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

