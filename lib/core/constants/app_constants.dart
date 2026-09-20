/// Application wide constants and configuration tokens.
class AppConstants {
  const AppConstants._();

  static const String appName = 'FinanceX';
  static const String appVersion = '1.0.0';
  static const String defaultCurrencySymbol = '\$';
  static const String defaultCurrencyCode = 'USD';
  static const String defaultLocale = 'en_US';

  // Storage Keys
  static const String themeKey = 'app_theme_mode';
  static const String userPreferencesKey = 'user_prefs';
  static const String authSessionKey = 'auth_session';

  // Route Names
  static const String initialRoute = '/';
  static const String splashRoute = '/splash';
  static const String dashboardRoute = '/dashboard';
  static const String transactionsRoute = '/transactions';
  static const String accountsRoute = '/accounts';
  static const String analyticsRoute = '/analytics';
  static const String categoriesRoute = '/categories';
  static const String subscriptionsRoute = '/subscriptions';
  static const String automationRoute = '/automation';
  static const String notificationConsentRoute = '/automation/consent';
  static const String filteredTransactionsRoute = '/transactions/filtered';
  static const String splitBillRoute = '/transactions/split';
  static const String addSubscriptionRoute = '/subscriptions/add';
}
