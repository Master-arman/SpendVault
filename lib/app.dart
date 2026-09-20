import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_theme.dart';
import 'package:finance_app/core/theme/radial_expansion_route.dart';
import 'package:finance_app/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:finance_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:finance_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:finance_app/features/dashboard/presentation/dashboard_shell.dart';
import 'package:finance_app/features/splash/presentation/splash_screen.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/subscriptions_screen.dart';
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
