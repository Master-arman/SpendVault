// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SpendVault';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get viewAll => 'View All';

  @override
  String get fastActions => 'Fast Actions';

  @override
  String get transfer => 'Transfer';

  @override
  String get splitBill => 'Split Bill';

  @override
  String get scanSms => 'Scan SMS';

  @override
  String get exportReport => 'Export Report';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get notifications => 'Notifications';

  @override
  String get errorGeneric => 'An unexpected error occurred';

  @override
  String get errorNetwork => 'Network connection error';

  @override
  String get errorAuthFailed => 'Authentication failed';

  @override
  String get errorRequiredField => 'This field is required';

  @override
  String get errorInvalidAmount => 'Please enter a valid amount';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';
}
