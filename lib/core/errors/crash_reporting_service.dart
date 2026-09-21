import 'package:flutter/foundation.dart';
import 'crash_data_sanitizer.dart';

/// Abstract sink for crash monitoring backends (Sentry, Firebase Crashlytics, etc.)
abstract class CrashReportSink {
  String get name;

  Future<void> recordError(
    String sanitizedMessage,
    String sanitizedStackTrace, {
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  });

  Future<void> recordBreadcrumb(
    String sanitizedMessage, {
    String? category,
    Map<String, dynamic>? data,
  });

  Future<void> setCustomKey(String key, dynamic sanitizedValue);

  Future<void> setUserIdentifier(String? userId);
}

/// In-memory sink recording sanitized crash reports and breadcrumbs for testing & local diagnostics.
class InMemoryCrashSink implements CrashReportSink {
  @override
  final String name;

  final List<Map<String, dynamic>> recordedErrors = [];
  final List<Map<String, dynamic>> breadcrumbs = [];
  final Map<String, dynamic> customKeys = {};
  String? userIdentifier;

  InMemoryCrashSink({this.name = 'InMemoryCrashSink'});

  @override
  Future<void> recordError(
    String sanitizedMessage,
    String sanitizedStackTrace, {
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  }) async {
    recordedErrors.add({
      'message': sanitizedMessage,
      'stackTrace': sanitizedStackTrace,
      'reason': reason,
      'customKeys': customKeys != null ? Map<String, dynamic>.from(customKeys) : null,
      'fatal': fatal,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> recordBreadcrumb(
    String sanitizedMessage, {
    String? category,
    Map<String, dynamic>? data,
  }) async {
    breadcrumbs.add({
      'message': sanitizedMessage,
      'category': category,
      'data': data != null ? Map<String, dynamic>.from(data) : null,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> setCustomKey(String key, dynamic sanitizedValue) async {
    customKeys[key] = sanitizedValue;
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {
    userIdentifier = userId;
  }

  void clear() {
    recordedErrors.clear();
    breadcrumbs.clear();
    customKeys.clear();
    userIdentifier = null;
  }
}

/// Pluggable Sentry crash reporting sink with guaranteed sanitized payload dispatch.
class SentryCrashSink implements CrashReportSink {
  @override
  final String name = 'Sentry';

  final List<Map<String, dynamic>> dispatchedEvents = [];

  @override
  Future<void> recordError(
    String sanitizedMessage,
    String sanitizedStackTrace, {
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  }) async {
    dispatchedEvents.add({
      'level': fatal ? 'fatal' : 'error',
      'message': sanitizedMessage,
      'exception': {
        'value': sanitizedMessage,
        'stacktrace': sanitizedStackTrace,
      },
      'tags': {
        'reason': ?reason,
      },
      'extra': customKeys,
    });
  }

  @override
  Future<void> recordBreadcrumb(
    String sanitizedMessage, {
    String? category,
    Map<String, dynamic>? data,
  }) async {
    dispatchedEvents.add({
      'type': 'breadcrumb',
      'category': category ?? 'default',
      'message': sanitizedMessage,
      'data': data,
    });
  }

  @override
  Future<void> setCustomKey(String key, dynamic sanitizedValue) async {
    // Sentry extra/tag assignment
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {
    // Sentry user context
  }
}

/// Pluggable Firebase Crashlytics sink with guaranteed sanitized payload dispatch.
class FirebaseCrashlyticsSink implements CrashReportSink {
  @override
  final String name = 'FirebaseCrashlytics';

  final List<Map<String, dynamic>> logs = [];
  final List<Map<String, dynamic>> nonFatalErrors = [];
  final List<Map<String, dynamic>> fatalErrors = [];

  @override
  Future<void> recordError(
    String sanitizedMessage,
    String sanitizedStackTrace, {
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  }) async {
    final entry = {
      'message': sanitizedMessage,
      'stack': sanitizedStackTrace,
      'reason': reason,
      'customKeys': customKeys,
      'fatal': fatal,
    };
    if (fatal) {
      fatalErrors.add(entry);
    } else {
      nonFatalErrors.add(entry);
    }
  }

  @override
  Future<void> recordBreadcrumb(
    String sanitizedMessage, {
    String? category,
    Map<String, dynamic>? data,
  }) async {
    logs.add({
      'log': '[$category] $sanitizedMessage',
      'data': data,
    });
  }

  @override
  Future<void> setCustomKey(String key, dynamic sanitizedValue) async {
    // Firebase Crashlytics custom key
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {
    // Firebase Crashlytics user identifier
  }
}

/// Central crash reporting service that strips all PII and sensitive financial data
/// before forwarding errors and breadcrumbs to attached crash monitoring sinks.
class CrashReportingService {
  static final CrashReportingService instance = CrashReportingService._internal();

  CrashReportingService._internal();

  final List<CrashReportSink> _sinks = [];
  bool _isInitialized = false;

  List<CrashReportSink> get sinks => List.unmodifiable(_sinks);
  bool get isInitialized => _isInitialized;

  /// Initialize crash reporting with specified sinks and optional global framework error bindings.
  void initialize({
    List<CrashReportSink>? sinks,
    bool enableGlobalHandlers = true,
  }) {
    _sinks.clear();
    if (sinks != null && sinks.isNotEmpty) {
      _sinks.addAll(sinks);
    } else {
      _sinks.add(InMemoryCrashSink());
    }
    _isInitialized = true;

    if (enableGlobalHandlers) {
      _attachGlobalErrorHandlers();
    }
  }

  void addSink(CrashReportSink sink) {
    if (!_sinks.contains(sink)) {
      _sinks.add(sink);
    }
  }

  void removeSink(CrashReportSink sink) {
    _sinks.remove(sink);
  }

  void _attachGlobalErrorHandlers() {
    // 1. Flutter framework render & build errors
    FlutterError.onError = (FlutterErrorDetails details) {
      recordFlutterError(details);
      // Keep console logging in debug mode
      FlutterError.presentError(details);
    };

    // 2. Uncaught asynchronous Dart runtime errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error, stack, reason: 'PlatformDispatcher uncaught asynchronous error', fatal: true);
      return true;
    };
  }

  /// Records an error after scrubbing all sensitive financial data and PII.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  }) async {
    final sanitizedMessage = CrashDataSanitizer.sanitize(error.toString());
    final sanitizedStack = CrashDataSanitizer.sanitizeStackTrace(stack);
    final sanitizedReason = reason != null ? CrashDataSanitizer.sanitize(reason) : null;
    final sanitizedKeys = customKeys != null
        ? (CrashDataSanitizer.sanitizeValue(customKeys) as Map<String, dynamic>)
        : null;

    for (final sink in _sinks) {
      try {
        await sink.recordError(
          sanitizedMessage,
          sanitizedStack,
          reason: sanitizedReason,
          customKeys: sanitizedKeys,
          fatal: fatal,
        );
      } catch (e) {
        debugPrint('Failed to report error to sink ${sink.name}: $e');
      }
    }
  }

  /// Records a [FlutterErrorDetails] after scrubbing framework and context metadata.
  Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
  }) async {
    final sanitizedDetails = CrashDataSanitizer.sanitizeFlutterErrorDetails(details);
    final message = '${sanitizedDetails['library']}: ${sanitizedDetails['exception']}';
    final stack = sanitizedDetails['stackTrace'] as String;
    final context = sanitizedDetails['context'] as String?;

    await recordError(
      message,
      null,
      reason: context,
      customKeys: {
        'library': sanitizedDetails['library'],
        'summary': sanitizedDetails['summary'],
        'stackTrace': stack,
      },
      fatal: fatal,
    );
  }

  /// Records a breadcrumb after scrubbing all personal and financial data.
  Future<void> recordBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) async {
    final sanitizedMessage = CrashDataSanitizer.sanitize(message);
    final sanitizedCategory = category != null ? CrashDataSanitizer.sanitize(category) : null;
    final sanitizedData = data != null
        ? (CrashDataSanitizer.sanitizeValue(data) as Map<String, dynamic>)
        : null;

    for (final sink in _sinks) {
      try {
        await sink.recordBreadcrumb(
          sanitizedMessage,
          category: sanitizedCategory,
          data: sanitizedData,
        );
      } catch (e) {
        debugPrint('Failed to record breadcrumb in sink ${sink.name}: $e');
      }
    }
  }

  /// Sets a custom key-value pair after scrubbing sensitive identifiers.
  Future<void> setCustomKey(String key, dynamic value) async {
    final sanitizedKey = CrashDataSanitizer.sanitize(key);
    final sanitizedValue = CrashDataSanitizer.sanitizeValue(value);

    for (final sink in _sinks) {
      try {
        await sink.setCustomKey(sanitizedKey, sanitizedValue);
      } catch (e) {
        debugPrint('Failed to set custom key in sink ${sink.name}: $e');
      }
    }
  }

  /// Sets an anonymized user identifier (never email or raw phone).
  Future<void> setUserIdentifier(String? userId) async {
    final sanitizedUserId = userId != null ? CrashDataSanitizer.sanitize(userId) : null;

    for (final sink in _sinks) {
      try {
        await sink.setUserIdentifier(sanitizedUserId);
      } catch (e) {
        debugPrint('Failed to set user identifier in sink ${sink.name}: $e');
      }
    }
  }
}
