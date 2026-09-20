import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service responsible for managing first-boot discovery tour status.
/// Uses a lightweight sentinel file in the app support directory.
class FeatureTourService {
  FeatureTourService._();

  static final FeatureTourService instance = FeatureTourService._();

  static const String _sentinelFileName = 'feature_tour_complete';

  /// In-memory testing override to bypass disk I/O in automated tests.
  @visibleForTesting
  bool? testingOverrideHasSeen;

  Future<File> _sentinelFile() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_sentinelFileName');
  }

  /// Returns `true` if the feature discovery tour has already been viewed/completed.
  Future<bool> hasSeenTour() async {
    if (testingOverrideHasSeen != null) {
      return testingOverrideHasSeen!;
    }
    try {
      final File file = await _sentinelFile();
      return file.existsSync();
    } catch (_) {
      return true; // Failsafe: avoid trapping users in case of filesystem issues
    }
  }

  /// Marks the feature discovery tour as complete.
  Future<void> markTourSeen() async {
    if (testingOverrideHasSeen != null) {
      testingOverrideHasSeen = true;
      return;
    }
    try {
      final File file = await _sentinelFile();
      if (!file.existsSync()) {
        await file.create(recursive: true);
      }
    } catch (_) {}
  }

  /// Resets the tour completion state so the tour can trigger again.
  Future<void> resetTour() async {
    if (testingOverrideHasSeen != null) {
      testingOverrideHasSeen = false;
      return;
    }
    try {
      final File file = await _sentinelFile();
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
