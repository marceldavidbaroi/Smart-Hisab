// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'স্মার্ট হিসাব';

  @override
  String get navHome => 'হোম';

  @override
  String get navCustomers => 'খদ্দের তালিকা';

  @override
  String get navCashbook => 'ক্যাশ খাতা';

  @override
  String get navBazar => 'বাজার ফর্দ';

  @override
  String get navMore => 'আরও';

  @override
  String get navStaff => 'কর্মচারী';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get commonSave => 'সংরক্ষণ';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonDelete => 'মুছুন';

  @override
  String get commonEdit => 'সম্পাদনা';

  @override
  String get commonConfirm => 'নিশ্চিত করুন';

  @override
  String get commonClose => 'বন্ধ করুন';

  @override
  String get commonBack => 'ফিরে যান';

  @override
  String get commonSearch => 'অনুসন্ধান করুন';

  @override
  String get commonTotal => 'মোট';

  @override
  String get commonDue => 'বকেয়া';

  @override
  String get commonPaid => 'পরিশোধ';

  @override
  String get commonInflow => 'জমা (ইনফ্লো)';

  @override
  String get commonOutflow => 'খরচ (আউটফ্লো)';

  @override
  String get commonBalance => 'ব্যালেন্স';

  @override
  String get commonDate => 'তারিখ';

  @override
  String get commonNotes => 'মন্তব্য / বিবরণ';

  @override
  String get commonAmount => 'টাকার পরিমাণ';

  @override
  String get settingsTitle => 'সেটিংস ও কনফিগ';

  @override
  String get settingsManagementSection => 'ব্যবস্থাপনা ও পরিচালনা';

  @override
  String get settingsCanteenProfile => 'ক্যান্টিন প্রোফাইল';

  @override
  String get settingsCanteenProfileSub => 'নাম ও বিবরণ';

  @override
  String get settingsSwitchCanteen => 'ক্যান্টিন পরিবর্তন';

  @override
  String get settingsSwitchCanteenSub => 'অন্য ক্যান্টিনে যান';

  @override
  String get settingsShiftsConfig => 'শিফট সেটিংস';

  @override
  String get settingsShiftsConfigSub => 'খাওয়ার সময়সূচি';

  @override
  String get settingsMealRates => 'মিলের দর';

  @override
  String get settingsMealRatesSub => 'দর ও পূর্বের ইতিহাস';

  @override
  String get settingsVendorsLedger => 'মহাজনদের খাতা';

  @override
  String get settingsVendorsLedgerSub => 'সাপ্লায়ার ও বাকি';

  @override
  String get settingsInviteManager => 'ম্যানেজার ইনভাইট';

  @override
  String get settingsInviteManagerSub => '৬ সংখ্যার কোড';

  @override
  String get settingsMyProfile => 'আমার প্রোফাইল';

  @override
  String get settingsMyProfileSub => 'অ্যাকাউন্ট বিবরণ';

  @override
  String get settingsLanguage => 'ভাষা (Language)';

  @override
  String get settingsLanguageSub => 'বাংলা / English';

  @override
  String get settingsDarkMode => 'ডার্ক মোড';

  @override
  String get settingsLightMode => 'লাইট মোড';

  @override
  String get settingsSignOut => 'সাইন আউট';

  @override
  String get settingsSignOutSub => 'অ্যাকাউন্ট থেকে লগআউট করুন';

  @override
  String get settingsSignOutConfirm =>
      'আপনি কি নিশ্চিতভাবে স্মার্ট হিসাব থেকে সাইন আউট করতে চান?';

  @override
  String get homeDayOpen => '🟢 দিন চালু';

  @override
  String get homeDayClosed => '🟡 দিন বন্ধ';

  @override
  String get homeStartDayTitle => 'আজকের দিনের হিসাব শুরু করুন';

  @override
  String get homeStartDaySubtitle =>
      'দৈনিক মিল ও বিক্রির হিসাব রাখতে ক্যাশ ড্রয়ারের প্রারম্ভিক জমা লিখুন।';

  @override
  String get homeStartDayButton => 'হিসাব শুরু করুন';

  @override
  String homeActiveShift(String shiftName, String rate) {
    return 'শিফট: $shiftName • $rate/মিল';
  }

  @override
  String get homeEndDay => 'দিন সমাপ্ত';

  @override
  String get homeLiveDrawerCash => 'ক্যাশ ড্রয়ার ব্যালেন্স';

  @override
  String homeOpeningCashLabel(String amount) {
    return 'প্রারম্ভিক: $amount';
  }

  @override
  String get homeMeals => 'মিল সংখ্যা';

  @override
  String get homeInflows => 'জমা (ইনফ্লো)';

  @override
  String get homeOutflows => 'খরচ (আউটফ্লো)';

  @override
  String get homeYesterdayRecap => 'গতকালের সংক্ষিপ্ত হিসাব';

  @override
  String get homeBalanced => 'সঠিক আছে';

  @override
  String homeVarianceDiff(String amount) {
    return 'পার্থক্য: $amount';
  }

  @override
  String get homeMealsServed => 'মোট পরিবেশিত মিল';

  @override
  String get homeCashCollected => 'নগদ আদায়';

  @override
  String get homeTotalOutstandingBaki => 'গ্রাহকদের মোট বকেয়া বাকি';

  @override
  String get homeQuickActions => 'কুইক অ্যাকশন';

  @override
  String get homeActionMarkMeals => 'মিল গণনা';

  @override
  String get homeActionCollectBaki => 'বাকি আদায়';

  @override
  String get homeActionAddIncome => 'জমা লিখুন';

  @override
  String get homeActionAddExpense => 'খরচ লিখুন';

  @override
  String get homeActionDayNotes => 'দিনের নোট';

  @override
  String get homeLiveActivityFeed => 'সাম্প্রতিক লেনদেন';

  @override
  String get homeRecent5 => 'সর্বশেষ ৫টি';

  @override
  String get homeNoRecentTransactions => 'আজ এখনো কোনো লেনদেন লিপিবদ্ধ হয়নি।';

  @override
  String get homeOpenDayTitle => 'আজকের দিনের হিসাব শুরু করুন';

  @override
  String get homeOpeningCashLabelInput => 'প্রারম্ভিক ক্যাশ ব্যালেন্স (৳)';

  @override
  String get homeOpeningCashHint => 'ক্যাশের পরিমাণ লিখুন, যেমন: ৫০০০';

  @override
  String get homeOpenDayConfirm => 'নিশ্চিত করে দিন চালু করুন';

  @override
  String get homeCloseDayTitle => 'দিনের সমাপ্তি ও হিসাব মেলানো';

  @override
  String get homeExpectedCash => 'হিসাব অনুযায়ী প্রত্যাশিত ক্যাশ:';

  @override
  String get homeActualClosingCash => 'ড্রয়ারে থাকা প্রকৃত নগদ ক্যাশ (৳)';

  @override
  String get homeClosingCashHint => 'ড্রয়ারের মোট ক্যাশ লিখুন';

  @override
  String get homeCashSurplus => 'ক্যাশ অতিরিক্ত (+):';

  @override
  String get homeCashShortage => 'ক্যাশ ঘাটতি (-):';

  @override
  String get homeReconciliationBalanced => 'ক্যাশ হিসাব পুরোপুরি মিলে গেছে!';

  @override
  String get homeClosingNotesOptional => 'সমাপনী মন্তব্য (ঐচ্ছিক)';

  @override
  String get homeClosingNotesHint => 'যেমন: ভাংতি দেওয়ার কারণে ২০০ টাকা কম';

  @override
  String get homeCloseDayConfirm => 'হিসাব মিলিয়ে দিন বন্ধ করুন';

  @override
  String get homeSelectCustomerBaki => 'বাকি আদায়ের জন্য খদ্দের নির্বাচন করুন';

  @override
  String get homeSearchCustomerHint => 'নাম বা ফোন নম্বর দিয়ে খুঁজুন...';

  @override
  String get homeNoMatchingCustomers => 'কোনো খদ্দের পাওয়া যায়নি।';
}
