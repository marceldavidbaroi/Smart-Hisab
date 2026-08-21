import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../customers/customers_notifier.dart';
import '../settings/meal_configs_notifier.dart';
import '../staff/staff_notifier.dart';
import 'business_day_notifier.dart';

@immutable
class OnboardingStep {
  final int stepNumber;
  final String titleBangla;
  final String titleEnglish;
  final String descriptionBangla;
  final String descriptionEnglish;
  final bool isCompleted;

  const OnboardingStep({
    required this.stepNumber,
    required this.titleBangla,
    required this.titleEnglish,
    required this.descriptionBangla,
    required this.descriptionEnglish,
    required this.isCompleted,
  });

  String getTitle(bool isBangla) => isBangla ? titleBangla : titleEnglish;
  String getDescription(bool isBangla) => isBangla ? descriptionBangla : descriptionEnglish;
}

@immutable
class OnboardingState {
  final List<OnboardingStep> steps;
  final bool isDismissed;

  const OnboardingState({
    required this.steps,
    this.isDismissed = false,
  });

  int get completedCount => steps.where((s) => s.isCompleted).length;
  int get totalCount => steps.length;
  double get progress => totalCount == 0 ? 0 : completedCount / totalCount;
  bool get isAllCompleted => totalCount > 0 && completedCount == totalCount;
  bool get shouldShow => !isDismissed && !isAllCompleted;

  OnboardingState copyWith({
    List<OnboardingStep>? steps,
    bool? isDismissed,
  }) {
    return OnboardingState(
      steps: steps ?? this.steps,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

class OnboardingProgressNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;
  static const String _dismissedCacheKey = 'onboarding_checklist_dismissed';

  OnboardingProgressNotifier(this._ref)
      : super(const OnboardingState(steps: [])) {
    _loadDismissedState();
    _recalculate();
  }

  void _loadDismissedState() {
    final cached = HiveService.getCache(_dismissedCacheKey);
    if (cached != null && cached['dismissed'] == true) {
      state = state.copyWith(isDismissed: true);
    }
  }

  void toggleDismissed() {
    final next = !state.isDismissed;
    state = state.copyWith(isDismissed: next);
    HiveService.setCache(_dismissedCacheKey, {'dismissed': next});
  }

  void recalculate() => _recalculate();

  void _recalculate() {
    // 1. Meal Rates
    final mealConfigs = _ref.read(mealConfigsNotifierProvider).mealConfigs;
    final hasMealRates = mealConfigs.isNotEmpty;

    // 2. Customers
    final customers = _ref.read(customersNotifierProvider).customers;
    final hasCustomers = customers.isNotEmpty;

    // 3. Staff
    final staff = _ref.read(staffNotifierProvider).staffList;
    final hasStaff = staff.isNotEmpty;

    // 4. Open Day
    final businessDayState = _ref.read(businessDayNotifierProvider);
    final hasOpenedDay = businessDayState.isDayOpen || businessDayState.lastClosedDayRecap != null;

    final steps = [
      OnboardingStep(
        stepNumber: 1,
        titleBangla: 'মিলের রেট ও দর নির্ধারণ',
        titleEnglish: 'Configure Meal Rates',
        descriptionBangla: 'প্রতি মিলের স্ট্যান্ডার্ড রেট (৳) সেট করুন',
        descriptionEnglish: 'Set standard per-meal pricing & rates (৳)',
        isCompleted: hasMealRates,
      ),
      OnboardingStep(
        stepNumber: 2,
        titleBangla: 'খাতা থেকে কাস্টমার ও বাকি যোগ',
        titleEnglish: 'Add Customers & Opening Baki',
        descriptionBangla: 'পুরোনো খাতার ব্যালেন্স সহ কাস্টমার তুলুন',
        descriptionEnglish: 'Migrate paper khata names & opening balances',
        isCompleted: hasCustomers,
      ),
      OnboardingStep(
        stepNumber: 3,
        titleBangla: 'কর্মচারীদের তালিকা যোগ করুন',
        titleEnglish: 'Staff & Cashier Roster',
        descriptionBangla: 'বাবুর্চি, সহকারী ও ক্যাশিয়ারের তথ্য রাখুন',
        descriptionEnglish: 'Add cooks, helpers and assign cashier roles',
        isCompleted: hasStaff,
      ),
      OnboardingStep(
        stepNumber: 4,
        titleBangla: 'আজকের দিনের হিসাব শুরু করুন',
        titleEnglish: 'Start First Business Day',
        descriptionBangla: 'ক্যাশের জমা টাকা লিখে আজকের খাতা খুলুন',
        descriptionEnglish: 'Input drawer opening float to start sales',
        isCompleted: hasOpenedDay,
      ),
    ];

    state = state.copyWith(steps: steps);
  }
}

final onboardingProgressProvider =
    StateNotifierProvider<OnboardingProgressNotifier, OnboardingState>((ref) {
  // Watch dependencies so checklist updates automatically in real-time
  ref.watch(mealConfigsNotifierProvider);
  ref.watch(customersNotifierProvider);
  ref.watch(staffNotifierProvider);
  ref.watch(businessDayNotifierProvider);

  final notifier = OnboardingProgressNotifier(ref);
  return notifier;
});
