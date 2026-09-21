import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/utils/security_hash.dart';
import 'package:finance_app/features/accounts/data/models/account.dart';
import 'package:finance_app/features/analytics/data/models/category_budget.dart';
import 'package:finance_app/features/automation/data/models/sms_audit_log.dart';
import 'package:finance_app/features/categories/data/models/category.dart';
import 'package:finance_app/features/subscriptions/data/models/subscription.dart';
import 'package:finance_app/features/transactions/data/models/transaction.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:share_plus/share_plus.dart';

/// Exception thrown when backup integrity validation or decryption fails.
class RestoreValidationException implements Exception {
  final String message;
  const RestoreValidationException(this.message);

  @override
  String toString() => 'RestoreValidationException: $message';
}

/// Result summary returned after a successful restoration or validation.
class RestoreResult {
  final bool isSuccess;
  final String message;
  final Map<String, int> restoredCounts;

  const RestoreResult({
    required this.isSuccess,
    required this.message,
    this.restoredCounts = const {},
  });

  @override
  String toString() => 'RestoreResult(isSuccess: $isSuccess, message: $message, counts: $restoredCounts)';
}

/// Abstract bridge for sharing backup files (supports unit testing).
abstract class IBackupShareBridge {
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
  });
}

/// Default production share bridge invoking [Share.shareXFiles].
class DefaultBackupShareBridge implements IBackupShareBridge {
  const DefaultBackupShareBridge();

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
  }) {
    return Share.shareXFiles(
      files,
      text: text,
      subject: subject,
    );
  }
}

/// Phase 45 & Phase 46: AES-256-GCM Encrypted Backup & Checksum Integrity Restoration Engine.
///
/// Encryption Scheme:
/// 1. Serializes the entire Isar database collections to a structured JSON string.
/// 2. Derives an AES-256 key from a user-supplied password using PBKDF2 (100,000 iterations).
/// 3. Encrypts payload with AES-GCM-256 via [encrypt] package.
/// 4. Generates SHA-256 integrity checksums for ciphertext and cleartext payload.
/// 5. Writes the output file with the `.enc` extension to the app's cache directory before sharing.
///
/// Restoration & Validation Scheme (Phase 46):
/// 1. Validates file SHA-256 checksum and internal ciphertext integrity.
/// 2. Decrypts and authenticates AES-256-GCM payload with user password.
/// 3. Validates manifest structure and JSON schema.
/// 4. Aborts immediately and alerts without touching or overwriting database if any check fails.
/// 5. Atomically clears and restores all Isar collections and relationships in a single write transaction.
class BackupService {
  const BackupService._();

  static IBackupShareBridge _shareBridge = const DefaultBackupShareBridge();

  /// Overrides the share bridge for unit testing.
  static void setShareBridgeForTesting(IBackupShareBridge? bridge) {
    _shareBridge = bridge ?? const DefaultBackupShareBridge();
  }

