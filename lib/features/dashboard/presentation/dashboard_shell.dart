import 'package:finance_app/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:finance_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:finance_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/subscriptions_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/dashboard_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:flutter/material.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    AccountsScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    SubscriptionsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard_rounded),
              label: 'Executive',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_rounded),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Ledger',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.repeat_rounded),
              label: 'Subs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_rounded),
              label: 'Categories',
            ),
          ],
        ),
      ),
    );
  }
}

