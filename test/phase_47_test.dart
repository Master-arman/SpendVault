import 'dart:convert';
import 'package:finance_app/core/utils/security_hash.dart';
import 'package:finance_app/features/security/domain/backup_service.dart';
import 'package:finance_app/features/security/domain/google_drive_backup.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock Google Drive bridge implementing private `appDataFolder` storage in memory.
class MockGoogleDriveClientBridge implements IGoogleDriveClientBridge {
  bool _signedIn = false;
  String? _userEmail;
  final Map<String, _MockDriveFile> _storage = {};
  int _idCounter = 1;

  @override
  Future<bool> signIn() async {
    _signedIn = true;
    _userEmail = 'tester@gmail.com';
    return true;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _userEmail = null;
  }

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<String?> getCurrentUserEmail() async => _userEmail;

  @override
  Future<DriveBackupSnapshot> uploadFile({
    required String name,
    required String content,
    Map<String, String>? appProperties,
  }) async {
    final String id = 'drive_file_${_idCounter++}';
    final DateTime now = DateTime.now();
    final String sha256 = SecurityHash.sha256Hash(content);

    final mockFile = _MockDriveFile(
      id: id,
      name: name,
      content: content,
      createdTime: now,
      modifiedTime: now,
      sizeBytes: utf8.encode(content).length,
      sha256Checksum: sha256,
      appProperties: {
        ...?appProperties,
        'parent': GoogleDriveBackupService.appDataFolder,
        'sha256': sha256,
      },
    );

    _storage[id] = mockFile;

    return DriveBackupSnapshot(
      id: mockFile.id,
      name: mockFile.name,
      createdTime: mockFile.createdTime,
      modifiedTime: mockFile.modifiedTime,
      sizeBytes: mockFile.sizeBytes,
      sha256Checksum: mockFile.sha256Checksum,
      appProperties: mockFile.appProperties,
    );
  }

  @override
  Future<List<DriveBackupSnapshot>> listFiles() async {
    return _storage.values.map((f) {
      return DriveBackupSnapshot(
        id: f.id,
        name: f.name,
        createdTime: f.createdTime,
        modifiedTime: f.modifiedTime,
        sizeBytes: f.sizeBytes,
        sha256Checksum: f.sha256Checksum,
        appProperties: f.appProperties,
      );
    }).toList();
  }

  @override
  Future<String> downloadFile(String fileId) async {
    final file = _storage[fileId];
    if (file == null) {
      throw const RestoreValidationException('File not found in Google Drive appDataFolder.');
    }
    return file.content;
  }

  @override
  Future<void> deleteFile(String fileId) async {
    _storage.remove(fileId);
  }
}

class _MockDriveFile {
  final String id;
  final String name;
  final String content;
  final DateTime createdTime;
  final DateTime modifiedTime;
  final int sizeBytes;
  final String sha256Checksum;
  final Map<String, String> appProperties;

