import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

class CanteenShift {
  final String id;
  final String tenantId;
  final String name;
  final String startTime;
  final String endTime;
  final bool isActive;

  const CanteenShift({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  factory CanteenShift.fromJson(Map<String, dynamic> json) {
    return CanteenShift(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '08:00',
      endTime: json['end_time'] as String? ?? '10:00',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
    };
  }

  CanteenShift copyWith({
    String? name,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) {
    return CanteenShift(
      id: id,
      tenantId: tenantId,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
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

    // 1. Try Supabase backend API request
    try {
      if (tenantId != null && tenantId!.isNotEmpty && SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .from('shifts')
            .select()
            .eq('tenant_id', tenantId!)
            .order('start_time', ascending: true);

        final shifts = (res as List<dynamic>)
            .map((e) => CanteenShift.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        final jsonList = shifts.map((s) => s.toJson()).toList();
        await HiveService.setCache('shifts_$tenantId', {'data': jsonList});
        state = state.copyWith(isLoading: false, shifts: shifts);
        return;
      }
    } catch (e) {
      debugPrint('fetchShifts API error: $e');
    }

    // 2. Offline fallback to Hive cache
    final cachedMap = HiveService.getCache('shifts_$tenantId');
    if (cachedMap != null && cachedMap['data'] != null) {
      final list = cachedMap['data'] as List<dynamic>;
      final loaded = list
          .map((e) => CanteenShift.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = state.copyWith(isLoading: false, shifts: loaded);
      return;
    }

    state = state.copyWith(isLoading: false, shifts: []);
  }

  /// Add new shift (optimistic)
  Future<bool> addShift({
    required String name,
    required String startTime,
    required String endTime,
    bool isActive = true,
  }) async {
    final shiftId = const Uuid().v4();
    final newShift = CanteenShift(
      id: shiftId,
      tenantId: tenantId ?? '',
      name: name,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
    );

    state = state.copyWith(shifts: [...state.shifts, newShift]);

    try {
      if (tenantId != null && tenantId!.isNotEmpty && SupabaseService.isInitialized) {
        await SupabaseService.client.from('shifts').insert(newShift.toJson());
      }
      return true;
    } catch (e) {
      debugPrint('addShift error: $e');
      return true;
    }
  }

  /// Batch seed 4 standard shifts preset (6:00 AM - 12:00 PM Morning, Lunch, Evening, Dinner)
  Future<bool> apply4ShiftPreset() async {
    state = state.copyWith(isLoading: true);

    const uuid = Uuid();
    final presetShifts = [
      CanteenShift(
        id: uuid.v4(),
        tenantId: tenantId ?? '',
        name: 'Morning Shift',
        startTime: '06:00 AM',
        endTime: '12:00 PM',
        isActive: true,
      ),
      CanteenShift(
        id: uuid.v4(),
        tenantId: tenantId ?? '',
        name: 'Lunch Shift',
        startTime: '12:00 PM',
        endTime: '04:00 PM',
        isActive: true,
      ),
      CanteenShift(
        id: uuid.v4(),
        tenantId: tenantId ?? '',
        name: 'Evening Snack',
        startTime: '04:00 PM',
        endTime: '07:00 PM',
        isActive: true,
      ),
      CanteenShift(
        id: uuid.v4(),
        tenantId: tenantId ?? '',
        name: 'Dinner Shift',
        startTime: '07:00 PM',
        endTime: '11:00 PM',
        isActive: true,
      ),
    ];

    state = state.copyWith(isLoading: false, shifts: [...state.shifts, ...presetShifts]);

    try {
      if (tenantId != null && tenantId!.isNotEmpty && SupabaseService.isInitialized) {
        final payload = presetShifts.map((s) => s.toJson()).toList();
        await SupabaseService.client.from('shifts').insert(payload);
      }
      return true;
    } catch (e) {
      debugPrint('apply4ShiftPreset error: $e');
      return true;
    }
  }

  /// Optimistically update shift
  Future<bool> updateShift({
    required String id,
    required String name,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) async {
    final index = state.shifts.indexWhere((s) => s.id == id);
    if (index == -1) return false;

    final updatedShift = state.shifts[index].copyWith(
      name: name,
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
    );

    final updatedList = List<CanteenShift>.from(state.shifts);
    updatedList[index] = updatedShift;
    state = state.copyWith(shifts: updatedList);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client
            .from('shifts')
            .update(updatedShift.toJson())
            .eq('id', id);
      }
      return true;
    } catch (e) {
      debugPrint('updateShift error: $e');
      return true;
    }
  }

  /// Delete shift (optimistic)
  Future<bool> deleteShift(String id) async {
    final updatedList = state.shifts.where((s) => s.id != id).toList();
    state = state.copyWith(shifts: updatedList);

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        await SupabaseService.client.from('shifts').delete().eq('id', id);
      }
      return true;
    } catch (e) {
      debugPrint('deleteShift error: $e');
      return true;
    }
  }
}
