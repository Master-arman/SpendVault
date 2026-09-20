import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:finance_app/features/security/domain/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

class MockBackupShareBridge implements IBackupShareBridge {
  List<XFile> sharedFiles = [];
  String? sharedSubject;
  String? sharedText;

  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? text,
    String? subject,
  }) async {
    sharedFiles = files;
    sharedSubject = subject;
    sharedText = text;
    return const ShareResult('success', ShareResultStatus.success);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 45: AES-256-GCM Encrypted Local Backup Engine Tests', () {
    late MockBackupShareBridge mockShareBridge;

    setUp(() {
      mockShareBridge = MockBackupShareBridge();
      BackupService.setShareBridgeForTesting(mockShareBridge);
    });

    tearDown(() {
      BackupService.setShareBridgeForTesting(null);
    });

    final Map<String, dynamic> sampleDatabasePayload = {
      'manifest': {
        'app': 'FinanceX',
        'version': '1.0.0',
        'schemaVersion': 1,
      },
      'accounts': [
        {
          'id': 1,
          'name': 'Primary Checking',
          'balance': 45250.75,
        }
      ],
      'transactions': [
        {
          'id': 101,
          'amount': 2499.00,
          'note': 'Apple Store Purchase #tech',
          'tags': ['#tech', '#apple'],
        }
      ],
    };

    final String sampleJson = jsonEncode(sampleDatabasePayload);
    const String masterPassword = 'SuperSecretMasterPassword123!';

    test('PBKDF2 derives deterministic 256-bit key (32 bytes) for identical salt & password', () {
      final Uint8List fixedSalt = Uint8List.fromList(List.generate(16, (i) => i + 1));
      
      // Use 1,000 iterations for unit test speed, default uses 100,000
      final Uint8List key1 = BackupService.deriveKey(masterPassword, fixedSalt, iterations: 1000);
      final Uint8List key2 = BackupService.deriveKey(masterPassword, fixedSalt, iterations: 1000);

      expect(key1.length, 32); // 256 bits
      expect(key1, equals(key2));
    });

    test('AES-256-GCM Encrypts and Decrypts structured JSON payload accurately', () {
      final String encryptedEnvelope = BackupService.encryptPayload(
        jsonPayload: sampleJson,
        password: masterPassword,
        iterations: 1000,
      );

      expect(encryptedEnvelope, contains('"cipher":"AES-256-GCM"'));
      expect(encryptedEnvelope, contains('"kdf":"PBKDF2-HMAC-SHA256"'));
      expect(encryptedEnvelope, contains('"salt"'));
      expect(encryptedEnvelope, contains('"iv"'));
      expect(encryptedEnvelope, contains('"ciphertext"'));

      final String decryptedJson = BackupService.decryptPayload(
        encryptedEnvelopeJson: encryptedEnvelope,
        password: masterPassword,
      );

      expect(decryptedJson, equals(sampleJson));
      final Map<String, dynamic> restored = jsonDecode(decryptedJson) as Map<String, dynamic>;
      expect(restored['accounts'][0]['name'], 'Primary Checking');
      expect(restored['transactions'][0]['amount'], 2499.00);
    });

    test('Decryption with incorrect password fails and throws exception', () {
      final String encryptedEnvelope = BackupService.encryptPayload(
        jsonPayload: sampleJson,
        password: masterPassword,
        iterations: 1000,
      );

      expect(
        () => BackupService.decryptPayload(
          encryptedEnvelopeJson: encryptedEnvelope,
          password: 'WrongPassword999!',
        ),
        throwsA(anything),
      );
    });

    test('createEncryptedBackupFile writes .enc file to target cache directory', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp('backup_test_');
      addTearDown(() async => await tempDir.delete(recursive: true));

      final File file = await BackupService.createEncryptedBackupFile(
        jsonPayload: sampleJson,
        password: masterPassword,
        filename: 'my_vault_backup',
        cacheDirectory: tempDir,
        iterations: 1000,
      );

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.enc'), isTrue);

      final String fileContent = await file.readAsString();
      expect(fileContent, contains('"cipher":"AES-256-GCM"'));

      final String decrypted = BackupService.decryptPayload(
        encryptedEnvelopeJson: fileContent,
        password: masterPassword,
      );
      expect(decrypted, equals(sampleJson));
    });

    test('backupAndShare creates .enc file and invokes share sheet', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp('backup_share_test_');
      addTearDown(() async => await tempDir.delete(recursive: true));

      final result = await BackupService.backupAndShare(
        jsonPayload: sampleJson,
        password: masterPassword,
        filename: 'statement_backup.enc',
        cacheDirectory: tempDir,
      );

      expect(result.status, ShareResultStatus.success);
      expect(mockShareBridge.sharedFiles.length, 1);
      expect(mockShareBridge.sharedFiles.first.path.endsWith('statement_backup.enc'), isTrue);
    });
  });
}
