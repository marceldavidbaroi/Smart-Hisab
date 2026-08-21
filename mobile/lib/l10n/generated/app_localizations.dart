import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Smart-Hisab'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navCashbook.
  ///
  /// In en, this message translates to:
  /// **'Cashbook'**
  String get navCashbook;

  /// No description provided for @navBazar.
  ///
  /// In en, this message translates to:
  /// **'Bazar'**
  String get navBazar;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get navStaff;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @commonDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get commonDue;

  /// No description provided for @commonPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get commonPaid;

  /// No description provided for @commonInflow.
  ///
  /// In en, this message translates to:
  /// **'Inflow'**
  String get commonInflow;

  /// No description provided for @commonOutflow.
  ///
  /// In en, this message translates to:
  /// **'Outflow'**
  String get commonOutflow;

  /// No description provided for @commonBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get commonBalance;

  /// No description provided for @commonDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

  /// No description provided for @commonNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get commonNotes;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & Config'**
  String get settingsTitle;

  /// No description provided for @settingsManagementSection.
  ///
  /// In en, this message translates to:
  /// **'Management & Operations'**
  String get settingsManagementSection;

  /// No description provided for @settingsCanteenProfile.
  ///
  /// In en, this message translates to:
  /// **'Canteen Profile'**
  String get settingsCanteenProfile;

  /// No description provided for @settingsCanteenProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Name & tier info'**
  String get settingsCanteenProfileSub;

  /// No description provided for @settingsSwitchCanteen.
  ///
  /// In en, this message translates to:
  /// **'Switch Canteen'**
  String get settingsSwitchCanteen;

  /// No description provided for @settingsSwitchCanteenSub.
  ///
  /// In en, this message translates to:
  /// **'Change active shop'**
  String get settingsSwitchCanteenSub;

  /// No description provided for @settingsShiftsConfig.
  ///
  /// In en, this message translates to:
  /// **'Shifts Config'**
  String get settingsShiftsConfig;

  /// No description provided for @settingsShiftsConfigSub.
  ///
  /// In en, this message translates to:
  /// **'Operating hours'**
  String get settingsShiftsConfigSub;

  /// No description provided for @settingsMealRates.
  ///
  /// In en, this message translates to:
  /// **'Meal Rates'**
  String get settingsMealRates;

  /// No description provided for @settingsMealRatesSub.
  ///
  /// In en, this message translates to:
  /// **'Pricing & history'**
  String get settingsMealRatesSub;

  /// No description provided for @settingsVendorsLedger.
  ///
  /// In en, this message translates to:
  /// **'Vendors Ledger'**
  String get settingsVendorsLedger;

  /// No description provided for @settingsVendorsLedgerSub.
  ///
  /// In en, this message translates to:
  /// **'Suppliers & baki'**
  String get settingsVendorsLedgerSub;

  /// No description provided for @settingsInviteManager.
  ///
  /// In en, this message translates to:
  /// **'Invite Manager'**
  String get settingsInviteManager;

  /// No description provided for @settingsInviteManagerSub.
  ///
  /// In en, this message translates to:
  /// **'6-digit join code'**
  String get settingsInviteManagerSub;

  /// No description provided for @settingsMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get settingsMyProfile;

  /// No description provided for @settingsMyProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get settingsMyProfileSub;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'English / বাংলা'**
  String get settingsLanguageSub;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get settingsDarkMode;

  /// No description provided for @settingsLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get settingsLightMode;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutSub.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your Smart-Hisab account'**
  String get settingsSignOutSub;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of Smart-Hisab?'**
  String get settingsSignOutConfirm;

  /// No description provided for @homeDayOpen.
  ///
  /// In en, this message translates to:
  /// **'🟢 Day Open'**
  String get homeDayOpen;

  /// No description provided for @homeDayClosed.
  ///
  /// In en, this message translates to:
  /// **'🟡 Day Closed'**
  String get homeDayClosed;

  /// No description provided for @homeStartDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Today\'s Business Day'**
  String get homeStartDayTitle;

  /// No description provided for @homeStartDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set opening cash drawer amount to record daily meals & sales.'**
  String get homeStartDaySubtitle;

  /// No description provided for @homeStartDayButton.
  ///
  /// In en, this message translates to:
  /// **'Start Business Day'**
  String get homeStartDayButton;

  /// No description provided for @homeActiveShift.
  ///
  /// In en, this message translates to:
  /// **'Shift: {shiftName} • {rate}/meal'**
  String homeActiveShift(String shiftName, String rate);

  /// No description provided for @homeEndDay.
  ///
  /// In en, this message translates to:
  /// **'End Day'**
  String get homeEndDay;

  /// No description provided for @homeLiveDrawerCash.
  ///
  /// In en, this message translates to:
  /// **'Live Drawer Cash'**
  String get homeLiveDrawerCash;

  /// No description provided for @homeOpeningCashLabel.
  ///
  /// In en, this message translates to:
  /// **'Open: {amount}'**
  String homeOpeningCashLabel(String amount);

  /// No description provided for @homeMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get homeMeals;

  /// No description provided for @homeInflows.
  ///
  /// In en, this message translates to:
  /// **'Inflows'**
  String get homeInflows;

  /// No description provided for @homeOutflows.
  ///
  /// In en, this message translates to:
  /// **'Outflows'**
  String get homeOutflows;

  /// No description provided for @homeYesterdayRecap.
  ///
  /// In en, this message translates to:
  /// **'Yesterday\'s Recap'**
  String get homeYesterdayRecap;

  /// No description provided for @homeBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get homeBalanced;

  /// No description provided for @homeVarianceDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff: {amount}'**
  String homeVarianceDiff(String amount);

  /// No description provided for @homeMealsServed.
  ///
  /// In en, this message translates to:
  /// **'Meals Served'**
  String get homeMealsServed;

  /// No description provided for @homeCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash Collected'**
  String get homeCashCollected;

  /// No description provided for @homeTotalOutstandingBaki.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding Customer Baki'**
  String get homeTotalOutstandingBaki;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get homeQuickActions;

  /// No description provided for @homeActionMarkMeals.
  ///
  /// In en, this message translates to:
  /// **'Mark Meals'**
  String get homeActionMarkMeals;

  /// No description provided for @homeActionCollectBaki.
  ///
  /// In en, this message translates to:
  /// **'Collect Baki'**
  String get homeActionCollectBaki;

  /// No description provided for @homeActionAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get homeActionAddIncome;

  /// No description provided for @homeActionAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get homeActionAddExpense;

  /// No description provided for @homeActionDayNotes.
  ///
  /// In en, this message translates to:
  /// **'Day Notes'**
  String get homeActionDayNotes;

  /// No description provided for @homeLiveActivityFeed.
  ///
  /// In en, this message translates to:
  /// **'Live Activity Feed'**
  String get homeLiveActivityFeed;

  /// No description provided for @homeRecent5.
  ///
  /// In en, this message translates to:
  /// **'Recent 5'**
  String get homeRecent5;

  /// No description provided for @homeNoRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions recorded today.'**
  String get homeNoRecentTransactions;

  /// No description provided for @homeOpenDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Today\'s Business Day'**
  String get homeOpenDayTitle;

  /// No description provided for @homeOpeningCashLabelInput.
  ///
  /// In en, this message translates to:
  /// **'Opening Cash Balance (৳)'**
  String get homeOpeningCashLabelInput;

  /// No description provided for @homeOpeningCashHint.
  ///
  /// In en, this message translates to:
  /// **'Enter drawer cash e.g. 5000'**
  String get homeOpeningCashHint;

  /// No description provided for @homeOpenDayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Open Day'**
  String get homeOpenDayConfirm;

  /// No description provided for @homeCloseDayTitle.
  ///
  /// In en, this message translates to:
  /// **'End Business Day & Reconcile'**
  String get homeCloseDayTitle;

  /// No description provided for @homeExpectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected Cash:'**
  String get homeExpectedCash;

  /// No description provided for @homeActualClosingCash.
  ///
  /// In en, this message translates to:
  /// **'Actual Closing Cash in Drawer (৳)'**
  String get homeActualClosingCash;

  /// No description provided for @homeClosingCashHint.
  ///
  /// In en, this message translates to:
  /// **'Enter actual cash in drawer'**
  String get homeClosingCashHint;

  /// No description provided for @homeCashSurplus.
  ///
  /// In en, this message translates to:
  /// **'Cash Surplus (+):'**
  String get homeCashSurplus;

  /// No description provided for @homeCashShortage.
  ///
  /// In en, this message translates to:
  /// **'Cash Shortage (-):'**
  String get homeCashShortage;

  /// No description provided for @homeReconciliationBalanced.
  ///
  /// In en, this message translates to:
  /// **'Cash matched perfectly! Expected = Actual'**
  String get homeReconciliationBalanced;

  /// No description provided for @homeClosingNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Closing Notes (Optional)'**
  String get homeClosingNotesOptional;

  /// No description provided for @homeClosingNotesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ৳200 short due to wrong change'**
  String get homeClosingNotesHint;

  /// No description provided for @homeCloseDayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reconcile & Close Business Day'**
  String get homeCloseDayConfirm;

  /// No description provided for @homeSelectCustomerBaki.
  ///
  /// In en, this message translates to:
  /// **'Select Customer for Baki Collection'**
  String get homeSelectCustomerBaki;

  /// No description provided for @homeSearchCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer by name or phone...'**
  String get homeSearchCustomerHint;

  /// No description provided for @homeNoMatchingCustomers.
  ///
  /// In en, this message translates to:
  /// **'No matching customers found.'**
  String get homeNoMatchingCustomers;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
