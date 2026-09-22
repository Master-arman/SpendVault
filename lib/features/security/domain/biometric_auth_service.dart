import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Result of an authentication attempt.
enum AuthResult {
  success,
  failure,
  notAvailable,
  error,
}

/// Singleton service that wraps [LocalAuthentication] and exposes a reactive
/// [isLocked] notifier so any widget in the tree can react to lock-state
/// changes without requiring direct dependency injection.
class BiometricAuthService {
  BiometricAuthService._();

  /// The single shared instance.
  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// `true` when the app is locked and the user must authenticate to proceed.
  final ValueNotifier<bool> isLocked = ValueNotifier<bool>(false);

  // ── Capability ─────────────────────────────────────────────────────────────

  /// Returns `true` when the device supports biometric or device-credential
  /// authentication and at least one biometric is enrolled.
  Future<bool> isAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (fingerprint, face, iris).
  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  // ── State Helpers ───────────────────────────────────────────────────────────

  /// Marks the app as locked. The [LockScreen] listens to [isLocked] and will
  /// appear automatically.
  void lock() {
    isLocked.value = true;
  }

  /// Marks the app as unlocked.
  void unlock() {
    isLocked.value = false;
  }

  void _unlock() => unlock();

  // ── Authentication ──────────────────────────────────────────────────────────

  /// Prompts the user to authenticate using biometrics or device credentials.
  ///
  /// - [stickyAuth] keeps the prompt alive when the app loses focus briefly
  ///   (e.g. the user opens the notification shade).
  /// - [biometricOnly] is `false` so the user can fall back to PIN/pattern.
  ///
  /// Returns an [AuthResult] indicating the outcome.
  Future<AuthResult> authenticate() async {
    final bool available = await isAvailable();
    if (!available) {
      return AuthResult.notAvailable;
    }

    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Unlock SpendVault to access your finances',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        unlock();
        return AuthResult.success;
      } else {
        return AuthResult.failure;
      }
    } catch (_) {
      return AuthResult.error;
    }
  }

  /// Cancels any in-progress authentication dialog (e.g. when app is closed).
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {
      // Ignore if no active session.
    }
  }
}
