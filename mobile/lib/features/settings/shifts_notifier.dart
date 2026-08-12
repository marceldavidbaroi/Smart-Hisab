import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

class CanteenShift {
  final String id;
  final String tenantId;
  final String name;
  final String startTime;
  final String endTime;
  final double defaultPrice;

  const CanteenShift({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.defaultPrice,
  });

  factory CanteenShift.fromJson(Map<String, dynamic> json) {
    return CanteenShift(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '08:00',
      endTime: json['end_time'] as String? ?? '10:00',
      defaultPrice: (json['default_price'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'default_price': defaultPrice,
    };
  }

  CanteenShift copyWith({
    String? startTime,
    String? endTime,
    double? defaultPrice,
  }) {
    return CanteenShift(
      id: id,
      tenantId: tenantId,
      name: name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      defaultPrice: defaultPrice ?? this.defaultPrice,
    );
  }
}

class ShiftsState {
  final bool isLoading;
  final List<CanteenShift> shifts;
  final String? errorMessage;

  const ShiftsState({
    this.isLoading = false,
    this.shifts = const [],
    this.errorMessage,
  });

  ShiftsState copyWith({
    bool? isLoading,
    List<CanteenShift>? shifts,
    String? errorMessage,
  }) {
    return ShiftsState(
      isLoading: isLoading ?? this.isLoading,
      shifts: shifts ?? this.shifts,
      errorMessage: errorMessage,
    );
  }
}

final shiftsNotifierProvider =
    StateNotifierProvider<ShiftsNotifier, ShiftsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return ShiftsNotifier(tenantId: authState.tenantId);
});

class ShiftsNotifier extends StateNotifier<ShiftsState> {
  final String? tenantId;

  ShiftsNotifier({required this.tenantId}) : super(const ShiftsState()) {
    fetchShifts();
  }

  Future<void> fetchShifts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .from('shifts')
            .select('*')
            .eq('tenant_id', tenantId!)
            .order('name', ascending: true) as List<dynamic>;

        final loaded = res
            .map((e) => CanteenShift.fromJson(e as Map<String, dynamic>))
            .toList();

        await HiveService.cacheBox.put(
            'shifts_$tenantId', loaded.map((e) => e.toJson()).toList());

        state = state.copyWith(isLoading: false, shifts: loaded);
        return;
      }
    } catch (e) {
      debugPrint('Shifts fetch error: $e');
    }

    // Hive offline fallback / Default demo seed
    final cached = HiveService.getCache('shifts_$tenantId') as List<dynamic>?;
    if (cached != null && cached.isNotEmpty) {
      final loaded = cached
          .map((e) => CanteenShift.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = state.copyWith(isLoading: false, shifts: loaded);
      return;
    }

    final defaultShifts = [
      CanteenShift(
        id: 'shift-001',
        tenantId: tenantId ?? 'demo-tenant',
        name: 'Breakfast',
        startTime: '07:30 AM',
        endTime: '10:00 AM',
        defaultPrice: 40.0,
      ),
      CanteenShift(
        id: 'shift-002',
        tenantId: tenantId ?? 'demo-tenant',
        name: 'Lunch',
        startTime: '01:00 PM',
        endTime: '03:30 PM',
        defaultPrice: 80.0,
      ),
      CanteenShift(
        id: 'shift-003',
        tenantId: tenantId ?? 'demo-tenant',
        name: 'Dinner',
        startTime: '08:00 PM',
        endTime: '10:30 PM',
        defaultPrice: 70.0,
      ),
    ];

    state = state.copyWith(isLoading: false, shifts: defaultShifts);
  }

  /// Optimistically update shift timings or meal pricing
  Future<bool> updateShift({
    required String shiftId,
    required String startTime,
    required String endTime,
    required double defaultPrice,
  }) async {
    final index = state.shifts.indexWhere((s) => s.id == shiftId);
    if (index == -1) return false;

    final updatedShift = state.shifts[index].copyWith(
      startTime: startTime,
      endTime: endTime,
      defaultPrice: defaultPrice,
    );

    final updatedList = List<CanteenShift>.from(state.shifts);
    updatedList[index] = updatedShift;
    state = state.copyWith(shifts: updatedList);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client
            .from('shifts')
            .update(updatedShift.toJson())
            .eq('id', shiftId);
      }
      return true;
    } catch (e) {
      debugPrint('updateShift error: $e');
      return true;
    }
  }
}
