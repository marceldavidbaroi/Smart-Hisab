import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/business_day.dart';
import '../../core/services/supabase_service.dart';

class BusinessDayState {
  final bool isLoading;
  final BusinessDay? activeDay;
  final String? errorMessage;

  const BusinessDayState({
    this.isLoading = false,
    this.activeDay,
    this.errorMessage,
  });

  bool get isDayOpen => activeDay?.status == BusinessDayStatus.open;

  BusinessDayState copyWith({
    bool? isLoading,
    BusinessDay? activeDay,
    String? errorMessage,
    bool clearActiveDay = false,
  }) {
    return BusinessDayState(
      isLoading: isLoading ?? this.isLoading,
      activeDay: clearActiveDay ? null : (activeDay ?? this.activeDay),
      errorMessage: errorMessage,
    );
  }
}

class BusinessDayNotifier extends StateNotifier<BusinessDayState> {
  final Ref _ref;

  BusinessDayNotifier(this._ref) : super(const BusinessDayState()) {
    fetchActiveDay();
  }

  String? get _tenantId => _ref.read(authNotifierProvider).tenantId;

  Future<void> fetchActiveDay() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final tenantId = _tenantId;
      if (tenantId != null && SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc(
          'get_active_business_day',
          params: {'p_tenant_id': tenantId},
        ) as Map<String, dynamic>?;

        if (res != null && res['success'] == true && res['data'] != null) {
          final dayData = res['data'] as Map<String, dynamic>;
          final dayModel = BusinessDay.fromJson(dayData);
          state = state.copyWith(
            isLoading: false,
            activeDay: dayModel.isOpen ? dayModel : null,
          );
          return;
        }
      }

      // Demo / initial state: start with a mock open day for fast testing if needed, or closed
      // If activeDay is already set, keep it, else set default demo active day
      if (state.activeDay == null) {
        state = state.copyWith(
          isLoading: false,
          activeDay: BusinessDay(
            dayId: 'demo-day-1',
            tenantId: tenantId ?? 'demo-tenant',
            date: DateTime.now(),
            status: BusinessDayStatus.open,
            openingCash: 5000.0,
            todayMeals: 32,
            todayCash: 8200.0,
            todayBaki: 6000.0,
            totalBakiOutstanding: 45000.0,
          ),
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Error fetching active business day: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> startDay(double openingCash) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final tenantId = _tenantId;
      if (tenantId != null && SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc(
          'start_business_day',
          params: {
            'p_tenant_id': tenantId,
            'p_opening_cash': openingCash,
          },
        ) as Map<String, dynamic>;

        if (res['success'] == true && res['data'] != null) {
          final data = res['data'] as Map<String, dynamic>;
          final newDay = BusinessDay.fromJson(data);
          state = state.copyWith(isLoading: false, activeDay: newDay);
          return true;
        } else {
          final msg = res['error']?['message'] as String? ?? 'Failed to start day';
          state = state.copyWith(isLoading: false, errorMessage: msg);
          return false;
        }
      }

      // Offline / demo state
      final newDay = BusinessDay(
        dayId: 'day-${DateTime.now().millisecondsSinceEpoch}',
        tenantId: tenantId ?? 'demo-tenant',
        date: DateTime.now(),
        status: BusinessDayStatus.open,
        openingCash: openingCash,
        todayMeals: 0,
        todayCash: openingCash,
        todayBaki: 0.0,
        totalBakiOutstanding: 45000.0,
      );
      state = state.copyWith(isLoading: false, activeDay: newDay);
      return true;
    } catch (e) {
      debugPrint('Error starting business day: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> endDay(double closingCash, String notes) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final tenantId = _tenantId;
      final currentDay = state.activeDay;

      if (tenantId != null && currentDay != null && SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc(
          'end_business_day',
          params: {
            'p_tenant_id': tenantId,
            'p_day_id': currentDay.dayId,
            'p_closing_cash': closingCash,
            'p_notes': notes,
          },
        ) as Map<String, dynamic>;

        if (res['success'] == true) {
          state = state.copyWith(
            isLoading: false,
            clearActiveDay: true,
          );
          return true;
        } else {
          final msg = res['error']?['message'] as String? ?? 'Failed to close day';
          state = state.copyWith(isLoading: false, errorMessage: msg);
          return false;
        }
      }

      // Offline / demo close
      state = state.copyWith(
        isLoading: false,
        clearActiveDay: true,
      );
      return true;
    } catch (e) {
      debugPrint('Error ending business day: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final businessDayNotifierProvider =
    StateNotifierProvider<BusinessDayNotifier, BusinessDayState>((ref) {
  return BusinessDayNotifier(ref);
});
