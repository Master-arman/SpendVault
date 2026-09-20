import 'dart:io';

import 'package:finance_app/features/onboarding/domain/onboarding_service.dart';
import 'package:finance_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ── path_provider mock ───────────────────────────────────────────────────────

class _MockPathProvider
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;

  _MockPathProvider(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getApplicationCachePath() async => tempDir.path;

  @override
  Future<String?> getExternalStoragePath() async => tempDir.path;

  @override
  Future<List<String>?> getExternalCachePaths() async => <String>[tempDir.path];

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async =>
      <String>[tempDir.path];

  @override
  Future<String?> getDownloadsPath() async => tempDir.path;

  @override
  Future<String?> getLibraryPath() async => tempDir.path;
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Directory? _tempDir;

Future<void> _setupPathProvider() async {
  _tempDir = await Directory.systemTemp.createTemp('onboarding_test_');
  PathProviderPlatform.instance = _MockPathProvider(_tempDir!);
}

Future<void> _teardownPathProvider() async {
  try {
    _tempDir?.deleteSync(recursive: true);
  } catch (_) {}
  _tempDir = null;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── OnboardingService ──────────────────────────────────────────────────────

  group('OnboardingService', () {
    setUp(_setupPathProvider);
    tearDown(_teardownPathProvider);

    test('hasSeenOnboarding() returns false on first call', () async {
      // Reset state to ensure clean slate.
      await OnboardingService.instance.resetOnboarding();
      expect(await OnboardingService.instance.hasSeenOnboarding(), isFalse);
    });

    test('markOnboardingSeen() makes hasSeenOnboarding() return true', () async {
      await OnboardingService.instance.resetOnboarding();
      expect(await OnboardingService.instance.hasSeenOnboarding(), isFalse);

      await OnboardingService.instance.markOnboardingSeen();

      expect(await OnboardingService.instance.hasSeenOnboarding(), isTrue);
    });

    test('resetOnboarding() makes hasSeenOnboarding() return false again',
        () async {
      await OnboardingService.instance.markOnboardingSeen();
      expect(await OnboardingService.instance.hasSeenOnboarding(), isTrue);

      await OnboardingService.instance.resetOnboarding();

      expect(await OnboardingService.instance.hasSeenOnboarding(), isFalse);
    });

    test('calling markOnboardingSeen() twice does not throw', () async {
      await OnboardingService.instance.resetOnboarding();
      await expectLater(
        OnboardingService.instance.markOnboardingSeen(),
        completes,
      );
      await expectLater(
        OnboardingService.instance.markOnboardingSeen(),
        completes,
      );
    });
  });

  // ── OnboardingScreen widget tests ──────────────────────────────────────────

  group('OnboardingScreen', () {
    // No setUp/tearDown needed — widget tests do not invoke path_provider.

    Widget _buildScreen() {
      return MaterialApp(
        routes: <String, WidgetBuilder>{
          '/dashboard': (_) => const Scaffold(body: Text('Dashboard')),
          '/onboarding': (_) => const OnboardingScreen(),
        },
        home: const OnboardingScreen(),
      );
    }

    testWidgets('renders all 3 slide titles on swipe', (WidgetTester tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      // Slide 1
      expect(find.text('Complete On-Device Storage'), findsOneWidget);

      // Swipe to slide 2
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Multi-Account Ledger'), findsOneWidget);

      // Swipe to slide 3
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Automatic Detection'), findsOneWidget);
    });

    testWidgets('Next button advances to next slide', (WidgetTester tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.text('Complete On-Device Storage'), findsOneWidget);

      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Multi-Account Ledger'), findsOneWidget);
    });

    testWidgets('Skip button is present on slides 1 and 2',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      // Skip visible on slide 1
      expect(find.byKey(const Key('skip_button')), findsOneWidget);

      // Still visible on slide 2
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('skip_button')), findsOneWidget);
    });

    testWidgets('Get Started appears on last slide', (WidgetTester tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      // Swipe to last slide
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('Get Started button is present on last slide and labelled correctly',
        (WidgetTester tester) async {
      // Widget-only check — no path_provider calls needed.
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingScreen()),
      );
      await tester.pump();

      // Navigate to last slide via Next taps
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });
  });
}
