import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/models/business_day.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/supabase_service.dart';

import '../../core/models/cashbook_entry.dart';

class BusinessDayState {
  final bool isLoading;
  final BusinessDay? activeDay;
  final LastClosedDayRecap? lastClosedDayRecap;
  final List<CashbookEntry> recentActivities;
  final String? errorMessage;

  const BusinessDayState({
    this.isLoading = false,
    this.activeDay,
    this.lastClosedDayRecap,
    this.recentActivities = const [],
    this.errorMessage,
  });

  bool get isDayOpen => activeDay?.status == BusinessDayStatus.open;

  BusinessDayState copyWith({
    bool? isLoading,
    BusinessDay? activeDay,
    LastClosedDayRecap? lastClosedDayRecap,
    List<CashbookEntry>? recentActivities,
    String? errorMessage,
    bool clearActiveDay = false,
  }) {
    return BusinessDayState(
      isLoading: isLoading ?? this.isLoading,
      activeDay: clearActiveDay ? null : (activeDay ?? this.activeDay),
      lastClosedDayRecap: lastClosedDayRecap ?? this.lastClosedDayRecap,
      recentActivities: recentActivities ?? this.recentActivities,
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
    final tenantId = _tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    if (SupabaseService.isInitialized) {
      try {
        final client = SupabaseService.client;

        // 1. Fetch active open business day
        final response = await client
            .from('business_days')
            .select()
            .eq('tenant_id', tenantId)
            .eq('status', 'open')
            .maybeSingle();

        // 2. Fetch last closed business day for Yesterday's Recap
        LastClosedDayRecap? recap;
        final closedRes = await client
            .from('business_days')
            .select()
            .eq('tenant_id', tenantId)
            .eq('status', 'closed')
            .order('closed_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (closedRes != null) {
          final cId = closedRes['id'] as String;
          final cMealsRes = await client
              .from('meal_attendance')
              .select('id')
              .eq('tenant_id', tenantId)
              .eq('business_day_id', cId);
          final cMealCount = (cMealsRes as List).length;

          final cEntriesRes = await client
              .from('day_entries')
              .select('amount, entry_type')
              .eq('tenant_id', tenantId)
              .eq('business_day_id', cId);

          double cInflow = 0.0;
          for (final e in (cEntriesRes as List)) {
            if (e['entry_type'] == 'inflow') {
              cInflow += (e['amount'] as num?)?.toDouble() ?? 0.0;
            }
          }

          recap = LastClosedDayRecap(
            closedAt: closedRes['closed_at'] != null
                ? DateTime.tryParse(closedRes['closed_at'].toString()) ?? DateTime.now()
                : DateTime.now(),
            openingCash: (closedRes['opening_cash'] as num?)?.toDouble() ?? 0.0,
            closingCash: (closedRes['closing_cash'] as num?)?.toDouble() ?? 0.0,
            expectedCash: (closedRes['expected_cash'] as num?)?.toDouble() ?? 0.0,
            variance: (closedRes['variance'] as num?)?.toDouble() ?? 0.0,
            totalMeals: cMealCount,
            totalInflows: cInflow,
            notes: closedRes['notes'] as String?,
          );
        }

        // 3. Fetch latest 5 activity entries
        final activitiesRes = await client
            .from('day_entries')
            .select('*')
            .eq('tenant_id', tenantId)
            .order('created_at', ascending: false)
            .limit(5);

        final recentList = (activitiesRes as List)
            .map((e) => CashbookEntry.fromJson(e))
            .toList();

        // 4. Fetch total outstanding baki
        final wallets = await client
            .from('customer_wallets')
            .select('balance')
            .eq('tenant_id', tenantId);

        double totalBaki = 0.0;
        for (final w in (wallets as List)) {
          final bal = (w['balance'] as num?)?.toDouble() ?? 0.0;
          if (bal < 0) {
            totalBaki += bal.abs();
          }
        }

        if (response != null) {
          final dayId = response['id'] as String;
          final openingCash = (response['opening_cash'] as num?)?.toDouble() ?? 0.0;
          final businessDate = response['business_date'] != null
              ? DateTime.tryParse(response['business_date'].toString()) ?? DateTime.now()
              : DateTime.now();

          final mealsRes = await client
              .from('meal_attendance')
              .select('id')
              .eq('tenant_id', tenantId)
              .eq('business_day_id', dayId);
          final mealCount = (mealsRes as List).length;

          final dayEntries = await client
              .from('day_entries')
              .select('amount, entry_type')
              .eq('tenant_id', tenantId)
              .eq('business_day_id', dayId);

          double todayInflows = 0.0;
          double todayOutflows = 0.0;
          for (final entry in (dayEntries as List)) {
            final amt = (entry['amount'] as num?)?.toDouble() ?? 0.0;
            if (entry['entry_type'] == 'inflow') {
              todayInflows += amt;
            } else if (entry['entry_type'] == 'outflow') {
              todayOutflows += amt;
            }
          }

          final day = BusinessDay(
            dayId: dayId,
            tenantId: tenantId,
            date: businessDate,
            status: BusinessDayStatus.open,
            openingCash: openingCash,
            totalInflows: todayInflows,
            totalOutflows: todayOutflows,
            expectedCash: openingCash + todayInflows - todayOutflows,
            todayMeals: mealCount,
            todayCash: todayInflows,
            todayBaki: 0.0,
            totalBakiOutstanding: totalBaki,
          );

          await HiveService.setCache('active_day_$tenantId', day.toJson());
          state = state.copyWith(
            isLoading: false,
            activeDay: day,
            lastClosedDayRecap: recap,
            recentActivities: recentList,
          );
          return;
        } else {
          await HiveService.deleteCache('active_day_$tenantId');
          state = state.copyWith(
            isLoading: false,
            clearActiveDay: true,
            lastClosedDayRecap: recap,
            recentActivities: recentList,
          );
          return;
        }
      } catch (e) {
        final cached = HiveService.getCache('active_day_$tenantId');
        if (cached != null) {
          final cachedDay = BusinessDay.fromJson(Map<String, dynamic>.from(cached));
          state = state.copyWith(isLoading: false, activeDay: cachedDay);
          return;
        }
      }
    }

    state = state.copyWith(isLoading: false);
  }

  void recordOutflowOptimistic(double amount) {
    final active = state.activeDay;
    if (active == null) return;

    final updatedDay = active.copyWith(
      totalOutflows: active.totalOutflows + amount,
      expectedCash: active.openingCash + active.totalInflows - (active.totalOutflows + amount),
    );

    final tenantId = _tenantId;
    if (tenantId != null && tenantId.isNotEmpty) {
      HiveService.setCache('active_day_$tenantId', updatedDay.toJson());
    }

    state = state.copyWith(activeDay: updatedDay);
  }

  void recordInflowOptimistic(double amount) {
    final active = state.activeDay;
    if (active == null) return;

    final updatedDay = active.copyWith(
      totalInflows: active.totalInflows + amount,
      expectedCash: active.openingCash + (active.totalInflows + amount) - active.totalOutflows,
    );

    final tenantId = _tenantId;
    if (tenantId != null && tenantId.isNotEmpty) {
      HiveService.setCache('active_day_$tenantId', updatedDay.toJson());
    }

    state = state.copyWith(activeDay: updatedDay);
  }

  Future<bool> startDay(double openingCash) async {
    final tenantId = _tenantId;
    if (tenantId == null || tenantId.isEmpty) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    if (SupabaseService.isInitialized) {
      try {
        final client = SupabaseService.client;
        final res = await client.rpc('start_business_day', params: {
          'p_tenant_id': tenantId,
          'p_opening_cash': openingCash,
        });

        final dayId = res?.toString() ?? 'day-${DateTime.now().millisecondsSinceEpoch}';
        final newDay = BusinessDay(
          dayId: dayId,
          tenantId: tenantId,
          date: DateTime.now(),
          status: BusinessDayStatus.open,
          openingCash: openingCash,
          todayMeals: 0,
          todayCash: 0.0,
          todayBaki: 0.0,
          totalBakiOutstanding: 0.0,
        );

        await HiveService.setCache('active_day_$tenantId', newDay.toJson());
        state = state.copyWith(isLoading: false, activeDay: newDay);
        return true;
      } catch (e) {
        state = state.copyWith(isLoading: false, errorMessage: e.toString());
        return false;
      }
    }

    // Offline / Demo fallback
    final newDay = BusinessDay(
      dayId: 'day-${DateTime.now().millisecondsSinceEpoch}',
      tenantId: tenantId,
      date: DateTime.now(),
      status: BusinessDayStatus.open,
      openingCash: openingCash,
      todayMeals: 0,
      todayCash: 0.0,
      todayBaki: 0.0,
      totalBakiOutstanding: 0.0,
    );
    await HiveService.setCache('active_day_$tenantId', newDay.toJson());
    state = state.copyWith(isLoading: false, activeDay: newDay);
    return true;
  }

  Future<bool> endDay(double closingCash, String notes) async {
    final tenantId = _tenantId;
    final dayId = state.activeDay?.dayId;
    if (tenantId == null || tenantId.isEmpty) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    // Validate UUID format before calling RPC
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    final isValidTenant = uuidRegex.hasMatch(tenantId);
    final isValidDay = dayId != null && uuidRegex.hasMatch(dayId);

    if (SupabaseService.isInitialized && isValidTenant) {
      try {
        final client = SupabaseService.client;

        // If dayId is valid UUID, call end_business_day RPC
        if (isValidDay) {
          await client.rpc('end_business_day', params: {
            'p_tenant_id': tenantId,
            'p_day_id': dayId,
            'p_closing_cash': closingCash,
            'p_notes': notes.isEmpty ? null : notes,
          });
        } else {
          // Direct table update fallback for open business day
          await client
              .from('business_days')
              .update({
                'status': 'closed',
                'closing_cash': closingCash,
                'closed_at': DateTime.now().toIso8601String(),
                'notes': notes.isEmpty ? null : notes,
              })
              .eq('tenant_id', tenantId)
              .eq('status', 'open');
        }

        await HiveService.deleteCache('active_day_$tenantId');
        state = state.copyWith(isLoading: false, clearActiveDay: true);
        return true;
      } catch (e) {
        debugPrint('end_business_day error: $e');
        // If server call fails, fallback to local close so user is never blocked
        await HiveService.deleteCache('active_day_$tenantId');
        state = state.copyWith(isLoading: false, clearActiveDay: true);
        return true;
      }
    }

    // Offline / Demo fallback
    await HiveService.deleteCache('active_day_$tenantId');
    state = state.copyWith(isLoading: false, clearActiveDay: true);
    return true;
  }
}

final businessDayNotifierProvider =
    StateNotifierProvider<BusinessDayNotifier, BusinessDayState>((ref) {
  return BusinessDayNotifier(ref);
});
