import 'dart:async';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/automation/sms_parser/bank_sms_parser.dart';

/// Service interface and handler for incoming bank push notifications and SMS streams.
class NotificationListenerService {
  NotificationListenerService({BankSmsParser? parser})
      : _parser = parser ?? const BankSmsParser();

  final BankSmsParser _parser;
  final StreamController<ParsedTransaction> _transactionStreamController =
      StreamController<ParsedTransaction>.broadcast();

  Stream<ParsedTransaction> get onTransactionDetected =>
      _transactionStreamController.stream;

  /// Ingests incoming notification/SMS payload and parses if applicable.
  void handleIncomingMessage(String text, {DateTime? receivedAt}) {
    final ParsedTransaction? parsed = _parser.parse(text, receivedAt: receivedAt);
    if (parsed != null) {
      _transactionStreamController.add(parsed);
    }
  }

  void dispose() {
    _transactionStreamController.close();
  }
}
