import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNavScaffoldState {
  final int selectedIndex;

  const AppNavScaffoldState({
    this.selectedIndex = 0,
  });

  AppNavScaffoldState copyWith({
    int? selectedIndex,
  }) {
    return AppNavScaffoldState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
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
}

final scaffoldNotifierProvider =
    StateNotifierProvider<AppScaffoldNotifier, AppNavScaffoldState>((ref) {
  return AppScaffoldNotifier();
});

