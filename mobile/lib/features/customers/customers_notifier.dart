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

  double get totalBakiOutstanding =>
      customers.fold(0.0, (sum, c) => sum + (c.currentBalance > 0 ? c.currentBalance : 0.0));

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

final customersNotifierProvider = StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  final tenantId = ref.watch(authNotifierProvider).tenantId;
  final notifier = CustomersNotifier(tenantId: tenantId);
  if (tenantId != null && tenantId.isNotEmpty) notifier.fetchCustomers();
  return notifier;
});

class CustomersNotifier extends StateNotifier<CustomersState> {
  final String? tenantId;

  CustomersNotifier({this.tenantId}) : super(const CustomersState());

  Future<void> fetchCustomers() async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty) {
      state = state.copyWith(customers: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

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

        final shiftInfo = await _resolveActiveShiftAndAttendance(tId);

        state = state.copyWith(
          customers: fetchedList,
          activeShiftName: shiftInfo['shiftName'] as String? ?? 'Lunch',
          activeShiftRate: (shiftInfo['shiftRate'] as num?)?.toDouble() ?? 80.0,
          markedCustomerIds: (shiftInfo['markedIds'] as Set<String>?) ?? {},
          isLoading: false,
        );

        await HiveService.setCache('customers_$tId', {
          'list': fetchedList.map((c) => c.toJson()).toList(),
        });
        return;
      } catch (e) {
        debugPrint('fetchCustomers error: $e');
      }
    }

    final cached = HiveService.getCache('customers_$tId');
    if (cached != null && cached['list'] is List) {
      final cachedList = (cached['list'] as List)
          .map((json) => Customer.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      state = state.copyWith(customers: cachedList, isLoading: false);
      return;
    }

    state = state.copyWith(customers: [], isLoading: false);
  }

  Future<Map<String, dynamic>> _resolveActiveShiftAndAttendance(String tId) async {
    String shiftName = 'Lunch';
    double shiftRate = 80.0;
    Set<String> markedIds = {};

    try {
      final shiftId = await SupabaseService.client
          .rpc('get_current_shift', params: {'p_tenant_id': tId}) as String?;

      if (shiftId != null && shiftId.isNotEmpty) {
        final shiftData = await SupabaseService.client
            .from('shifts')
            .select('name')
            .eq('id', shiftId)
            .maybeSingle();
        if (shiftData != null && shiftData['name'] != null) {
          shiftName = shiftData['name'] as String;
        }

        final mealConfig = await SupabaseService.client
            .from('meal_configs')
            .select('price')
            .eq('tenant_id', tId)
            .eq('shift_id', shiftId)
            .order('effective_date', ascending: false)
            .maybeSingle();
        if (mealConfig != null && mealConfig['price'] != null) {
          shiftRate = (mealConfig['price'] as num).toDouble();
        }

        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final attendance = await SupabaseService.client
            .from('meal_attendance')
            .select('customer_id')
            .eq('tenant_id', tId)
            .eq('shift_id', shiftId)
            .gte('created_at', '${todayStr}T00:00:00')
            .lte('created_at', '${todayStr}T23:59:59');

        final attendanceList = attendance as List;
        markedIds = attendanceList.map((row) => row['customer_id'] as String).toSet();
      }
    } catch (e) {
      debugPrint('_resolveActiveShiftAndAttendance note: $e');
    }

    return {'shiftName': shiftName, 'shiftRate': shiftRate, 'markedIds': markedIds};
  }

  Future<bool> recordMealAttendance(String customerId) async {
    final tId = tenantId ?? 'tenant-demo';
    final isAlreadyMarked = state.markedCustomerIds.contains(customerId);
    final mealCharge = state.activeShiftRate;

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

    state = state.copyWith(markedCustomerIds: newMarkedSet, customers: updatedCustomers);

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc('record_meal_attendance', params: {
          'p_tenant_id': tId,
          'p_customer_id': customerId,
        }) as Map<String, dynamic>?;

        if (res != null) {
          final action = res['action'] as String?;
          final newBalance = (res['new_balance'] as num?)?.toDouble();

          if (action == 'added') newMarkedSet.add(customerId);
          if (action == 'removed') newMarkedSet.remove(customerId);

          if (newBalance != null) {
            final syncedCustomers = state.customers.map((c) {
              return c.id == customerId ? c.copyWith(currentBalance: newBalance) : c;
            }).toList();
            state = state.copyWith(markedCustomerIds: newMarkedSet, customers: syncedCustomers);
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('recordMealAttendance RPC error: $e');
      return true;
    }
  }

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
        final finalizedList = state.customers.map((c) => c.id == tempId ? created : c).toList();
        state = state.copyWith(customers: finalizedList);
        await HiveService.setCache('customers_$tId', {'list': finalizedList.map((c) => c.toJson()).toList()});
        return true;
      }
    } catch (e) {
      debugPrint('addCustomer error: $e');
    }

    await HiveService.setCache('customers_$tId', {'list': updatedList.map((c) => c.toJson()).toList()});
    return true;
  }

  Future<bool> collectBaki({
    required String customerId,
    required double amount,
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';

    final updatedList = state.customers.map((c) {
      if (c.id == customerId) {
        final newBal = (c.currentBalance - amount).clamp(0.0, double.infinity);
        return c.copyWith(currentBalance: newBal);
      }
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList);
    await HiveService.setCache('customers_$tId', {'list': updatedList.map((c) => c.toJson()).toList()});

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
            final syncedList = state.customers.map((c) {
              return c.id == customerId ? c.copyWith(currentBalance: newBalance) : c;
            }).toList();
            state = state.copyWith(customers: syncedList);
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('collectBaki error: $e');
      return true;
    }
  }

  Future<bool> addManualBaki({
    required String customerId,
    required double amount,
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';

    final updatedList = state.customers.map((c) {
      if (c.id == customerId) return c.copyWith(currentBalance: c.currentBalance + amount);
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        final walletRes = await SupabaseService.client
            .from('customer_wallets')
            .select('id')
            .eq('customer_id', customerId)
            .maybeSingle();

        if (walletRes != null && walletRes['id'] != null) {
          final walletId = walletRes['id'] as String;
          await SupabaseService.client.from('wallet_entries').insert({
            'tenant_id': tId,
            'wallet_id': walletId,
            'type': 'adjustment',
            'amount': amount,
            'reference_type': 'manual_adjustment',
            'notes': notes ?? 'Manual Baki Entry',
          });
        }
      }
      return true;
    } catch (e) {
      debugPrint('addManualBaki error: $e');
      return true;
    }
  }

  Future<bool> updateMealSubscription({
    required String customerId,
    required List<String> subscribedShifts,
  }) async {
    debugPrint('updateMealSubscription for $customerId: $subscribedShifts');
    return true;
  }

  Future<void> deleteCustomer(String customerId) async {
    final tId = tenantId ?? 'tenant-demo';
    final updatedList = state.customers.where((c) => c.id != customerId).toList();
    state = state.copyWith(customers: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('customers').update({'is_active': false}).eq('id', customerId);
      }
    } catch (e) {
      debugPrint('deleteCustomer error: $e');
    }

    await HiveService.setCache('customers_$tId', {'list': updatedList.map((c) => c.toJson()).toList()});
  }

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
        return c.copyWith(name: name, phone: phone, address: address, institution: institution);
      }
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList);
    await HiveService.setCache('customers_$tId', {'list': updatedList.map((c) => c.toJson()).toList()});

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

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
