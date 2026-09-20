import 'dart:async';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/automation/sms_parser/bank_sms_parser.dart';

/// Repository interface and implementation for Android Notification Listener Service Bridge.
class NotificationListenerRepo {
  NotificationListenerRepo({
    BankSmsParser? parser,
    bool initialPermissionGranted = false,
  })  : _parser = parser ?? const BankSmsParser(),
        _mockPermissionGranted = initialPermissionGranted;

  final BankSmsParser _parser;
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
  void onNotificationReceived({
    required String title,
    required String content,
    String? packageName,
    DateTime? timestamp,
  }) {
    if (!_isListening) return;

    final String fullText = '$title $content';
    final ParsedTransaction? parsed = _parser.parse(
      fullText,
      receivedAt: timestamp ?? DateTime.now(),
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
