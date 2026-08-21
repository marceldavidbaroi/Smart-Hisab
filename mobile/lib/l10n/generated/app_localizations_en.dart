// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Smart-Hisab';

  @override
  String get navHome => 'Home';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navCashbook => 'Cashbook';

  @override
  String get navBazar => 'Bazar';

  @override
  String get navMore => 'More';

  @override
  String get navStaff => 'Staff';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonDue => 'Due';

  @override
  String get commonPaid => 'Paid';

  @override
  String get commonInflow => 'Inflow';

  @override
  String get commonOutflow => 'Outflow';

  @override
  String get commonBalance => 'Balance';

  @override
  String get commonDate => 'Date';

  @override
  String get commonNotes => 'Notes';

  @override
  String get commonAmount => 'Amount';

  @override
  String get settingsTitle => 'Settings & Config';

  @override
  String get settingsManagementSection => 'Management & Operations';

  @override
  String get settingsCanteenProfile => 'Canteen Profile';

  @override
  String get settingsCanteenProfileSub => 'Name & tier info';

  @override
  String get settingsSwitchCanteen => 'Switch Canteen';

  @override
  String get settingsSwitchCanteenSub => 'Change active shop';

  @override
  String get settingsShiftsConfig => 'Shifts Config';

  @override
  String get settingsShiftsConfigSub => 'Operating hours';

  @override
  String get settingsMealRates => 'Meal Rates';

  @override
  String get settingsMealRatesSub => 'Pricing & history';

  @override
  String get settingsVendorsLedger => 'Vendors Ledger';

  @override
  String get settingsVendorsLedgerSub => 'Suppliers & baki';

  @override
  String get settingsInviteManager => 'Invite Manager';

  @override
  String get settingsInviteManagerSub => '6-digit join code';

  @override
  String get settingsMyProfile => 'My Profile';

  @override
  String get settingsMyProfileSub => 'Account details';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSub => 'English / বাংলা';

  @override
  String get settingsDarkMode => 'Dark Theme';

  @override
  String get settingsLightMode => 'Light Theme';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutSub => 'Sign out of your Smart-Hisab account';

  @override
  String get settingsSignOutConfirm =>
      'Are you sure you want to sign out of Smart-Hisab?';

  @override
  String get homeDayOpen => '🟢 Day Open';

  @override
  String get homeDayClosed => '🟡 Day Closed';

  @override
  String get homeStartDayTitle => 'Start Today\'s Business Day';

  @override
  String get homeStartDaySubtitle =>
      'Set opening cash drawer amount to record daily meals & sales.';

  @override
  String get homeStartDayButton => 'Start Business Day';

  @override
  String homeActiveShift(String shiftName, String rate) {
    return 'Shift: $shiftName • $rate/meal';
  }

  @override
  String get homeEndDay => 'End Day';

  @override
  String get homeLiveDrawerCash => 'Live Drawer Cash';

  @override
  String homeOpeningCashLabel(String amount) {
    return 'Open: $amount';
  }

  @override
  String get homeMeals => 'Meals';

  @override
  String get homeInflows => 'Inflows';

  @override
  String get homeOutflows => 'Outflows';

  @override
  String get homeYesterdayRecap => 'Yesterday\'s Recap';

  @override
  String get homeBalanced => 'Balanced';

  @override
  String homeVarianceDiff(String amount) {
    return 'Diff: $amount';
  }

  @override
  String get homeMealsServed => 'Meals Served';

  @override
  String get homeCashCollected => 'Cash Collected';

  @override
  String get homeTotalOutstandingBaki => 'Total Outstanding Customer Baki';

  @override
  String get homeQuickActions => 'Quick Actions';

  @override
  String get homeActionMarkMeals => 'Mark Meals';

  @override
  String get homeActionCollectBaki => 'Collect Baki';

  @override
  String get homeActionAddIncome => 'Add Income';

  @override
  String get homeActionAddExpense => 'Add Expense';

  @override
  String get homeActionDayNotes => 'Day Notes';

  @override
  String get homeLiveActivityFeed => 'Live Activity Feed';

  @override
  String get homeRecent5 => 'Recent 5';

  @override
  String get homeNoRecentTransactions =>
      'No recent transactions recorded today.';

  @override
  String get homeOpenDayTitle => 'Start Today\'s Business Day';

  @override
  String get homeOpeningCashLabelInput => 'Opening Cash Balance (৳)';

  @override
  String get homeOpeningCashHint => 'Enter drawer cash e.g. 5000';

  @override
  String get homeOpenDayConfirm => 'Confirm & Open Day';

  @override
  String get homeCloseDayTitle => 'End Business Day & Reconcile';

  @override
  String get homeExpectedCash => 'Expected Cash:';

  @override
  String get homeActualClosingCash => 'Actual Closing Cash in Drawer (৳)';

  @override
  String get homeClosingCashHint => 'Enter actual cash in drawer';

  @override
  String get homeCashSurplus => 'Cash Surplus (+):';

  @override
  String get homeCashShortage => 'Cash Shortage (-):';

  @override
  String get homeReconciliationBalanced =>
      'Cash matched perfectly! Expected = Actual';

  @override
  String get homeClosingNotesOptional => 'Closing Notes (Optional)';

  @override
  String get homeClosingNotesHint => 'e.g. ৳200 short due to wrong change';

  @override
  String get homeCloseDayConfirm => 'Reconcile & Close Business Day';

  @override
  String get homeSelectCustomerBaki => 'Select Customer for Baki Collection';

  @override
  String get homeSearchCustomerHint => 'Search customer by name or phone...';

  @override
  String get homeNoMatchingCustomers => 'No matching customers found.';
}
