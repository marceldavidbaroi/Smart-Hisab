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
  final Map<String, Set<String>> customerAttendanceDates;
  final String activeShiftName;
  final double activeShiftRate;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  const CustomersState({
    this.customers = const [],
    this.markedCustomerIds = const {},
    this.customerAttendanceDates = const {},
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
    Map<String, Set<String>>? customerAttendanceDates,
    String? activeShiftName,
    double? activeShiftRate,
    bool? isLoading,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      markedCustomerIds: markedCustomerIds ?? this.markedCustomerIds,
      customerAttendanceDates: customerAttendanceDates ?? this.customerAttendanceDates,
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
  return CustomersNotifier(tenantId: tenantId);
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

        state = state.copyWith(
          customers: fetchedList,
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

  Set<String> getCustomerAttendanceDates(String customerId) {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final dates = state.customerAttendanceDates[customerId] ?? {};
    if (state.markedCustomerIds.contains(customerId) && !dates.contains(todayStr)) {
      return {...dates, todayStr};
    }
    return dates;
  }

  Future<void> toggleCustomerAttendanceDate(String customerId, DateTime date) async {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final isToday = dateKey == todayKey;

    final existingDates = Set<String>.from(getCustomerAttendanceDates(customerId));
    final isCurrentlyMarked = existingDates.contains(dateKey);

    if (!isCurrentlyMarked) {
      // 1. Mark attendance date locally
      existingDates.add(dateKey);

      final updatedMap = Map<String, Set<String>>.from(state.customerAttendanceDates);
      updatedMap[customerId] = existingDates;
      state = state.copyWith(customerAttendanceDates: updatedMap);

      if (isToday) {
        // recordMealAttendance will update balance (locally & RPC)
        await recordMealAttendance(customerId);
      } else {
        // Record baki entry for past/future non-today date
        final mealCharge = state.activeShiftRate > 0 ? state.activeShiftRate : 80.0;
        await addManualBaki(
          customerId: customerId,
          amount: mealCharge,
          notes: 'Meal Attendance ($dateKey)',
          entryDate: date,
        );
      }
    }
  }

  Future<bool> addCustomer({
    required String name,
    required String phone,
    String? address,
    String? institution,
    double openingBaki = 0.0,
  }) async {
    final cleanPhone = phone.trim();

    // 1. Check if active customer already exists in local state
    final activeDuplicateExists = state.customers.any(
      (c) => (c.phone ?? '').trim() == cleanPhone,
    );
    if (activeDuplicateExists) {
      state = state.copyWith(errorMessage: 'An active customer with phone ($cleanPhone) already exists.');
      return false;
    }

    final tId = tenantId ?? 'tenant-demo';

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc(
          'create_or_reactivate_customer',
          params: {
            'p_tenant_id': tId,
            'p_name': name,
            'p_phone': cleanPhone,
            'p_address': address,
            'p_institution': institution,
          },
        );

        if (res != null && res['customer'] != null) {
          final customerData = Map<String, dynamic>.from(res['customer'] as Map);
          var customerObj = Customer.fromJson(customerData);

          // If opening baki is provided, record manual baki entry / initial debt
          if (openingBaki > 0) {
            customerObj = customerObj.copyWith(currentBalance: openingBaki);
            // Record opening balance adjustment entry asynchronously
            addManualBaki(
              customerId: customerObj.id,
              amount: openingBaki,
              notes: 'Opening Baki (পূর্বের খাতার বাকি)',
            );
          }

          // If reactivated, remove any stale copy in list if present, then add to front
          final updatedList = [
            customerObj,
            ...state.customers.where((c) => c.id != customerObj.id),
          ];

          state = state.copyWith(customers: updatedList, errorMessage: null);
          await HiveService.setCache('customers_$tId', {'list': updatedList.map((c) => c.toJson()).toList()});
          return true;
        }
      }
    } catch (e) {
      debugPrint('addCustomer error: $e');
      final errStr = e.toString();
      if (errStr.contains('already exists') ||
          errStr.contains('duplicate key') ||
          errStr.contains('idx_unique_active_customer_phone_per_tenant')) {
        state = state.copyWith(errorMessage: 'An active customer with phone ($cleanPhone) already exists.');
        return false;
      }
      state = state.copyWith(errorMessage: 'Failed to create customer: $errStr');
      return false;
    }

    // Demo / Offline fallback
    final tempId = 'cust-${DateTime.now().millisecondsSinceEpoch}';
    final newCustomer = Customer(
      id: tempId,
      tenantId: tId,
      name: name,
      phone: cleanPhone,
      address: address,
      institution: institution,
      currentBalance: openingBaki > 0 ? openingBaki : 0.0,
      createdAt: DateTime.now(),
    );

    final updatedList = [newCustomer, ...state.customers];
    state = state.copyWith(customers: updatedList, errorMessage: null);
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
    DateTime? entryDate,
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
          final entryPayload = <String, dynamic>{
            'tenant_id': tId,
            'wallet_id': walletId,
            'type': 'adjustment',
            'amount': amount,
            'reference_type': 'manual_adjustment',
            'notes': notes ?? 'Manual Baki Entry',
          };
          if (entryDate != null) {
            entryPayload['created_at'] = entryDate.toIso8601String();
          }
          await SupabaseService.client.from('wallet_entries').insert(entryPayload);
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
    final tId = tenantId ?? 'tenant-demo';
    final updatedList = state.customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(activeMeals: subscribedShifts);
      }
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList);
    await HiveService.setCache('customers_$tId', {'list': updatedList.map((c) => c.toJson()).toList()});

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('customers').update({
          'subscribed_shifts': subscribedShifts,
        }).eq('id', customerId);
      }
      return true;
    } catch (e) {
      debugPrint('updateMealSubscription error: $e');
      return true;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    final tId = tenantId ?? 'tenant-demo';
    final customer = state.customers.where((c) => c.id == customerId).firstOrNull;

    // Check local debt first
    if (customer != null && customer.currentBalance > 0) {
      state = state.copyWith(
        errorMessage: 'Cannot delete customer with outstanding balance of ৳${customer.currentBalance.toStringAsFixed(0)}. Settle balance first.',
      );
      return false;
    }

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('customers').update({'is_active': false}).eq('id', customerId);
      }

      final updatedList = state.customers.where((c) => c.id != customerId).toList();
      state = state.copyWith(customers: updatedList, errorMessage: null);
      await HiveService.setCache('customers_$tId', {'list': updatedList.map((c) => c.toJson()).toList()});
      return true;
    } catch (e) {
      debugPrint('deleteCustomer error: $e');
      final errStr = e.toString();
      if (errStr.contains('Cannot deactivate customer with outstanding debt balance')) {
        state = state.copyWith(errorMessage: 'Cannot delete customer with outstanding debt. Settle balance first.');
      } else {
        state = state.copyWith(errorMessage: 'Failed to delete customer: $errStr');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchCustomerStatement({
    required String customerId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty || !SupabaseService.isInitialized) {
      return {'entries': [], 'total_count': 0, 'opening_balance': 0.0};
    }

    try {
      final res = await SupabaseService.client.rpc(
        'get_customer_statement',
        params: {
          'p_tenant_id': tId,
          'p_customer_id': customerId,
          'p_start': startDate?.toIso8601String().substring(0, 10),
          'p_end': endDate?.toIso8601String().substring(0, 10),
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (res != null && res is Map) {
        final entriesList = (res['entries'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];
        final totalCount = (res['total_count'] as num?)?.toInt() ?? entriesList.length;
        final openingBalance = (res['opening_balance'] as num?)?.toDouble() ?? 0.0;

        return {
          'entries': entriesList,
          'total_count': totalCount,
          'opening_balance': openingBalance,
        };
      }
    } catch (e) {
      debugPrint('fetchCustomerStatement RPC error: $e');
    }

    return {'entries': [], 'total_count': 0, 'opening_balance': 0.0};
  }

  void markCustomerAsPresentLocally(String customerId) {
    if (!state.markedCustomerIds.contains(customerId)) {
      state = state.copyWith(
        markedCustomerIds: {...state.markedCustomerIds, customerId},
      );
    }
  }

  Future<void> fetchCustomerAttendanceOnDemand(String customerId) async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty || !SupabaseService.isInitialized) return;

    try {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final attendanceRes = await SupabaseService.client
          .from('meal_attendance')
          .select('customer_id, created_at')
          .eq('tenant_id', tId)
          .eq('customer_id', customerId)
          .gte('created_at', '${todayStr}T00:00:00')
          .lte('created_at', '${todayStr}T23:59:59');

      final attendanceList = attendanceRes as List;
      final newMarkedSet = Set<String>.from(state.markedCustomerIds);
      if (attendanceList.isNotEmpty) {
        newMarkedSet.add(customerId);
      } else {
        newMarkedSet.remove(customerId);
      }

      state = state.copyWith(markedCustomerIds: newMarkedSet);
    } catch (e) {
      debugPrint('fetchCustomerAttendanceOnDemand error: $e');
    }
  }

  Future<double> resolveShiftRateOnDemand() async {
    if (state.activeShiftRate > 0) return state.activeShiftRate;
    final tId = tenantId;
    if (tId == null || tId.isEmpty || !SupabaseService.isInitialized) return 80.0;

    try {
      final mealConfig = await SupabaseService.client
          .from('meal_configs')
          .select('rate')
          .eq('tenant_id', tId)
          .order('effective_from', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mealConfig != null && mealConfig['rate'] != null) {
        final rate = (mealConfig['rate'] as num).toDouble();
        state = state.copyWith(activeShiftRate: rate);
        return rate;
      }
    } catch (e) {
      debugPrint('resolveShiftRateOnDemand error: $e');
    }
    return 80.0;
  }

  Future<double?> fetchCustomerBalance(String customerId) async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty || !SupabaseService.isInitialized) return null;

    try {
      final res = await SupabaseService.client.rpc(
        'get_customer_balance',
        params: {
          'p_tenant_id': tId,
          'p_customer_id': customerId,
        },
      );
      if (res != null && res is num) {
        return res.toDouble();
      }
    } catch (e) {
      debugPrint('fetchCustomerBalance RPC error: $e');
    }
    return null;
  }

  Future<bool> updateCustomer({
    required String customerId,
    required String name,
    required String phone,
    String? address,
    String? institution,
  }) async {
    final cleanPhone = phone.trim();
    final duplicateExists = state.customers.any(
      (c) => c.id != customerId && (c.phone ?? '').trim() == cleanPhone,
    );
    if (duplicateExists) {
      state = state.copyWith(errorMessage: 'Another customer with this phone number ($cleanPhone) already exists.');
      return false;
    }

    final tId = tenantId ?? 'tenant-demo';

    final updatedList = state.customers.map((c) {
      if (c.id == customerId) {
        return c.copyWith(name: name, phone: cleanPhone, address: address, institution: institution);
      }
      return c;
    }).toList();

    state = state.copyWith(customers: updatedList, errorMessage: null);
    await HiveService.setCache('customers_$tId', {'list': updatedList.map((c) => c.toJson()).toList()});

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('customers').update({
          'name': name,
          'phone': cleanPhone,
          'address': address,
          'institution': institution,
        }).eq('id', customerId);
      }
      return true;
    } catch (e) {
      debugPrint('updateCustomer error: $e');
      if (e.toString().contains('duplicate key') || e.toString().contains('customers_phone')) {
        state = state.copyWith(errorMessage: 'Phone number $cleanPhone is already registered to another customer.');
        return false;
      }
      return true;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> voidWalletEntry({
    required String customerId,
    required String entryId,
    required String reason,
    String? entryDateStr,
  }) async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty) return false;

    try {
      if (SupabaseService.isInitialized) {
        // Fetch target entry details to check if it's an attendance entry
        final entryRes = await SupabaseService.client
            .from('wallet_entries')
            .select('created_at, notes, type')
            .eq('id', entryId)
            .maybeSingle();

        final createdAtStr = entryRes?['created_at']?.toString() ?? entryDateStr;
        final notesStr = entryRes?['notes']?.toString() ?? '';

        await SupabaseService.client.rpc('void_wallet_entry', params: {
          'p_tenant_id': tId,
          'p_entry_id': entryId,
          'p_reason': reason,
        });

        // If this entry was a meal attendance entry, remove the date from attendance set
        if (createdAtStr != null && (notesStr.contains('Meal Attendance') || notesStr.contains('Meal Charge'))) {
          final targetDateKey = createdAtStr.substring(0, 10);
          final todayKey = DateTime.now().toIso8601String().substring(0, 10);

          final existingDates = Set<String>.from(getCustomerAttendanceDates(customerId));
          existingDates.remove(targetDateKey);

          final updatedMap = Map<String, Set<String>>.from(state.customerAttendanceDates);
          updatedMap[customerId] = existingDates;

          final newMarkedSet = Set<String>.from(state.markedCustomerIds);
          if (targetDateKey == todayKey) {
            newMarkedSet.remove(customerId);
          }

          state = state.copyWith(
            customerAttendanceDates: updatedMap,
            markedCustomerIds: newMarkedSet,
          );
        }

        // Re-sync customer list & wallet balances
        await fetchCustomers();
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('voidWalletEntry RPC error: $e');
      rethrow;
    }
  }
}

