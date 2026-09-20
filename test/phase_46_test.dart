import 'dart:convert';
import 'dart:io';
import 'package:finance_app/core/utils/security_hash.dart';
import 'package:finance_app/features/security/domain/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 46: Checksum Integrity Restoration Engine Tests', () {
    const String masterPassword = 'StrongMasterKeyVault!#2026';
    const String wrongPassword = 'IncorrectPassword999!';

    final Map<String, dynamic> sampleValidPayload = {
      'manifest': {
        'app': 'SpendVault',
        'version': '1.0.0',
        'schemaVersion': 1,
        'exportTimestamp': '2026-09-20T19:50:00.000',
        'entityCounts': {
          'accounts': 2,
          'categories': 2,
          'transactions': 2,
          'subscriptions': 1,
          'budgets': 1,
          'smsLogs': 1,
        },
      },
      'accounts': [
        {
          'id': 1,
          'name': 'HDFC Primary Checking',
          'last4Digits': '5512',
          'balance': 74500.50,
          'type': 'bank',
          'isDefault': true,
          'colorHex': 0xFF0D9488,
        },
        {
          'id': 2,
          'name': 'Cash Wallet',
          'last4Digits': null,
          'balance': 3200.00,
          'type': 'cash',
          'isDefault': false,
          'colorHex': 0xFF14B8A6,
        },
      ],
      'categories': [
        {
          'id': 10,
          'name': 'Groceries & Provisions',
          'iconCodePoint': 58742,
          'colorHex': 0xFF0D9488,
          'budgetLimit': 15000.0,
        },
        {
          'id': 11,
          'name': 'Streaming Subscriptions',
          'iconCodePoint': 58743,
          'colorHex': 0xFF6366F1,
          'budgetLimit': 2000.0,
        },
      ],
      'transactions': [
        {
          'id': 1001,
          'amount': 1850.0,
          'type': 'expense',
          'timestamp': '2026-09-18T14:30:00.000',
          'sourceAccountId': 1,
          'destinationAccountId': null,
          'categoryId': 10,
          'note': 'Weekly Supermarket Restock',
          'tags': ['#groceries', '#weekend'],
          'deduplicationHash': 'hash_txn_001',
        },
        {
          'id': 1002,
          'amount': 25000.0,
          'type': 'income',
          'timestamp': '2026-09-01T09:00:00.000',
          'sourceAccountId': 1,
          'destinationAccountId': null,
          'categoryId': null,
          'note': 'Consulting Retainer Pay',
          'tags': ['#income', '#consulting'],
          'deduplicationHash': 'hash_txn_002',
        },
      ],
      'subscriptions': [
        {
          'id': 201,
          'name': 'Netflix 4K UHD',
          'amount': 649.0,
          'cycle': 'monthly',
          'nextBillingDate': '2026-10-15T00:00:00.000',
          'reminderDaysBefore': 2,
          'isActive': true,
          'autoLogOnRenewal': true,
          'categoryId': 11,
          'accountId': 1,
        },
      ],
      'budgets': [
        {
          'id': 301,
          'monthlyLimit': 15000.0,
          'month': 9,
          'year': 2026,
          'categoryId': 10,
        },
      ],
      'smsLogs': [
        {
          'id': 401,
          'rawPayload': 'HDFC Bank: Rs 1,850.00 spent at Nature Basket on xx5512',
          'parsedAmount': 1850.0,
          'detectedPayee': 'Nature Basket',
          'sourcePackageOrSender': 'HDFCBK',
          'executionState': 'parsed',
          'timestamp': '2026-09-18T14:30:00.000',
          'deduplicationHash': 'dedup_sms_001',
          'inferredCategory': 'Groceries',
        },
      ],
    };

    final String validPayloadJson = jsonEncode(sampleValidPayload);

    test('1. Checksum & Decryption: Successfully validates SHA-256 and decodes valid envelope under password', () {
      final String envelopeJson = BackupService.encryptPayload(
        jsonPayload: validPayloadJson,
        password: masterPassword,
        iterations: 1000,
      );

      final decoded = BackupService.validateAndDecryptBackup(
        encryptedEnvelopeJson: envelopeJson,
        password: masterPassword,
      );

      expect(decoded, isA<Map<String, dynamic>>());
      expect(decoded['manifest']['app'], 'SpendVault');
      expect((decoded['accounts'] as List).length, 2);
      expect((decoded['transactions'] as List).length, 2);
      expect((decoded['subscriptions'] as List).length, 1);
    });

    test('2. External File SHA-256 Checksum Validation: Accepts matching checksum', () {
      final String envelopeJson = BackupService.encryptPayload(
        jsonPayload: validPayloadJson,
        password: masterPassword,
        iterations: 1000,
      );

      final String expectedChecksum = SecurityHash.sha256Hash(envelopeJson);

      final decoded = BackupService.validateAndDecryptBackup(
        encryptedEnvelopeJson: envelopeJson,
        password: masterPassword,
        expectedFileChecksum: expectedChecksum,
      );

      expect(decoded['manifest']['app'], 'SpendVault');
    });

    test('3. External File SHA-256 Checksum Validation: Aborts with RestoreValidationException on checksum mismatch', () {
      final String envelopeJson = BackupService.encryptPayload(
        jsonPayload: validPayloadJson,
        password: masterPassword,
        iterations: 1000,
      );

      const String forgedChecksum = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

      expect(
        () => BackupService.validateAndDecryptBackup(
          encryptedEnvelopeJson: envelopeJson,
          password: masterPassword,
          expectedFileChecksum: forgedChecksum,
        ),
        throwsA(
          isA<RestoreValidationException>().having(
            (e) => e.message,
            'message',
            contains('File SHA-256 checksum verification failed'),
          ),
        ),
      );
    });

    test('4. Ciphertext Integrity: Aborts if internal ciphertext checksum is tampered', () {
      final String envelopeJson = BackupService.encryptPayload(
        jsonPayload: validPayloadJson,
        password: masterPassword,
        iterations: 1000,
      );

      final Map<String, dynamic> envelopeMap = jsonDecode(envelopeJson) as Map<String, dynamic>;
      // Tamper ciphertext
      final String originalCiphertext = envelopeMap['ciphertext'] as String;
      envelopeMap['ciphertext'] = '${originalCiphertext.substring(0, originalCiphertext.length - 4)}AAAA';

      final String tamperedEnvelope = jsonEncode(envelopeMap);

      expect(
        () => BackupService.validateAndDecryptBackup(
          encryptedEnvelopeJson: tamperedEnvelope,
          password: masterPassword,
        ),
        throwsA(
          isA<RestoreValidationException>().having(
            (e) => e.message,
            'message',
            contains('Encrypted data integrity checksum mismatch'),
          ),
        ),
      );
    });

    test('5. Authentication & Decryption: Aborts with RestoreValidationException if supplied password is wrong', () {
      final String envelopeJson = BackupService.encryptPayload(
        jsonPayload: validPayloadJson,
        password: masterPassword,
        iterations: 1000,
      );

      expect(
        () => BackupService.validateAndDecryptBackup(
          encryptedEnvelopeJson: envelopeJson,
          password: wrongPassword,
        ),
        throwsA(
          isA<RestoreValidationException>().having(
            (e) => e.message,
            'message',
            contains('Decryption failed. Incorrect master password'),
          ),
        ),
      );
    });

    test('6. Schema Validation: Aborts with RestoreValidationException if manifest header is missing', () {
      final Map<String, dynamic> missingManifestPayload = {
        'accounts': [{'id': 1, 'name': 'Corrupt Vault'}],
      };

      final String envelopeJson = BackupService.encryptPayload(
        jsonPayload: jsonEncode(missingManifestPayload),
        password: masterPassword,
        iterations: 1000,
      );

      expect(
        () => BackupService.validateAndDecryptBackup(
          encryptedEnvelopeJson: envelopeJson,
          password: masterPassword,
        ),
        throwsA(
          isA<RestoreValidationException>().having(
            (e) => e.message,
            'message',
            contains('Missing root manifest header'),
          ),
        ),
      );
    });

    test('7. File Restoration: Throws RestoreValidationException when target file does not exist', () async {
      final File nonExistentFile = File('c:/non_existent_vault_backup.enc');

      expect(
        () => BackupService.restoreFromFile(
          backupFile: nonExistentFile,
          password: masterPassword,
          isar: null,
        ),
        throwsA(
          isA<RestoreValidationException>().having(
            (e) => e.message,
            'message',
            contains('Backup file not found'),
          ),
        ),
      );
    });

    test('8. End-to-End File Lifecycle: Encrypt to file -> Validate & Decrypt from file content', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp('phase46_restore_test_');
      addTearDown(() async => await tempDir.delete(recursive: true));

      final File backupFile = await BackupService.createEncryptedBackupFile(
        jsonPayload: validPayloadJson,
        password: masterPassword,
        filename: 'restore_vault_test.enc',
        cacheDirectory: tempDir,
        iterations: 1000,
      );

      expect(backupFile.existsSync(), isTrue);

      final String fileContent = await backupFile.readAsString();
      final String fileSha256 = SecurityHash.sha256Hash(fileContent);

      final Map<String, dynamic> restoredPayload = BackupService.validateAndDecryptBackup(
        encryptedEnvelopeJson: fileContent,
        password: masterPassword,
        expectedFileChecksum: fileSha256,
      );

      expect(restoredPayload['manifest']['app'], 'SpendVault');
      expect((restoredPayload['accounts'] as List).first['name'], 'HDFC Primary Checking');
      expect((restoredPayload['transactions'] as List).first['amount'], 1850.0);
      expect((restoredPayload['subscriptions'] as List).first['name'], 'Netflix 4K UHD');
    });
  });
}
