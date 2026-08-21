import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_scaffold_notifier.dart';
import 'widgets/custom_bottom_nav.dart';
import 'home/home_screen.dart';
import 'customers/customers_screen.dart';
import 'cashbook/cashbook_screen.dart';
import 'bazar/bazar_screen.dart';
import 'settings/settings_screen.dart';

/// 5-Tab Application Navigation Scaffold for Smart-Hisab
/// [0: Home, 1: Customers, 2: Cashbook, 3: Bazar, 4: More/Settings]
class AppScaffold extends ConsumerStatefulWidget {
  const AppScaffold({super.key});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  final Set<int> _visitedIndices = {0}; // Only Tab 0 (Home) starts mounted

  @override
  Widget build(BuildContext context) {
    final scaffoldState = ref.watch(scaffoldNotifierProvider);
    final scaffoldNotifier = ref.read(scaffoldNotifierProvider.notifier);
    final currentIndex = scaffoldState.selectedIndex.clamp(0, 4);

    if (!_visitedIndices.contains(currentIndex)) {
      _visitedIndices.add(currentIndex);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: currentIndex,
        children: [
          const HomeScreen(),
          _visitedIndices.contains(1) ? const CustomersScreen() : const SizedBox.shrink(),
          _visitedIndices.contains(2) ? const CashbookScreen() : const SizedBox.shrink(),
          _visitedIndices.contains(3) ? const BazarScreen() : const SizedBox.shrink(),
          _visitedIndices.contains(4) ? const SettingsScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: currentIndex,
        onTabSelected: (index) {
          if (!_visitedIndices.contains(index)) {
            setState(() => _visitedIndices.add(index));
          }
          scaffoldNotifier.setTab(index);
        },
      ),
    );
  }
}

