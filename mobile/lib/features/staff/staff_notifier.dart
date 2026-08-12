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
  final String? notes;
  final DateTime createdAt;

  const SalaryPayoutRecord({
    required this.id,
    required this.staffId,
    required this.amount,
    this.paymentMode = 'Cash',
    this.notes,
    required this.createdAt,
  });

  factory SalaryPayoutRecord.fromJson(Map<String, dynamic> json) {
    return SalaryPayoutRecord(
      id: json['id'] as String? ?? '',
      staffId: json['staff_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['payment_mode'] as String? ?? 'Cash',
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

  /// Fetch staff list for current tenant with local Hive fallback
  Future<void> fetchStaff() async {
    final tId = tenantId ?? 'tenant-demo';
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .from('staff_members')
            .select('*')
            .eq('tenant_id', tId)
            .order('name', ascending: true) as List<dynamic>;

        final fetched = res
            .map((json) => StaffMember.fromJson(json as Map<String, dynamic>))
            .toList();

        await HiveService.setCache('staff_$tId', {
          'list': fetched.map((s) => s.toJson()).toList(),
        });

        state = state.copyWith(staffList: fetched, isLoading: false);
        return;
      }
    } catch (e) {
      debugPrint('StaffNotifier fetch error: $e');
    }

    // Offline / Demo Fallback
    final cached = HiveService.getCache('staff_$tId');
    if (cached != null && cached['list'] is List) {
      final rawList = cached['list'] as List;
      final cachedList = rawList
          .map((json) => StaffMember.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      if (cachedList.isNotEmpty) {
        state = state.copyWith(staffList: cachedList, isLoading: false);
        return;
      }
    }

    // Demo Seed
    final demoStaff = [
      const StaffMember(
        id: 'staff-1',
        name: 'Abul Bashar',
        role: StaffRole.staff,
        phone: '01712345678',
        monthlySalary: 15000.0,
        totalPaidThisMonth: 5000.0,
      ),
      const StaffMember(
        id: 'staff-2',
        name: 'Jamil Hossain',
        role: StaffRole.manager,
        phone: '01898765432',
        monthlySalary: 12000.0,
        totalPaidThisMonth: 12000.0,
      ),
      const StaffMember(
        id: 'staff-3',
        name: 'Solaiman Khan',
        role: StaffRole.staff,
        phone: '01911223344',
        monthlySalary: 10000.0,
        totalPaidThisMonth: 0.0,
      ),
    ];

    state = state.copyWith(staffList: demoStaff, isLoading: false);
  }

  /// Add new staff member with Targeted Cache Mutation
  Future<bool> addStaff({
    required String name,
    required String phone,
    required StaffRole role,
    double monthlySalary = 0.0,
    String? pinCode,
  }) async {
    final tId = tenantId ?? 'tenant-demo';
    final tempId = 'staff-${DateTime.now().millisecondsSinceEpoch}';

    final newStaff = StaffMember(
      id: tempId,
      name: name,
      phone: phone,
      role: role,
      monthlySalary: monthlySalary,
      pinCode: pinCode,
      totalPaidThisMonth: 0.0,
      createdAt: DateTime.now(),
    );

    // Targeted cache mutation
    final updatedList = [newStaff, ...state.staffList];
    state = state.copyWith(staffList: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.from('staff_members').insert({
          'tenant_id': tId,
          'name': name,
          'phone': phone,
          'role': role.name,
          'monthly_salary': monthlySalary,
          'pin_code': pinCode,
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

  /// Record salary payout with Optimistic Targeted Cache Mutation
  Future<bool> recordSalaryPayout({
    required String staffId,
    required double amount,
    String paymentMode = 'Cash',
    String? notes,
  }) async {
    final tId = tenantId ?? 'tenant-demo';

    // 1. Optimistic local cache mutation
    final updatedList = state.staffList.map((s) {
      if (s.id == staffId) {
        return s.copyWith(totalPaidThisMonth: s.totalPaidThisMonth + amount);
      }
      return s;
    }).toList();

    final newRecord = SalaryPayoutRecord(
      id: 'payout-${DateTime.now().millisecondsSinceEpoch}',
      staffId: staffId,
      amount: amount,
      paymentMode: paymentMode,
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
        await SupabaseService.client.rpc('record_salary_payout', params: {
          'p_tenant_id': tId,
          'p_staff_id': staffId,
          'p_amount': amount,
          'p_payment_mode': paymentMode,
          'p_notes': notes ?? 'Salary payout',
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
    final tId = tenantId ?? 'tenant-demo';
    final updatedList = state.staffList.where((s) => s.id != staffId).toList();
    state = state.copyWith(staffList: updatedList);

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('staff_members').delete().eq('id', staffId);
      }
    } catch (e) {
      debugPrint('deleteStaff error: $e');
    }

    await HiveService.setCache('staff_$tId', {
      'list': updatedList.map((s) => s.toJson()).toList(),
    });
  }

  /// Update staff member details with targeted optimistic cache mutation
  Future<bool> updateStaff({
    required String staffId,
    required String name,
    required String phone,
    required StaffRole role,
    double monthlySalary = 0.0,
  }) async {
    final tId = tenantId ?? 'tenant-demo';

    final updatedList = state.staffList.map((s) {
      if (s.id == staffId) {
        return s.copyWith(
          name: name,
          phone: phone,
          role: role,
          monthlySalary: monthlySalary,
        );
      }
      return s;
    }).toList();

    state = state.copyWith(staffList: updatedList);
    await HiveService.setCache('staff_$tId', {
      'list': updatedList.map((s) => s.toJson()).toList(),
    });

    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.from('staff_members').update({
          'name': name,
          'phone': phone,
          'role': role.name,
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

