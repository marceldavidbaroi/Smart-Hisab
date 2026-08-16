import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/staff_member.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

@immutable
class SalaryPayoutRecord {
  final String id;
  final String staffId;
  final double amount;
  final String paymentMode;
  final String payoutType; // 'regular_salary' or 'advance'
  final String? accountId;
  final String? notes;
  final DateTime createdAt;

  const SalaryPayoutRecord({
    required this.id,
    required this.staffId,
    required this.amount,
    this.paymentMode = 'Cash',
    this.payoutType = 'regular_salary',
    this.accountId,
    this.notes,
    required this.createdAt,
  });

  bool get isAdvance => payoutType == 'advance';

  factory SalaryPayoutRecord.fromJson(Map<String, dynamic> json) {
    return SalaryPayoutRecord(
      id: json['id'] as String? ?? '',
      staffId: json['staff_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['payment_mode'] as String? ?? 'Cash',
      payoutType: json['payout_type'] as String? ?? 'regular_salary',
      accountId: json['account_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'amount': amount,
      'payment_mode': paymentMode,
      'payout_type': payoutType,
      'account_id': accountId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@immutable
class StaffState {
  final List<StaffMember> staffList;
  final Map<String, List<SalaryPayoutRecord>> payoutsMap;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  const StaffState({
    this.staffList = const [],
    this.payoutsMap = const {},
    this.isLoading = false,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<StaffMember> get filteredStaffList {
    if (searchQuery.trim().isEmpty) return staffList;
    final query = searchQuery.trim().toLowerCase();
    return staffList.where((s) {
      final nameMatch = s.name.toLowerCase().contains(query);
      final phoneMatch = (s.phone ?? '').contains(query);
      final roleMatch = s.role.name.toLowerCase().contains(query);
      return nameMatch || phoneMatch || roleMatch;
    }).toList();
  }

  double get totalMonthlyPayroll {
    return staffList.fold(0.0, (sum, s) => sum + s.monthlySalary);
  }

  double get totalPaidPayrollThisMonth {
    return staffList.fold(0.0, (sum, s) => sum + s.totalPaidThisMonth);
  }

  StaffState copyWith({
    List<StaffMember>? staffList,
    Map<String, List<SalaryPayoutRecord>>? payoutsMap,
    bool? isLoading,
    String? searchQuery,
    String? errorMessage,
  }) {
    return StaffState(
      staffList: staffList ?? this.staffList,
      payoutsMap: payoutsMap ?? this.payoutsMap,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

final staffNotifierProvider =
    StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  final tenantId = ref.watch(authNotifierProvider).tenantId;
  final notifier = StaffNotifier(tenantId: tenantId);
  if (tenantId != null && tenantId.isNotEmpty) {
    notifier.fetchStaff();
  }
  return notifier;
});

class StaffNotifier extends StateNotifier<StaffState> {
  final String? tenantId;

  StaffNotifier({this.tenantId}) : super(const StaffState());

  /// Fetch staff list for current tenant from Supabase or local cache
  Future<void> fetchStaff() async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty) {
      state = state.copyWith(staffList: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    // 1. Offline / Local Cache Fallback
    final cached = HiveService.getCache('staff_$tId');
    if (cached != null && cached['list'] is List) {
      final rawList = cached['list'] as List;
      final cachedList = rawList
          .map((json) => StaffMember.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      state = state.copyWith(staffList: cachedList);
    }

    // 2. Fetch live data from Supabase
    if (SupabaseService.isInitialized) {
      try {
        final staffRows = await SupabaseService.client
            .from('staff_members')
            .select()
            .eq('tenant_id', tId)
            .order('created_at', ascending: true);

        final payoutsRows = await SupabaseService.client
            .from('salary_payouts')
            .select()
            .eq('tenant_id', tId)
            .order('created_at', ascending: false);

        // Group payouts by staff_id
        final Map<String, List<SalaryPayoutRecord>> payoutsMap = {};
        final Map<String, double> paidThisMonthMap = {};
        final Map<String, double> advanceThisMonthMap = {};
        final now = DateTime.now();

        for (final row in payoutsRows) {
          final record = SalaryPayoutRecord.fromJson(row);
          payoutsMap.putIfAbsent(record.staffId, () => []).add(record);

          // Check if payout is in current month
          if (record.createdAt.year == now.year && record.createdAt.month == now.month) {
            if (record.isAdvance) {
              advanceThisMonthMap[record.staffId] = (advanceThisMonthMap[record.staffId] ?? 0.0) + record.amount;
            } else {
              paidThisMonthMap[record.staffId] = (paidThisMonthMap[record.staffId] ?? 0.0) + record.amount;
            }
          }
        }

        final liveList = (staffRows as List).map((row) {
          final staff = StaffMember.fromJson(row);
          final paidThisMonth = paidThisMonthMap[staff.id] ?? 0.0;
          final advanceThisMonth = advanceThisMonthMap[staff.id] ?? 0.0;
          return staff.copyWith(
            totalPaidThisMonth: paidThisMonth,
            totalAdvanceThisMonth: advanceThisMonth,
          );
        }).toList();

        state = state.copyWith(
          staffList: liveList,
          payoutsMap: payoutsMap,
          isLoading: false,
        );

        await HiveService.setCache('staff_$tId', {
          'list': liveList.map((s) => s.toJson()).toList(),
        });
        return;
      } catch (e) {
        debugPrint('fetchStaff Supabase error: $e');
      }
    }

    state = state.copyWith(isLoading: false);
  }

  /// Add new staff member with Targeted Cache Mutation
  Future<bool> addStaff({
    required String name,
    required String phone,
    required StaffRole role,
    SalaryType salaryType = SalaryType.monthly,
    double monthlySalary = 0.0,
    String? pinCode,
  }) async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty) return false;
    final tempId = 'staff-${DateTime.now().millisecondsSinceEpoch}';

    final newStaff = StaffMember(
      id: tempId,
      name: name,
      phone: phone,
      role: role,
      salaryType: salaryType,
      monthlySalary: monthlySalary,
      pinCode: pinCode,
      totalPaidThisMonth: 0.0,
      totalAdvanceThisMonth: 0.0,
      createdAt: DateTime.now(),
    );

    // Targeted cache mutation
    final updatedList = [newStaff, ...state.staffList];
    state = state.copyWith(staffList: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.from('staff_members').insert({
          'tenant_id': tId,
          'full_name': name,
          'phone': phone,
          'role': role.name,
          'salary_type': salaryType.name,
          'monthly_salary': monthlySalary,
        }).select().single();

        final created = StaffMember.fromJson(res);
        final finalized = state.staffList
            .map((s) => s.id == tempId ? created : s)
            .toList();
        state = state.copyWith(staffList: finalized);
        await HiveService.setCache('staff_$tId', {
          'list': finalized.map((s) => s.toJson()).toList(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('addStaff error: $e');
    }

    await HiveService.setCache('staff_$tId', {
      'list': updatedList.map((s) => s.toJson()).toList(),
    });
    return true;
  }

  /// Record salary payout / advance with Optimistic Targeted Cache Mutation & RPC `record_salary_payout_v2`
  Future<bool> recordSalaryPayout({
    required String staffId,
    required double amount,
    String paymentMode = 'Cash',
    String payoutType = 'regular_salary', // 'regular_salary' or 'advance'
    String? accountId,
    String? notes,
  }) async {
    final tId = tenantId;
    if (tId == null || tId.isEmpty) return false;

    final isAdv = payoutType == 'advance';

    // 1. Optimistic local cache mutation
    final updatedList = state.staffList.map((s) {
      if (s.id == staffId) {
        if (isAdv) {
          return s.copyWith(totalAdvanceThisMonth: s.totalAdvanceThisMonth + amount);
        } else {
          return s.copyWith(totalPaidThisMonth: s.totalPaidThisMonth + amount);
        }
      }
      return s;
    }).toList();

    final newRecord = SalaryPayoutRecord(
      id: 'payout-${DateTime.now().millisecondsSinceEpoch}',
      staffId: staffId,
      amount: amount,
      paymentMode: paymentMode,
      payoutType: payoutType,
      accountId: accountId,
      notes: notes,
      createdAt: DateTime.now(),
    );

    final currentPayouts = state.payoutsMap[staffId] ?? [];
    final updatedMap = Map<String, List<SalaryPayoutRecord>>.from(state.payoutsMap);
    updatedMap[staffId] = [newRecord, ...currentPayouts];

    state = state.copyWith(staffList: updatedList, payoutsMap: updatedMap);
    await HiveService.setCache('staff_$tId', {
      'list': updatedList.map((s) => s.toJson()).toList(),
    });

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.rpc('record_salary_payout_v2', params: {
          'p_tenant_id': tId,
          'p_staff_id': staffId,
          'p_amount': amount,
          'p_account_id': accountId,
          'p_payment_mode': paymentMode.toLowerCase(),
          'p_payout_type': payoutType,
          'p_notes': notes ?? (isAdv ? 'Salary Advance' : 'Salary Payout'),
        });
      }
      return true;
    } catch (e) {
      debugPrint('recordSalaryPayout RPC error: $e');
      return true; // Keep local optimistic state for fast POS experience
    }
  }

  /// Delete staff member with Targeted Cache Mutation
  Future<void> deleteStaff(String staffId) async {
    final tId = tenantId;
    final updatedList = state.staffList.where((s) => s.id != staffId).toList();
    state = state.copyWith(staffList: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('staff_members').delete().eq('id', staffId);
      }
    } catch (e) {
      debugPrint('deleteStaff error: $e');
    }

    if (tId != null && tId.isNotEmpty) {
      await HiveService.setCache('staff_$tId', {
        'list': updatedList.map((s) => s.toJson()).toList(),
      });
    }
  }

  /// Update staff member details with targeted optimistic cache mutation
  Future<bool> updateStaff({
    required String staffId,
    required String name,
    required String phone,
    required StaffRole role,
    SalaryType salaryType = SalaryType.monthly,
    double monthlySalary = 0.0,
  }) async {
    final tId = tenantId;

    final updatedList = state.staffList.map((s) {
      if (s.id == staffId) {
        return s.copyWith(
          name: name,
          phone: phone,
          role: role,
          salaryType: salaryType,
          monthlySalary: monthlySalary,
        );
      }
      return s;
    }).toList();

    state = state.copyWith(staffList: updatedList);
    if (tId != null && tId.isNotEmpty) {
      await HiveService.setCache('staff_$tId', {
        'list': updatedList.map((s) => s.toJson()).toList(),
      });
    }

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('staff_members').update({
          'full_name': name,
          'phone': phone,
          'role': role.name,
          'salary_type': salaryType.name,
          'monthly_salary': monthlySalary,
        }).eq('id', staffId);
      }
      return true;
    } catch (e) {
      debugPrint('updateStaff error: $e');
      return true;
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

