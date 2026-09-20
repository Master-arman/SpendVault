import 'package:finance_app/core/localization/locale_provider.dart';
import 'package:finance_app/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 55: LocaleProvider Unit Tests', () {
    setUp(() {
      LocaleProvider.instance.setLocale(LocaleProvider.defaultLocale);
    });

    tearDown(() {
      LocaleProvider.instance.setLocale(LocaleProvider.defaultLocale);
    });

    test('LocaleProvider defaults to English', () {
      expect(LocaleProvider.instance.value, const Locale('en'));
      expect(LocaleProvider.instance.isEnglish, isTrue);
      expect(LocaleProvider.instance.isHindi, isFalse);
    });

    test('LocaleProvider setLocale updates locale properly', () {
      LocaleProvider.instance.setLocale(const Locale('hi'));
      expect(LocaleProvider.instance.value, const Locale('hi'));
      expect(LocaleProvider.instance.isHindi, isTrue);
      expect(LocaleProvider.instance.isEnglish, isFalse);
    });

    test('LocaleProvider toggleLocale toggles between English and Hindi', () {
      expect(LocaleProvider.instance.isEnglish, isTrue);

      LocaleProvider.instance.toggleLocale();
      expect(LocaleProvider.instance.isHindi, isTrue);

      LocaleProvider.instance.toggleLocale();
      expect(LocaleProvider.instance.isEnglish, isTrue);
    });
  });

  group('Phase 55: AppLocalizations Widget & Resolution Tests', () {
    Widget buildTestWidget({required Locale locale, required WidgetBuilder builder}) {
      return MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: builder),
      );
    }

    testWidgets('AppLocalizations provides correct English translations for transactions, settings, and errors',
        (WidgetTester tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('en'),
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Column(
                children: [
                  Text(l10n.totalBalance),
                  Text(l10n.addTransaction),
                  Text(l10n.expense),
                  Text(l10n.income),
                  Text(l10n.recentActivity),
                  Text(l10n.viewAll),
                  Text(l10n.fastActions),
                  Text(l10n.transfer),
                  Text(l10n.splitBill),
                  Text(l10n.settings),
                  Text(l10n.theme),
                  Text(l10n.language),
                  Text(l10n.english),
                  Text(l10n.hindi),
                  Text(l10n.notifications),
                  Text(l10n.errorGeneric),
                  Text(l10n.errorNetwork),
                  Text(l10n.errorAuthFailed),
                  Text(l10n.errorRequiredField),
                  Text(l10n.errorInvalidAmount),
                ],
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(l10n.totalBalance, equals('Total Balance'));
      expect(l10n.addTransaction, equals('Add Transaction'));
      expect(l10n.expense, equals('Expense'));
      expect(l10n.income, equals('Income'));
      expect(l10n.recentActivity, equals('Recent Activity'));
      expect(l10n.viewAll, equals('View All'));
      expect(l10n.fastActions, equals('Fast Actions'));
      expect(l10n.transfer, equals('Transfer'));
      expect(l10n.splitBill, equals('Split Bill'));
      expect(l10n.settings, equals('Settings'));
      expect(l10n.theme, equals('Theme'));
      expect(l10n.language, equals('Language'));
      expect(l10n.english, equals('English'));
      expect(l10n.hindi, equals('Hindi'));
      expect(l10n.notifications, equals('Notifications'));
      expect(l10n.errorGeneric, equals('An unexpected error occurred'));
      expect(l10n.errorNetwork, equals('Network connection error'));
      expect(l10n.errorAuthFailed, equals('Authentication failed'));
      expect(l10n.errorRequiredField, equals('This field is required'));
      expect(l10n.errorInvalidAmount, equals('Please enter a valid amount'));

      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
    });

    testWidgets('AppLocalizations provides correct Hindi translations for transactions, settings, and errors',
        (WidgetTester tester) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        buildTestWidget(
          locale: const Locale('hi'),
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Column(
                children: [
                  Text(l10n.totalBalance),
                  Text(l10n.addTransaction),
                  Text(l10n.expense),
                  Text(l10n.income),
                  Text(l10n.recentActivity),
                  Text(l10n.viewAll),
                  Text(l10n.fastActions),
                  Text(l10n.transfer),
                  Text(l10n.splitBill),
                  Text(l10n.settings),
                  Text(l10n.theme),
                  Text(l10n.language),
                  Text(l10n.english),
                  Text(l10n.hindi),
                  Text(l10n.notifications),
                  Text(l10n.errorGeneric),
                  Text(l10n.errorNetwork),
                  Text(l10n.errorAuthFailed),
                  Text(l10n.errorRequiredField),
                  Text(l10n.errorInvalidAmount),
                ],
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(l10n.totalBalance, equals('कुल शेष'));
      expect(l10n.addTransaction, equals('लेन-देन जोड़ें'));
      expect(l10n.expense, equals('खर्च'));
      expect(l10n.income, equals('आय'));
      expect(l10n.recentActivity, equals('हाल की गतिविधि'));
      expect(l10n.viewAll, equals('सभी देखें'));
      expect(l10n.fastActions, equals('त्वरित क्रियाएं'));
      expect(l10n.transfer, equals('स्थानांतरण'));
      expect(l10n.splitBill, equals('बिल बांटें'));
      expect(l10n.settings, equals('सेटिंग्स'));
      expect(l10n.theme, equals('थीम'));
      expect(l10n.language, equals('भाषा'));
      expect(l10n.english, equals('अंग्रेज़ी'));
      expect(l10n.hindi, equals('हिन्दी'));
      expect(l10n.notifications, equals('सूचनाएं'));
      expect(l10n.errorGeneric, equals('एक अप्रत्याशित त्रुटि हुई'));
      expect(l10n.errorNetwork, equals('नेटवर्क कनेक्शन त्रुटि'));
      expect(l10n.errorAuthFailed, equals('प्रमाणीकरण विफल रहा'));
      expect(l10n.errorRequiredField, equals('यह फ़ील्ड आवश्यक है'));
      expect(l10n.errorInvalidAmount, equals('कृपया एक मान्य राशि दर्ज करें'));

      expect(find.text('कुल शेष'), findsOneWidget);
      expect(find.text('लेन-देन जोड़ें'), findsOneWidget);
      expect(find.text('खर्च'), findsOneWidget);
      expect(find.text('आय'), findsOneWidget);
    });

    testWidgets('Reactive language switching with LocaleProvider dynamically updates UI text',
        (WidgetTester tester) async {
      LocaleProvider.instance.setLocale(const Locale('en'));

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: LocaleProvider.instance,
          builder: (context, currentLocale, _) {
            return MaterialApp(
              locale: currentLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (ctx) {
                  final loc = AppLocalizations.of(ctx)!;
                  return Scaffold(
                    body: Center(
                      child: Text(loc.totalBalance, key: const Key('balance_label')),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
      await tester.pump();

      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('कुल शेष'), findsNothing);

      // Switch to Hindi
      LocaleProvider.instance.setLocale(const Locale('hi'));
      await tester.pump();

      expect(find.text('कुल शेष'), findsOneWidget);
      expect(find.text('Total Balance'), findsNothing);
    });
  });
}