  _MockDriveFile({
    required this.id,
    required this.name,
    required this.content,
    required this.createdTime,
    required this.modifiedTime,
    required this.sizeBytes,
    required this.sha256Checksum,
    required this.appProperties,
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 47: Google Drive Private AppData Sync Tests', () {
    late MockGoogleDriveClientBridge mockDriveBridge;
    const String masterPassword = 'GoogleVaultSecurePass#2026';

    final Map<String, dynamic> sampleDatabasePayload = {
      'manifest': {
        'app': 'SpendVault',
        'version': '1.0.0',
        'schemaVersion': 1,
        'exportTimestamp': '2026-09-20T20:00:00.000',
        'entityCounts': {'accounts': 1, 'transactions': 1},
      },
      'accounts': [
        {
          'id': 1,
          'name': 'HDFC Salary Account',
          'balance': 98500.0,
          'type': 'bank',
        }
      ],
      'transactions': [
        {
          'id': 101,
          'amount': 3200.0,
          'type': 'expense',
          'timestamp': '2026-09-20T12:00:00.000',
          'note': 'Grocery Store purchase',
          'tags': ['#food'],
        }
      ],
    };

    final String sampleJson = jsonEncode(sampleDatabasePayload);

    setUp(() {
      mockDriveBridge = MockGoogleDriveClientBridge();
      GoogleDriveBackupService.setClientBridgeForTesting(mockDriveBridge);
    });

    tearDown(() {
      GoogleDriveBackupService.setClientBridgeForTesting(null);
    });

    test('1. Scope & Constants: Enforces drive.appdata scope and appDataFolder isolation target', () {
      expect(
        GoogleDriveBackupService.driveAppdataScope,
        'https://www.googleapis.com/auth/drive.appdata',
      );
      expect(GoogleDriveBackupService.appDataFolder, 'appDataFolder');
    });

    test('2. Authentication: Signs in and retrieves user email', () async {
      expect(await GoogleDriveBackupService.isSignedIn(), isFalse);

      final bool success = await GoogleDriveBackupService.signIn();
      expect(success, isTrue);
      expect(await GoogleDriveBackupService.isSignedIn(), isTrue);
      expect(await GoogleDriveBackupService.getCurrentUserEmail(), 'tester@gmail.com');

      await GoogleDriveBackupService.signOut();
      expect(await GoogleDriveBackupService.isSignedIn(), isFalse);
    });

    test('3. Upload Snapshot: Stores file in appDataFolder with .enc extension and SHA-256 metadata', () async {
      final String encryptedPayload = BackupService.encryptPayload(
        jsonPayload: sampleJson,
        password: masterPassword,
        iterations: 1000,
      );

      final DriveBackupSnapshot snapshot = await GoogleDriveBackupService.uploadSnapshot(
        encryptedPayload: encryptedPayload,
        filename: 'my_encrypted_vault',
      );

      expect(snapshot.id, isNotEmpty);
      expect(snapshot.name.endsWith('.enc'), isTrue);
      expect(snapshot.sizeBytes, greaterThan(0));
      expect(snapshot.appProperties['parent'], GoogleDriveBackupService.appDataFolder);
      expect(snapshot.sha256Checksum, SecurityHash.sha256Hash(encryptedPayload));
    });

    test('4. List & Download: Retrieves snapshots and decodes payload content from appDataFolder', () async {
      final String encryptedPayload = BackupService.encryptPayload(
        jsonPayload: sampleJson,
        password: masterPassword,
        iterations: 1000,
      );

      final snapshot = await GoogleDriveBackupService.uploadSnapshot(
        encryptedPayload: encryptedPayload,
        filename: 'cloud_backup_01.enc',
      );

      final List<DriveBackupSnapshot> list = await GoogleDriveBackupService.listSnapshots();
      expect(list.length, 1);
      expect(list.first.id, snapshot.id);
      expect(list.first.name, 'cloud_backup_01.enc');

      final String downloadedContent = await GoogleDriveBackupService.downloadSnapshot(snapshot.id);
      expect(downloadedContent, equals(encryptedPayload));
    });

    test('5. Restore Pipeline: Downloads from Drive, validates SHA-256, and decrypts successfully', () async {
      final String encryptedPayload = BackupService.encryptPayload(
        jsonPayload: sampleJson,
        password: masterPassword,
        iterations: 1000,
      );

      final snapshot = await GoogleDriveBackupService.uploadSnapshot(
        encryptedPayload: encryptedPayload,
        filename: 'drive_restore_test.enc',
      );

      final RestoreResult result = await GoogleDriveBackupService.restoreDatabaseFromDrive(
        fileId: snapshot.id,
        password: masterPassword,
        isar: null, // Dry run validation
      );

      expect(result.isSuccess, isTrue);
      expect(result.restoredCounts['accounts'], 1);
      expect(result.restoredCounts['transactions'], 1);
    });

    test('6. Restore Pipeline Abort: Throws RestoreValidationException on wrong password without altering database', () async {
      final String encryptedPayload = BackupService.encryptPayload(
        jsonPayload: sampleJson,
        password: masterPassword,
        iterations: 1000,
      );

      final snapshot = await GoogleDriveBackupService.uploadSnapshot(
        encryptedPayload: encryptedPayload,
        filename: 'drive_wrong_pass.enc',
      );

      expect(
        () => GoogleDriveBackupService.restoreDatabaseFromDrive(
          fileId: snapshot.id,
          password: 'WrongPassword999!',
          isar: null,
        ),
        throwsA(
          isA<RestoreValidationException>().having(
            (e) => e.message,
            'message',
            contains('Decryption failed'),
          ),
        ),
      );
    });

    test('7. Delete Snapshot: Successfully removes snapshot from appDataFolder', () async {
      final snapshot = await GoogleDriveBackupService.uploadSnapshot(
        encryptedPayload: 'encrypted_test_payload',
        filename: 'temp_to_delete.enc',
      );

      expect((await GoogleDriveBackupService.listSnapshots()).length, 1);

      await GoogleDriveBackupService.deleteSnapshot(snapshot.id);
      expect((await GoogleDriveBackupService.listSnapshots()).isEmpty, isTrue);
    });
  });
}