  /// Generates cryptographically strong random bytes for salt and initialization vectors.
  static Uint8List generateRandomBytes(int length) {
    final Random random = Random.secure();
    final Uint8List bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Derives a 256-bit encryption key using PBKDF2 with HMAC-SHA256 (100,000 iterations).
  static Uint8List deriveKey(
    String password,
    Uint8List salt, {
    int iterations = 100000,
    int keyLength = 32,
  }) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Serializes the entire active Isar database into a comprehensive JSON string.
  static Future<String> serializeIsarDatabase(Isar isar) async {
    final List<Account> accounts = await isar.accounts.where().findAll();
    final List<Category> categories = await isar.categorys.where().findAll();
    final List<Transaction> transactions = await isar.transactions.where().findAll();
    final List<Subscription> subscriptions = await isar.subscriptions.where().findAll();
    final List<CategoryBudget> budgets = await isar.categoryBudgets.where().findAll();
    final List<SmsAuditLog> smsLogs = await isar.smsAuditLogs.where().findAll();

    final Map<String, dynamic> backupMap = {
      'manifest': {
        'app': AppConstants.appName,
        'version': AppConstants.appVersion,
        'schemaVersion': 1,
        'exportTimestamp': DateTime.now().toIso8601String(),
        'entityCounts': {
          'accounts': accounts.length,
          'categories': categories.length,
          'transactions': transactions.length,
          'subscriptions': subscriptions.length,
          'budgets': budgets.length,
          'smsLogs': smsLogs.length,
        },
      },
      'accounts': accounts.map((a) => {
        'id': a.id,
        'name': a.name,
        'last4Digits': a.last4Digits,
        'balance': a.currentBalance,
        'type': a.type.name,
        'isDefault': a.isDefault,
        'colorHex': a.colorHex,
      }).toList(),
      'categories': categories.map((c) => {
        'id': c.id,
        'name': c.name,
        'iconCodePoint': c.iconCodePoint,
        'colorHex': c.colorHex,
        'budgetLimit': c.budgetLimit,
      }).toList(),
      'transactions': transactions.map((t) => {
        'id': t.id,
        'amount': t.amount,
        'type': t.type.name,
        'timestamp': t.timestamp.toIso8601String(),
        'sourceAccountId': t.sourceAccount.value?.id,
        'destinationAccountId': t.destinationAccount.value?.id,
        'categoryId': t.category.value?.id,
        'note': t.note,
        'receiptLocalPath': t.receiptLocalPath,
        'tags': t.tags,
        'deduplicationHash': t.deduplicationHash,
      }).toList(),
      'subscriptions': subscriptions.map((s) => {
        'id': s.id,
        'name': s.name,
        'amount': s.amount,
        'cycle': s.cycle.name,
        'nextBillingDate': s.nextBillingDate.toIso8601String(),
        'reminderDaysBefore': s.reminderDaysBefore,
        'isActive': s.isActive,
        'autoLogOnRenewal': s.autoLogOnRenewal,
        'categoryId': s.category.value?.id,
        'accountId': s.account.value?.id,
      }).toList(),
      'budgets': budgets.map((b) => {
        'id': b.id,
        'monthlyLimit': b.monthlyLimit,
        'month': b.month,
        'year': b.year,
        'categoryId': b.category.value?.id,
      }).toList(),
      'smsLogs': smsLogs.map((l) => {
        'id': l.id,
        'rawPayload': l.rawPayload,
        'parsedAmount': l.parsedAmount,
        'detectedPayee': l.detectedPayee,
        'sourcePackageOrSender': l.sourcePackageOrSender,
        'executionState': l.executionState.name,
        'timestamp': l.timestamp.toIso8601String(),
        'deduplicationHash': l.deduplicationHash,
        'inferredCategory': l.inferredCategory,
      }).toList(),
    };

    return jsonEncode(backupMap);
  }

  /// Encrypts a JSON payload using PBKDF2 (100,000 iterations) + AES-256-GCM.
  /// Embeds SHA-256 integrity checksums inside the envelope.
  static String encryptPayload({
    required String jsonPayload,
    required String password,
    Uint8List? salt,
    enc.IV? iv,
    int iterations = 100000,
  }) {
    final Uint8List effectiveSalt = salt ?? generateRandomBytes(16);
    final enc.IV effectiveIV = iv ?? enc.IV.fromSecureRandom(12);
    final Uint8List derivedKey = deriveKey(
      password,
      effectiveSalt,
      iterations: iterations,
      keyLength: 32,
    );

    final encrypter = enc.Encrypter(
      enc.AES(
        enc.Key(derivedKey),
        mode: enc.AESMode.gcm,
      ),
    );

    final enc.Encrypted encrypted = encrypter.encrypt(
      jsonPayload,
      iv: effectiveIV,
    );

    final String ciphertext = encrypted.base64;
    final String checksum = SecurityHash.sha256Hash(ciphertext);
    final String payloadChecksum = SecurityHash.sha256Hash(jsonPayload);

    final Map<String, dynamic> envelope = {
      'version': 1,
      'cipher': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': iterations,
      'salt': base64Encode(effectiveSalt),
      'iv': base64Encode(effectiveIV.bytes),
      'ciphertext': ciphertext,
      'checksum': checksum,
      'payloadChecksum': payloadChecksum,
    };

    return jsonEncode(envelope);
  }

  /// Decrypts a backup envelope using user-supplied password.
  static String decryptPayload({
    required String encryptedEnvelopeJson,
    required String password,
  }) {
    final Map<String, dynamic> envelope =
        jsonDecode(encryptedEnvelopeJson) as Map<String, dynamic>;

    final int iterations = envelope['iterations'] as int? ?? 100000;
    final Uint8List salt = base64Decode(envelope['salt'] as String);
    final Uint8List ivBytes = base64Decode(envelope['iv'] as String);
    final String ciphertextBase64 = envelope['ciphertext'] as String;

    final Uint8List derivedKey = deriveKey(
      password,
      salt,
      iterations: iterations,
      keyLength: 32,
    );

    final encrypter = enc.Encrypter(
      enc.AES(
        enc.Key(derivedKey),
        mode: enc.AESMode.gcm,
      ),
    );

    return encrypter.decrypt64(
      ciphertextBase64,
      iv: enc.IV(ivBytes),
    );
  }

  /// Validates the file's SHA-256 checksum and tests decryption under [password].
  ///
  /// Returns the validated, decrypted JSON payload map if successful.
  /// Throws [RestoreValidationException] and aborts if any validation step fails.
  static Map<String, dynamic> validateAndDecryptBackup({
    required String encryptedEnvelopeJson,
    required String password,
    String? expectedFileChecksum,
  }) {
    // 1. External SHA-256 Checksum Validation (if provided)
    if (expectedFileChecksum != null && expectedFileChecksum.trim().isNotEmpty) {
      final String actualChecksum = SecurityHash.sha256Hash(encryptedEnvelopeJson);
      final String trimmedExpected = expectedFileChecksum.trim();
      if (actualChecksum.toLowerCase() != trimmedExpected.toLowerCase()) {
        throw RestoreValidationException(
          'File SHA-256 checksum verification failed. Expected: $trimmedExpected, Actual: $actualChecksum. Backup may be corrupted or modified.',
        );
      }
    }

    // 2. Parse Envelope Structure
    final dynamic decodedEnvelope;
    try {
      decodedEnvelope = jsonDecode(encryptedEnvelopeJson);
    } catch (e) {
      throw RestoreValidationException('Malformed backup file: Not a valid JSON envelope ($e).');
    }

    if (decodedEnvelope is! Map<String, dynamic>) {
      throw const RestoreValidationException('Invalid backup envelope structure.');
    }

    final String? ciphertext = decodedEnvelope['ciphertext'] as String?;
    if (ciphertext == null || ciphertext.isEmpty) {
      throw const RestoreValidationException('Invalid backup envelope: Missing ciphertext payload.');
    }

    // 3. Ciphertext Checksum Validation (if envelope contains checksum)
    final String? expectedCiphertextChecksum = decodedEnvelope['checksum'] as String?;
    if (expectedCiphertextChecksum != null && expectedCiphertextChecksum.isNotEmpty) {
      final String actualCiphertextChecksum = SecurityHash.sha256Hash(ciphertext);
      if (actualCiphertextChecksum.toLowerCase() != expectedCiphertextChecksum.toLowerCase()) {
        throw const RestoreValidationException(
          'Encrypted data integrity checksum mismatch. Ciphertext has been tampered with or corrupted.',
        );
      }
    }

    // 4. Decrypt under supplied password
    final String decryptedJson;
    try {
      decryptedJson = decryptPayload(
        encryptedEnvelopeJson: encryptedEnvelopeJson,
        password: password,
      );
    } catch (e) {
      throw RestoreValidationException(
        'Decryption failed. Incorrect master password or corrupted cryptographic payload ($e).',
      );
    }

    // 5. Decrypted Payload Checksum Validation (if present)
    final String? expectedPayloadChecksum = decodedEnvelope['payloadChecksum'] as String?;
    if (expectedPayloadChecksum != null && expectedPayloadChecksum.isNotEmpty) {
      final String actualPayloadChecksum = SecurityHash.sha256Hash(decryptedJson);
      if (actualPayloadChecksum.toLowerCase() != expectedPayloadChecksum.toLowerCase()) {
        throw const RestoreValidationException(
          'Decrypted payload SHA-256 checksum mismatch. Integrity check failed.',
        );
      }
    }

    // 6. JSON Structure and Schema Validation
    final dynamic payload;
    try {
      payload = jsonDecode(decryptedJson);
    } catch (e) {
      throw RestoreValidationException('Decrypted data is not a valid JSON document ($e).');
    }

    if (payload is! Map<String, dynamic> || !payload.containsKey('manifest')) {
      throw const RestoreValidationException(
        'Invalid backup data: Missing root manifest header or incompatible schema version.',
      );
    }

    return payload;
  }

  /// Restores all database collections and relational links atomically from a validated payload.
  static Future<RestoreResult> restoreDatabaseFromDecryptedPayload({
    required Map<String, dynamic> payload,
    required Isar isar,
  }) async {
    final Map<String, int> counts = {};

    await isar.writeTxn(() async {
      // 1. Clear existing database collections safely inside transaction
      await isar.transactions.clear();
      await isar.subscriptions.clear();
      await isar.categoryBudgets.clear();
      await isar.smsAuditLogs.clear();
      await isar.accounts.clear();
      await isar.categorys.clear();

      // 2. Re-create & insert Accounts
      final List<dynamic> accountsRaw = payload['accounts'] as List<dynamic>? ?? [];
      final List<Account> accounts = [];
      final Map<int, Account> accountMap = {};
      for (final a in accountsRaw) {
        final map = a as Map<String, dynamic>;
        final account = Account()
          ..id = (map['id'] as num).toInt()
          ..name = map['name'] as String? ?? 'Restored Account'
          ..currentBalance = (map['balance'] as num?)?.toDouble() ?? 0.0
          ..type = AccountType.values.firstWhere(
            (e) => e.name == map['type'],
            orElse: () => AccountType.bank,
          )
          ..last4Digits = map['last4Digits'] as String?
          ..colorHex = (map['colorHex'] as num?)?.toInt() ?? 0xFF0D9488
          ..isDefault = map['isDefault'] as bool? ?? false;
        accounts.add(account);
        accountMap[account.id] = account;
      }
      if (accounts.isNotEmpty) {
        await isar.accounts.putAll(accounts);
      }
      counts['accounts'] = accounts.length;

      // 3. Re-create & insert Categories
      final List<dynamic> categoriesRaw = payload['categories'] as List<dynamic>? ?? [];
      final List<Category> categories = [];
      final Map<int, Category> categoryMap = {};
      for (final c in categoriesRaw) {
        final map = c as Map<String, dynamic>;
        final category = Category()
          ..id = (map['id'] as num).toInt()
          ..name = map['name'] as String? ?? 'Restored Category'
          ..iconCodePoint = (map['iconCodePoint'] as num?)?.toInt() ?? 0
          ..colorHex = (map['colorHex'] as num?)?.toInt() ?? 0xFF0D9488
          ..budgetLimit = (map['budgetLimit'] as num?)?.toDouble();
        categories.add(category);
        categoryMap[category.id] = category;
      }
      if (categories.isNotEmpty) {
        await isar.categorys.putAll(categories);
      }
      counts['categories'] = categories.length;

      // 4. Re-create & insert Transactions with Links
      final List<dynamic> transactionsRaw = payload['transactions'] as List<dynamic>? ?? [];
      final List<Transaction> transactions = [];
      for (final t in transactionsRaw) {
        final map = t as Map<String, dynamic>;
        final transaction = Transaction()
          ..id = (map['id'] as num).toInt()
          ..amount = (map['amount'] as num?)?.toDouble() ?? 0.0
          ..type = TransactionType.values.firstWhere(
            (e) => e.name == map['type'],
            orElse: () => TransactionType.expense,
          )
          ..timestamp = DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now()
          ..note = map['note'] as String?
          ..receiptLocalPath = map['receiptLocalPath'] as String?
          ..tags = (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? []
          ..deduplicationHash = map['deduplicationHash'] as String?;

        final int? sourceId = (map['sourceAccountId'] as num?)?.toInt();
        if (sourceId != null && accountMap.containsKey(sourceId)) {
          transaction.sourceAccount.value = accountMap[sourceId];
        }
        final int? destId = (map['destinationAccountId'] as num?)?.toInt();
        if (destId != null && accountMap.containsKey(destId)) {
          transaction.destinationAccount.value = accountMap[destId];
        }
        final int? catId = (map['categoryId'] as num?)?.toInt();
        if (catId != null && categoryMap.containsKey(catId)) {
          transaction.category.value = categoryMap[catId];
        }
        transactions.add(transaction);
      }
      if (transactions.isNotEmpty) {
        await isar.transactions.putAll(transactions);
        for (final tx in transactions) {
          await tx.sourceAccount.save();
          await tx.destinationAccount.save();
          await tx.category.save();
        }
      }
      counts['transactions'] = transactions.length;

      // 5. Re-create & insert Subscriptions with Links
      final List<dynamic> subscriptionsRaw = payload['subscriptions'] as List<dynamic>? ?? [];
      final List<Subscription> subscriptions = [];
      for (final s in subscriptionsRaw) {
        final map = s as Map<String, dynamic>;
        final sub = Subscription()
          ..id = (map['id'] as num).toInt()
          ..name = map['name'] as String? ?? 'Restored Subscription'
          ..amount = (map['amount'] as num?)?.toDouble() ?? 0.0
          ..cycle = BillingCycle.values.firstWhere(
            (e) => e.name == map['cycle'],
            orElse: () => BillingCycle.monthly,
          )
          ..nextBillingDate = DateTime.tryParse(map['nextBillingDate'] as String? ?? '') ?? DateTime.now()
          ..reminderDaysBefore = (map['reminderDaysBefore'] as num?)?.toInt() ?? 1
          ..isActive = map['isActive'] as bool? ?? true
          ..autoLogOnRenewal = map['autoLogOnRenewal'] as bool? ?? false;

        final int? catId = (map['categoryId'] as num?)?.toInt();
        if (catId != null && categoryMap.containsKey(catId)) {
          sub.category.value = categoryMap[catId];
        }
        final int? accId = (map['accountId'] as num?)?.toInt();
        if (accId != null && accountMap.containsKey(accId)) {
          sub.account.value = accountMap[accId];
        }
        subscriptions.add(sub);
      }
      if (subscriptions.isNotEmpty) {
        await isar.subscriptions.putAll(subscriptions);
        for (final sub in subscriptions) {
          await sub.category.save();
          await sub.account.save();
        }
      }
      counts['subscriptions'] = subscriptions.length;

      // 6. Re-create & insert CategoryBudgets with Links
      final List<dynamic> budgetsRaw = payload['budgets'] as List<dynamic>? ?? [];
      final List<CategoryBudget> budgets = [];
      for (final b in budgetsRaw) {
        final map = b as Map<String, dynamic>;
        final budget = CategoryBudget()
          ..id = (map['id'] as num).toInt()
          ..monthlyLimit = (map['monthlyLimit'] as num?)?.toDouble() ?? 0.0
          ..month = (map['month'] as num?)?.toInt() ?? DateTime.now().month
          ..year = (map['year'] as num?)?.toInt() ?? DateTime.now().year;

        final int? catId = (map['categoryId'] as num?)?.toInt();
        if (catId != null && categoryMap.containsKey(catId)) {
          budget.category.value = categoryMap[catId];
        }
        budgets.add(budget);
      }
      if (budgets.isNotEmpty) {
        await isar.categoryBudgets.putAll(budgets);
        for (final b in budgets) {
          await b.category.save();
        }
      }
      counts['budgets'] = budgets.length;

      // 7. Re-create & insert SmsAuditLogs
      final List<dynamic> smsLogsRaw = payload['smsLogs'] as List<dynamic>? ?? [];
      final List<SmsAuditLog> smsLogs = [];
      for (final l in smsLogsRaw) {
        final map = l as Map<String, dynamic>;
        final log = SmsAuditLog()
          ..id = (map['id'] as num).toInt()
          ..rawPayload = map['rawPayload'] as String? ?? ''
          ..parsedAmount = (map['parsedAmount'] as num?)?.toDouble()
          ..detectedPayee = map['detectedPayee'] as String?
          ..sourcePackageOrSender = map['sourcePackageOrSender'] as String?
          ..executionState = AuditExecutionState.values.firstWhere(
            (e) => e.name == map['executionState'],
            orElse: () => AuditExecutionState.ignored,
          )
          ..timestamp = DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now()
          ..deduplicationHash = map['deduplicationHash'] as String?
          ..inferredCategory = map['inferredCategory'] as String?;
        smsLogs.add(log);
      }
      if (smsLogs.isNotEmpty) {
        await isar.smsAuditLogs.putAll(smsLogs);
      }
      counts['smsLogs'] = smsLogs.length;
    });

    return RestoreResult(
      isSuccess: true,
      message: 'Database successfully restored from backup.',
      restoredCounts: counts,
    );
  }

  /// Full Phase 46 Restoration Pipeline:
  /// 1. Verifies SHA-256 checksums and attempts payload decryption.
  /// 2. If valid, atomically clears and restores database via [restoreDatabaseFromDecryptedPayload].
  /// 3. Aborts and throws [RestoreValidationException] without altering data if verification fails.
  /// 4. If [isar] is null, performs validation and dry-run decoding without writing to database.
  static Future<RestoreResult> restoreEncryptedBackup({
    required String encryptedEnvelopeJson,
    required String password,
    Isar? isar,
    String? expectedFileChecksum,
  }) async {
    // Validate & decrypt first. Throws RestoreValidationException on any error.
    final Map<String, dynamic> payload = validateAndDecryptBackup(
      encryptedEnvelopeJson: encryptedEnvelopeJson,
      password: password,
      expectedFileChecksum: expectedFileChecksum,
    );

    if (isar == null) {
      return RestoreResult(
        isSuccess: true,
        message: 'Backup payload successfully validated and decrypted.',
        restoredCounts: {
          'accounts': (payload['accounts'] as List?)?.length ?? 0,
          'categories': (payload['categories'] as List?)?.length ?? 0,
          'transactions': (payload['transactions'] as List?)?.length ?? 0,
          'subscriptions': (payload['subscriptions'] as List?)?.length ?? 0,
          'budgets': (payload['budgets'] as List?)?.length ?? 0,
          'smsLogs': (payload['smsLogs'] as List?)?.length ?? 0,
        },
      );
    }

    // Only when validation strictly passes and isar is provided, overwrite database.
    return await restoreDatabaseFromDecryptedPayload(
      payload: payload,
      isar: isar,
    );
  }

  /// Full Phase 46 Restoration Pipeline from a File:
  /// Reads file, calculates/verifies checksum, decrypts, and restores database.
  static Future<RestoreResult> restoreFromFile({
    required File backupFile,
    required String password,
    Isar? isar,
    String? expectedFileChecksum,
  }) async {
    if (!backupFile.existsSync()) {
      throw RestoreValidationException('Backup file not found at: ${backupFile.path}');
    }

    final String content = await backupFile.readAsString(encoding: utf8);
    return await restoreEncryptedBackup(
      encryptedEnvelopeJson: content,
      password: password,
      isar: isar,
      expectedFileChecksum: expectedFileChecksum,
    );
  }

  /// Writes the encrypted backup envelope to a `.enc` file in the application's cache directory.
  static Future<File> createEncryptedBackupFile({
    required String jsonPayload,
    required String password,
    String? filename,
    Directory? cacheDirectory,
    int iterations = 100000,
  }) async {
    final String encryptedJson = encryptPayload(
      jsonPayload: jsonPayload,
      password: password,
      iterations: iterations,
    );

    final Directory dir = cacheDirectory ?? (await getTemporaryDirectory());
    final String dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String name = filename ?? 'financex_backup_$dateStr.enc';
    final String finalName = name.endsWith('.enc') ? name : '$name.enc';

    final File file = File('${dir.path}/$finalName');
    return await file.writeAsString(encryptedJson, encoding: utf8);
  }

  /// Complete pipeline: Encrypts database, saves `.enc` to cache directory,
  /// and triggers system share sheet via [SharePlus.instance.shareXFiles].
  static Future<ShareResult> backupAndShare({
    required String jsonPayload,
    required String password,
    String? filename,
    Directory? cacheDirectory,
    String subject = 'FinanceX Encrypted Vault Backup',
    String text = 'Attached is your AES-256-GCM encrypted FinanceX backup file (.enc).',
  }) async {
    final File backupFile = await createEncryptedBackupFile(
      jsonPayload: jsonPayload,
      password: password,
      filename: filename,
      cacheDirectory: cacheDirectory,
    );

    final XFile xFile = XFile(
      backupFile.path,
      mimeType: 'application/octet-stream',
      name: backupFile.path.split(Platform.pathSeparator).last,
    );

    return await _shareBridge.shareXFiles(
      [xFile],
      subject: subject,
      text: text,
    );
  }
}
