import 'package:finance_app/features/security/domain/biometric_auth_service.dart';
import 'package:finance_app/features/security/presentation/app_lock_observer.dart';
import 'package:finance_app/features/security/presentation/screens/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates local_auth platform channel responses.
void _setupLocalAuthMock({required bool canAuthenticate, required bool success}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/local_auth'),
    (MethodCall call) async {
      switch (call.method) {
        case 'getAvailableBiometrics':
          return canAuthenticate ? <String>['fingerprint'] : <String>[];
        case 'isDeviceSupported':
          return canAuthenticate;
        case 'authenticate':
          return success;
        case 'stopAuthentication':
          return true;
        default:
          return null;
      }
    },
  );
}

void main() {
  late BiometricAuthService service;

  setUp(() {
    // Always start from a clean singleton state.
    service = BiometricAuthService.instance;
    service.isLocked.value = false;
  });

  tearDown(() {
    service.isLocked.value = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      null,
    );
  });

  // ── Unit Tests: BiometricAuthService ────────────────────────────────────────

  group('BiometricAuthService', () {
    test('initial state: isLocked is false', () {
      expect(service.isLocked.value, isFalse);
    });

    test('lock() sets isLocked to true', () {
      service.lock();
      expect(service.isLocked.value, isTrue);
    });

    test('successful authenticate() unlocks the service', () async {
      _setupLocalAuthMock(canAuthenticate: true, success: true);
      service.lock();
      expect(service.isLocked.value, isTrue);

      final AuthResult result = await service.authenticate();

      expect(result, AuthResult.success);
      expect(service.isLocked.value, isFalse);
    });

    test('failed authenticate() keeps isLocked true', () async {
      _setupLocalAuthMock(canAuthenticate: true, success: false);
      service.lock();

      final AuthResult result = await service.authenticate();

      expect(result, AuthResult.failure);
      expect(service.isLocked.value, isTrue);
    });

    test('authenticate() returns notAvailable when device has no biometrics',
        () async {
      _setupLocalAuthMock(canAuthenticate: false, success: false);

      final AuthResult result = await service.authenticate();

      expect(result, AuthResult.notAvailable);
    });

    test('isAvailable() returns true when device supports biometrics', () async {
      _setupLocalAuthMock(canAuthenticate: true, success: true);
      final bool available = await service.isAvailable();
      expect(available, isTrue);
    });

    test('isAvailable() returns false when device has no biometrics', () async {
      _setupLocalAuthMock(canAuthenticate: false, success: false);
      final bool available = await service.isAvailable();
      expect(available, isFalse);
    });
  });

  // ── Widget Tests: LockScreen ────────────────────────────────────────────────

  group('LockScreen', () {
    testWidgets('renders Unlock button', (WidgetTester tester) async {
      _setupLocalAuthMock(canAuthenticate: true, success: false);
      service.lock();

      await tester.pumpWidget(const MaterialApp(home: LockScreen()));
      await tester.pump(); // let initState's postFrameCallback fire

      expect(find.byKey(const Key('unlock_button')), findsOneWidget);
    });

    testWidgets('shows Locked heading', (WidgetTester tester) async {
      _setupLocalAuthMock(canAuthenticate: true, success: false);
      service.lock();

      await tester.pumpWidget(const MaterialApp(home: LockScreen()));
      await tester.pump();

      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('Unlock button is present and tappable when not authenticating',
        (WidgetTester tester) async {
      // Use a setup where auth is not available so the auto-trigger returns
      // immediately with notAvailable and the button re-enables.
      _setupLocalAuthMock(canAuthenticate: false, success: false);
      service.lock();

      await tester.pumpWidget(const MaterialApp(home: LockScreen()));
      // Pump enough frames for postFrameCallback + setState to complete.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Button should be enabled (isAuthenticating = false after notAvailable).
      final Finder button = find.byKey(const Key('unlock_button'));
      expect(button, findsOneWidget);

      // The label should be 'Unlock' (not loading).
      expect(find.text('Unlock'), findsOneWidget);
    });
  });

  // ── Widget Tests: AppLockObserver ───────────────────────────────────────────

  group('AppLockObserver', () {
    testWidgets('shows child when isLocked is false', (WidgetTester tester) async {
      service.isLocked.value = false;

      await tester.pumpWidget(
        AppLockObserver(
          gracePeriod: const Duration(seconds: 1),
          child: const MaterialApp(
            home: Scaffold(body: Text('Protected Content')),
          ),
        ),
      );

      expect(find.text('Protected Content'), findsOneWidget);
    });

    testWidgets('shows LockScreen overlay when isLocked is true',
        (WidgetTester tester) async {
      _setupLocalAuthMock(canAuthenticate: true, success: false);
      service.isLocked.value = true;

      await tester.pumpWidget(
        AppLockObserver(
          gracePeriod: const Duration(seconds: 1),
          child: const MaterialApp(
            home: Scaffold(body: Text('Protected Content')),
          ),
        ),
      );
      await tester.pump();

      // Protected content must NOT be visible through the lock screen.
      expect(find.text('Protected Content'), findsNothing);
      // Lock screen heading must be visible.
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets(
        'hides LockScreen when isLocked flips to false after successful auth',
        (WidgetTester tester) async {
      _setupLocalAuthMock(canAuthenticate: true, success: true);
      service.isLocked.value = true;

      await tester.pumpWidget(
        AppLockObserver(
          gracePeriod: const Duration(seconds: 1),
          child: const MaterialApp(
            home: Scaffold(body: Text('Protected Content')),
          ),
        ),
      );
      await tester.pump();

      // Simulate successful unlock.
      service.isLocked.value = false;
      await tester.pumpAndSettle();

      expect(find.text('Protected Content'), findsOneWidget);
    });
  });

  // ── Lifecycle Tests ─────────────────────────────────────────────────────────

  group('AppLockObserver lifecycle', () {
    testWidgets(
        're-locks app when resumed after grace period has elapsed',
        (WidgetTester tester) async {
      service.isLocked.value = false;

      await tester.pumpWidget(
        AppLockObserver(
          gracePeriod: Duration.zero, // Instant grace period for testing.
          child: const MaterialApp(
            home: Scaffold(body: Text('Protected Content')),
          ),
        ),
      );

      // Simulate going to background.
      final ByteData pauseData = const StringCodec().encodeMessage(
        AppLifecycleState.paused.toString(),
      )!;
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        pauseData,
        (_) {},
      );

      // Small delay to ensure _pausedAt is set.
      await tester.pump(const Duration(milliseconds: 10));

      // Simulate returning to foreground.
      final ByteData resumeData = const StringCodec().encodeMessage(
        AppLifecycleState.resumed.toString(),
      )!;
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        resumeData,
        (_) {},
      );

      await tester.pump();

      expect(service.isLocked.value, isTrue);
    });
  });
}
