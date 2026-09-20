import 'dart:async';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/automation/domain/notification_parser.dart';
import 'package:finance_app/features/automation/domain/payment_app_filter.dart';
import 'package:finance_app/features/automation/sms_parser/bank_sms_parser.dart';

/// Repository interface and implementation for Android Notification Listener Service Bridge.
class NotificationListenerRepo {
  NotificationListenerRepo({
    BankSmsParser? parser,
    NotificationParser? notificationParser,
    bool initialPermissionGranted = false,
  })  : _parser = parser ?? const BankSmsParser(),
        _notificationParser = notificationParser ?? const NotificationParser(),
        _mockPermissionGranted = initialPermissionGranted;

  final BankSmsParser _parser;
  final NotificationParser _notificationParser;
  final StreamController<ParsedTransaction> _transactionStreamController =
      StreamController<ParsedTransaction>.broadcast();

  bool _isListening = false;
  bool _mockPermissionGranted;

  Stream<ParsedTransaction> get onTransactionReceived =>
      _transactionStreamController.stream;

  bool get isListening => _isListening;

  /// Checks if Android Notification Listener permission is granted.
  Future<bool> isPermissionGranted() async {
    return _mockPermissionGranted;
  }

  /// Requests notification access permission from user.
  Future<bool> requestPermission() async {
    _mockPermissionGranted = true;
    return _mockPermissionGranted;
  }

  /// Starts listening to notification streams.
  Future<void> startListening() async {
    _isListening = true;
  }

  /// Processes raw incoming notification payload and parses financial transactions.
  /// If [packageName] is provided, only whitelisted payment apps are accepted.
  void onNotificationReceived({
    required String title,
    required String content,
    String? packageName,
    DateTime? timestamp,
  }) {
    if (!_isListening) return;

    // Filter by payment app whitelist if package identifier is provided
    if (packageName != null && !PaymentAppFilter.isWhitelisted(packageName)) {
      return;
    }

    final String fullText = '$title $content';
    final DateTime now = timestamp ?? DateTime.now();

    // 1. Try deterministic notification parser
    ParsedTransaction? parsed = _notificationParser.parse(
      fullText,
      packageName: packageName,
      timestamp: now,
    );

    // 2. Fallback to general bank SMS parser
    parsed ??= _parser.parse(
      fullText,
      receivedAt: now,
    );

    if (parsed != null) {
      _transactionStreamController.add(parsed);
    }
  }

  /// Stops listening to notification streams.
  Future<void> stopListening() async {
    _isListening = false;
  }

  void dispose() {
    _isListening = false;
    _transactionStreamController.close();
  }
}
