import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility for secure cryptographic hashing, checksum verification, and data masking.
class SecurityHash {
  const SecurityHash._();

  /// Generates a SHA-256 hex digest of the provided [input] string.
  static String sha256Hash(String input) {
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates an HMAC-SHA256 signature using a secret key and input string.
  static String hmacSha256(String key, String input) {
    final Hmac hmac = Hmac(sha256, utf8.encode(key));
    final Digest digest = hmac.convert(utf8.encode(input));
    return digest.toString();
  }

  /// Creates a deterministic hash fingerprint for an SMS/transaction message
  /// to facilitate deduplication without storing cleartext unmasked body text.
  static String transactionFingerprint({
    required double amount,
    required String sender,
    required DateTime timestamp,
    String? accountEnding,
  }) {
    final String raw = '${amount.toStringAsFixed(2)}|${sender.trim().toLowerCase()}|${timestamp.toIso8601String()}|${accountEnding ?? ""}';
    return sha256Hash(raw);
  }

  /// Safely masks an account number (e.g. ************4321).
  static String maskAccount(String accountNumber, {int visibleDigits = 4}) {
    final String trimmed = accountNumber.replaceAll(RegExp(r'\s+'), '');
    if (trimmed.length <= visibleDigits) {
      return trimmed;
    }
    final String mask = '*' * (trimmed.length - visibleDigits);
    final String tail = trimmed.substring(trimmed.length - visibleDigits);
    return '$mask$tail';
  }
}
