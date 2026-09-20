import 'package:finance_app/features/security/domain/biometric_auth_service.dart';
import 'package:finance_app/features/security/presentation/screens/lock_screen.dart';
import 'package:flutter/material.dart';

/// A [StatefulWidget] that wraps the entire app widget tree and observes
/// [AppLifecycleState] changes to automatically re-lock the app whenever it
/// returns from the background.
///
/// ### Grace Period
/// A configurable [gracePeriod] (default 3 seconds) prevents false re-locks
/// that occur when the user briefly dismisses a notification shade or
/// permission dialog without truly leaving the app.
///
/// ### Usage
/// Wrap [MaterialApp] (or any top-level widget) with [AppLockObserver]:
/// ```dart
/// AppLockObserver(child: MaterialApp(...))
/// ```
class AppLockObserver extends StatefulWidget {
  const AppLockObserver({
    super.key,
    required this.child,
    this.gracePeriod = const Duration(seconds: 3),
  });

  /// The widget subtree to protect (typically [MaterialApp]).
  final Widget child;

  /// How long the app may be in the background before it is locked on return.
  final Duration gracePeriod;

  @override
  State<AppLockObserver> createState() => _AppLockObserverState();
}

class _AppLockObserverState extends State<AppLockObserver>
    with WidgetsBindingObserver {
  final BiometricAuthService _authService = BiometricAuthService.instance;

  /// Timestamp when the app entered the background.
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // Record the moment the app left the foreground.
        _pausedAt = DateTime.now();

      case AppLifecycleState.resumed:
        _handleResume();

      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Cancel any in-progress biometric prompt cleanly.
        _authService.cancelAuthentication();
    }
  }

  void _handleResume() {
    if (_pausedAt == null) return;

    final Duration elapsed = DateTime.now().difference(_pausedAt!);
    _pausedAt = null;

    // Only lock if the app was in the background longer than the grace period.
    if (elapsed >= widget.gracePeriod) {
      _authService.lock();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _authService.isLocked,
      builder: (BuildContext context, bool locked, Widget? child) {
        // When locked, render LockScreen on top of (but replacing) the tree so
        // no app content is visible in the task switcher thumbnail.
        if (locked) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const LockScreen(),
          );
        }
        return child!;
      },
      child: widget.child,
    );
  }
}
