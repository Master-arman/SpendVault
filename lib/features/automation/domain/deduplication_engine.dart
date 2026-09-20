import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:isar/isar.dart';

/// Cryptographic Deduplication Engine for transaction events.
/// Drops duplicate transactions arriving via both SMS and push notification
/// within a rolling 15-minute window.
class DeduplicationEngine {
  DeduplicationEngine({this.isar});

  final Isar? isar;
  final Set<String> _inMemoryHashCache = <String>{};

  /// Computes a deterministic MD5 hash for a transaction slot within a 15-minute window.
  static String generateHash(double amount, String payee, DateTime time) {
    final int cleanTime = time.millisecondsSinceEpoch ~/ (1000 * 60 * 15); // 15-minute slot
    final String payload = '$amount-${payee.toLowerCase().trim()}-$cleanTime';
    return md5.convert(utf8.encode(payload)).toString();
  }

  /// Checks whether a transaction with the computed hash already exists in Isar or local cache.
  Future<bool> isDuplicate({
    required double amount,
    required String payee,
    required DateTime time,
    Isar? customIsar,
  }) async {
    final String hash = generateHash(amount, payee, time);
    return isHashDuplicate(hash, customIsar: customIsar);
  }

  /// Checks if a pre-computed hash exists in database or memory.
  Future<bool> isHashDuplicate(String hash, {Isar? customIsar}) async {
    final targetIsar = customIsar ?? isar;

    // 1. Check database if Isar is available
    if (targetIsar != null) {
      final Transaction? existing = await targetIsar.transactions
          .filter()
          .deduplicationHashEqualTo(hash)
          .findFirst();

      if (existing != null) {
        return true;
      }
    }

    // 2. Check in-memory cache
    return _inMemoryHashCache.contains(hash);
  }

  /// Evaluates an incoming transaction:
  /// - Computes and populates its [deduplicationHash]
  /// - If a duplicate is detected, returns `null` (silently dropped)
  /// - If new, records hash in cache and returns transaction
  Future<Transaction?> processOrDrop(
    Transaction transaction, {
    String? merchantOrPayee,
    Isar? customIsar,
  }) async {
    final String payee = merchantOrPayee ?? transaction.note ?? 'Unknown';
    final String hash = generateHash(transaction.amount, payee, transaction.timestamp);

    final bool duplicate = await isHashDuplicate(hash, customIsar: customIsar);
    if (duplicate) {
      // Duplicate event detected within 15-minute window: dropped silently
      return null;
    }

    // Register hash in memory cache
    _inMemoryHashCache.add(hash);
    transaction.deduplicationHash = hash;
    return transaction;
  }

  /// Clears the in-memory deduplication cache.
  void clearMemoryCache() {
    _inMemoryHashCache.clear();
  }
}
