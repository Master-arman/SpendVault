import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility to debounce rapid action calls, preventing redundant processing.
class Debouncer {
  Debouncer({int? milliseconds, Duration? duration})
      : duration = duration ?? Duration(milliseconds: milliseconds ?? 300);

  final Duration duration;
  Timer? _timer;

  /// Runs the provided [action] after [duration] has elapsed without new calls.
  void run(VoidCallback action) {
    cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any active pending debounce timers.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Returns true if a timer is currently active.
  bool get isRunning => _timer?.isActive ?? false;

  /// Disposes of the debouncer.
  void dispose() {
    cancel();
  }
}
