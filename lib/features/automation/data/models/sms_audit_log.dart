import 'package:isar/isar.dart';

part 'sms_audit_log.g.dart';

/// Execution state representing the outcome of incoming notification/SMS processing.
enum AuditExecutionState {
  parsed,
  ignored,
  duplicate,
}

/// Audit log record for incoming SMS and push notification financial automation events.
@collection
class SmsAuditLog {
  Id id = Isar.autoIncrement;

  /// The raw unparsed text payload received from the Android notification or SMS.
  late String rawPayload;

  /// The parsed monetary transaction amount, or null if unparsed/ignored.
  double? parsedAmount;

  /// The detected payee, merchant, or beneficiary name.
  String? detectedPayee;

  /// Source Android application package identifier or bank SMS sender code.
  String? sourcePackageOrSender;

  /// Processing outcome execution state: parsed, ignored, or duplicate.
  @Enumerated(EnumType.name)
  AuditExecutionState executionState = AuditExecutionState.ignored;

  /// Timestamp when the raw payload was ingested.
  DateTime timestamp = DateTime.now();

  /// 15-minute slot deduplication cryptographic MD5 hash.
  @Index()
  String? deduplicationHash;

  /// Automatically inferred category from dictionary rules.
  String? inferredCategory;
}
