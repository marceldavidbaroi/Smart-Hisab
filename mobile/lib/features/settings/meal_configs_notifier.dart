import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

class MealConfig {
  final String id;
  final String tenantId;
  final String? shiftId;
  final String? shiftName;
  final double rate;
  final DateTime effectiveFrom;
  final String? note;

  const MealConfig({
    required this.id,
    required this.tenantId,
    this.shiftId,
    this.shiftName,
    required this.rate,
    required this.effectiveFrom,
    this.note,
  });

  factory MealConfig.fromJson(Map<String, dynamic> json) {
    return MealConfig(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String? ?? '',
      shiftId: json['shift_id'] as String?,
      shiftName: json['shifts']?['name'] as String? ?? json['shift_name'] as String?,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.tryParse(json['effective_from'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'shift_id': ?shiftId,
      'rate': rate,
      'effective_from': effectiveFrom.toIso8601String().split('T').first,
      'note': note,
    };
  }

  MealConfig copyWith({
    String? shiftId,
    String? shiftName,
    double? rate,
    DateTime? effectiveFrom,
    String? note,
  }) {
    return MealConfig(
      id: id,
      tenantId: tenantId,
      shiftId: shiftId ?? this.shiftId,
      shiftName: shiftName ?? this.shiftName,
      rate: rate ?? this.rate,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      note: note ?? this.note,
    );
  }
}

class MealConfigsState {
  final bool isLoading;
  final List<MealConfig> mealConfigs;
  final String? errorMessage;

  const MealConfigsState({
    this.isLoading = false,
    this.mealConfigs = const [],
    this.errorMessage,
  });

  MealConfigsState copyWith({
    bool? isLoading,
    List<MealConfig>? mealConfigs,
    String? errorMessage,
  }) {
    return MealConfigsState(
      isLoading: isLoading ?? this.isLoading,
      mealConfigs: mealConfigs ?? this.mealConfigs,
      errorMessage: errorMessage,
    );
  }
}

final mealConfigsNotifierProvider =
    StateNotifierProvider<MealConfigsNotifier, MealConfigsState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return MealConfigsNotifier(tenantId: authState.tenantId);
});

class MealConfigsNotifier extends StateNotifier<MealConfigsState> {
  final String? tenantId;

  MealConfigsNotifier({required this.tenantId}) : super(const MealConfigsState());

  Future<void> fetchMealConfigs() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // 1. Try Supabase backend API fetch
    try {
      if (tenantId != null && tenantId!.isNotEmpty && SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .from('meal_configs')
            .select('*, shifts(name)')
            .eq('tenant_id', tenantId!)
            .order('effective_from', ascending: false);

        final mealConfigs = (res as List<dynamic>)
            .map((e) => MealConfig.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        await _updateCache(mealConfigs);
        state = state.copyWith(isLoading: false, mealConfigs: mealConfigs);
        return;
      }
    } catch (e) {
      debugPrint('fetchMealConfigs API error: $e');
    }

    // 2. Offline fallback to Hive cache
    final cachedMap = HiveService.getCache('meal_configs_$tenantId');
    if (cachedMap != null && cachedMap['data'] != null) {
      final list = cachedMap['data'] as List<dynamic>;
      final loaded = list
          .map((e) => MealConfig.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = state.copyWith(isLoading: false, mealConfigs: loaded);
      return;
    }

    state = state.copyWith(isLoading: false, mealConfigs: []);
  }

  /// Add new meal config (optimistic update)
  Future<bool> addMealConfig({
    required double rate,
    required DateTime effectiveFrom,
    String? note,
    String? shiftId,
    String? shiftName,
  }) async {
    final tempId = const Uuid().v4();
    final newConfig = MealConfig(
      id: tempId,
      tenantId: tenantId ?? '',
      shiftId: shiftId,
      shiftName: shiftName,
      rate: rate,
      effectiveFrom: effectiveFrom,
      note: note,
    );

    final updatedList = [newConfig, ...state.mealConfigs];
    state = state.copyWith(mealConfigs: updatedList);

    try {
      if (tenantId != null && tenantId!.isNotEmpty && SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .from('meal_configs')
            .insert(newConfig.toJson())
            .select('*, shifts(name)')
            .single();

        final createdConfig = MealConfig.fromJson(Map<String, dynamic>.from(res as Map));
        final finalList = state.mealConfigs.map((c) => c.id == tempId ? createdConfig : c).toList();
        state = state.copyWith(mealConfigs: finalList);
        await _updateCache(finalList);
      } else {
        await _updateCache(updatedList);
      }
      return true;
    } catch (e) {
      debugPrint('addMealConfig error: $e');
      return true;
    }
  }

  /// Optimistically update meal config
  Future<bool> updateMealConfig({
    required String id,
    required double rate,
    required DateTime effectiveFrom,
    String? note,
    String? shiftId,
    String? shiftName,
  }) async {
    final index = state.mealConfigs.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    final updatedConfig = state.mealConfigs[index].copyWith(
      rate: rate,
      effectiveFrom: effectiveFrom,
      note: note,
      shiftId: shiftId,
      shiftName: shiftName,
    );

    final updatedList = List<MealConfig>.from(state.mealConfigs);
    updatedList[index] = updatedConfig;
    state = state.copyWith(mealConfigs: updatedList);

    try {
      if (tenantId != null && tenantId!.isNotEmpty && SupabaseService.isInitialized) {
        final payload = {
          'rate': rate,
          'effective_from': effectiveFrom.toIso8601String().split('T').first,
          'note': note,
          'shift_id': ?shiftId,
        };

        await SupabaseService.client
            .from('meal_configs')
            .update(payload)
            .eq('id', id);

        await _updateCache(updatedList);
      } else {
        await _updateCache(updatedList);
      }
      return true;
    } catch (e) {
      debugPrint('updateMealConfig error: $e');
      return true;
    }
  }

  /// Delete meal config (optimistic update)
  Future<bool> deleteMealConfig(String id) async {
    final updatedList = state.mealConfigs.where((c) => c.id != id).toList();
    state = state.copyWith(mealConfigs: updatedList);

    try {
      if (tenantId != null && tenantId!.isNotEmpty && SupabaseService.isInitialized) {
        await SupabaseService.client.from('meal_configs').delete().eq('id', id);
        await _updateCache(updatedList);
      } else {
        await _updateCache(updatedList);
      }
      return true;
    } catch (e) {
      debugPrint('deleteMealConfig error: $e');
      return true;
    }
  }

  Future<void> _updateCache(List<MealConfig> configs) async {
    if (tenantId == null || tenantId!.isEmpty) return;
    final jsonList = configs.map((c) => c.toJson()).toList();
    await HiveService.setCache('meal_configs_$tenantId', {'data': jsonList});
  }
}

