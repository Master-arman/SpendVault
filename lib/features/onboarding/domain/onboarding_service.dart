import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Manages first-launch detection via a lightweight sentinel file stored in the
/// app's support directory. No external packages required — uses [path_provider]
/// which is already a project dependency.
class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();

  static const String _sentinelFileName = 'onboarding_complete';

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<File> _sentinelFile() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_sentinelFileName');
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns `true` if the user has already completed the onboarding flow.
  Future<bool> hasSeenOnboarding() async {
    try {
      final File file = await _sentinelFile();
      return file.existsSync();
    } catch (_) {
      // If we can't read the file system, skip onboarding gracefully.
      return true;
    }
  }

  /// Writes the sentinel file to mark onboarding as completed.
  Future<void> markOnboardingSeen() async {
    try {
      final File file = await _sentinelFile();
      if (!file.existsSync()) {
        await file.create(recursive: true);
      }
    } catch (_) {
      // Non-fatal: worst case, onboarding re-shows on next launch.
    }
  }

  /// Deletes the sentinel file, forcing onboarding to show on next launch.
  /// Useful for testing or when the user resets the app.
  Future<void> resetOnboarding() async {
    try {
      final File file = await _sentinelFile();
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
