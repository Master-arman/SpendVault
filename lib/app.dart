import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/core/theme/radial_expansion_route.dart';
import 'package:finance_app/core/theme/shared_axis_route.dart';
import 'package:finance_app/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:finance_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:finance_app/features/automation/presentation/screens/automation_settings_screen.dart';
import 'package:finance_app/features/automation/presentation/screens/notification_consent_screen.dart';
import 'package:finance_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:finance_app/features/dashboard/presentation/dashboard_shell.dart';
import 'package:finance_app/features/splash/presentation/splash_screen.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/add_subscription_screen.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/filtered_transactions_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/split_bill_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:flutter/material.dart';

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppConstants.splashRoute,
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case AppConstants.splashRoute:
          case AppConstants.initialRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const SplashScreen(),
              settings: settings,
            );
          case AppConstants.dashboardRoute:
            return RadialExpansionRoute<void>(
              page: const DashboardShell(),
              settings: settings,
            );
          case AppConstants.transactionsRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const TransactionsScreen(),
              settings: settings,
            );
          case AppConstants.accountsRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const AccountsScreen(),
              settings: settings,
            );
          case AppConstants.analyticsRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const AnalyticsScreen(),
              settings: settings,
            );
          case AppConstants.categoriesRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const CategoriesScreen(),
              settings: settings,
            );
          case AppConstants.subscriptionsRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const SubscriptionsScreen(),
              settings: settings,
            );
          case AppConstants.filteredTransactionsRoute:
            final Map<String, dynamic> args = (settings.arguments as Map<String, dynamic>?) ?? {};
            return SharedAxisPageRoute<void>(
              page: FilteredTransactionsScreen(
                categoryId: args['categoryId'] as String?,
                categoryName: args['categoryName'] as String?,
                startDate: args['startDate'] as DateTime?,
                endDate: args['endDate'] as DateTime?,
              ),
              settings: settings,
            );
          case AppConstants.splitBillRoute:
            final Map<String, dynamic> args = (settings.arguments as Map<String, dynamic>?) ?? {};
            return MaterialPageRoute<void>(
              builder: (_) => SplitBillScreen(
                initialBillAmount: (args['initialBillAmount'] as num?)?.toDouble() ?? 120.0,
                initialParticipants: (args['initialParticipants'] as num?)?.toInt() ?? 4,
                categoryName: (args['categoryName'] as String?) ?? 'Food & Dining',
              ),
              settings: settings,
            );
          case AppConstants.notificationConsentRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const NotificationConsentScreen(),
              settings: settings,
            );
          case AppConstants.automationRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const AutomationSettingsScreen(),
              settings: settings,
            );
          case AppConstants.addSubscriptionRoute:
            return MaterialPageRoute<void>(
              builder: (_) => const AddSubscriptionScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute<void>(
              builder: (_) => const DashboardShell(),
              settings: settings,
            );
        }
      },
    );
  }
}
