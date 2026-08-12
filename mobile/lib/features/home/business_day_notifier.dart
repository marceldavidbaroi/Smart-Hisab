import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/business_day.dart';

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

    // Completely local state management without API network calls
    final tenantId = _tenantId;
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
  }

  Future<bool> startDay(double openingCash) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final tenantId = _tenantId;
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
  }

  Future<bool> endDay(double closingCash, String notes) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    state = state.copyWith(
      isLoading: false,
      clearActiveDay: true,
    );
    return true;
  }
}

final businessDayNotifierProvider =
    StateNotifierProvider<BusinessDayNotifier, BusinessDayState>((ref) {
  return BusinessDayNotifier(ref);
});
