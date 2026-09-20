import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:finance_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:finance_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:finance_app/features/subscriptions/presentation/screens/subscriptions_screen.dart';
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
    AccountsScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    SubscriptionsScreen(),
    CategoriesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderStroke, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_rounded),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
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
