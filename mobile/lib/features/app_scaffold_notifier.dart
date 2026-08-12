import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/staff_member.dart';

class AppNavScaffoldState {
  final int selectedIndex;
  final bool isCounterMode;
  final StaffMember? activeCounterStaff;

  const AppNavScaffoldState({
    this.selectedIndex = 0,
    this.isCounterMode = false,
    this.activeCounterStaff,
  });

  AppNavScaffoldState copyWith({
    int? selectedIndex,
    bool? isCounterMode,
    StaffMember? activeCounterStaff,
    bool clearActiveStaff = false,
  }) {
    return AppNavScaffoldState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isCounterMode: isCounterMode ?? this.isCounterMode,
      activeCounterStaff: clearActiveStaff
          ? null
          : (activeCounterStaff ?? this.activeCounterStaff),
    );
  }
}

class AppScaffoldNotifier extends StateNotifier<AppNavScaffoldState> {
  AppScaffoldNotifier() : super(const AppNavScaffoldState());

  void setTab(int index) {
    if (state.selectedIndex != index) {
      state = state.copyWith(selectedIndex: index);
    }
  }

  void activateCounterMode(StaffMember staff) {
    state = state.copyWith(
      isCounterMode: true,
      activeCounterStaff: staff,
      selectedIndex: 0,
    );
  }

  void exitCounterMode() {
    state = state.copyWith(
      isCounterMode: false,
      clearActiveStaff: true,
      selectedIndex: 0,
    );
  }
}

final scaffoldNotifierProvider =
    StateNotifierProvider<AppScaffoldNotifier, AppNavScaffoldState>((ref) {
  return AppScaffoldNotifier();
});
