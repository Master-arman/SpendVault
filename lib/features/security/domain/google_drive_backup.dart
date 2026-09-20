import 'dart:convert';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/utils/security_hash.dart';
import 'package:finance_app/features/security/domain/backup_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';

/// Represents a remote encrypted backup snapshot stored in Google Drive's private `appDataFolder`.
class DriveBackupSnapshot {
  final String id;
  final String name;
  final DateTime createdTime;
  final DateTime? modifiedTime;
  final int sizeBytes;
  final String? md5Checksum;
  final String? sha256Checksum;
  final Map<String, String> appProperties;

  const DriveBackupSnapshot({
    required this.id,
    required this.name,
    required this.createdTime,
    this.modifiedTime,
    required this.sizeBytes,
    this.md5Checksum,
    this.sha256Checksum,
    this.appProperties = const {},
  });

  @override
  String toString() =>
      'DriveBackupSnapshot(id: $id, name: $name, createdTime: $createdTime, size: $sizeBytes bytes)';
}

/// Abstract bridge for Google Sign-In and Google Drive Private AppData operations
/// allowing flawless mock injection during automated testing without live credentials.
abstract class IGoogleDriveClientBridge {
  Future<bool> signIn();
  Future<void> signOut();
  Future<bool> isSignedIn();
  Future<String?> getCurrentUserEmail();
  Future<DriveBackupSnapshot> uploadFile({
    required String name,
    required String content,
    Map<String, String>? appProperties,
  });
  Future<List<DriveBackupSnapshot>> listFiles();
  Future<String> downloadFile(String fileId);
  Future<void> deleteFile(String fileId);
}

/// Live Google Drive API client bridge using `google_sign_in` and `googleapis`.
class DefaultGoogleDriveClientBridge implements IGoogleDriveClientBridge {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  Future<drive.DriveApi> _getDriveApi() async {
    if (_driveApi != null) return _driveApi!;

    _currentUser ??= await _googleSignIn.signInSilently();
    _currentUser ??= await _googleSignIn.signIn();

    if (_currentUser == null) {
      throw const RestoreValidationException(
        'Google Drive authentication was cancelled or unavailable.',
      );
    }

    final http.Client? client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw const RestoreValidationException(
        'Failed to obtain authenticated HTTP client for Google Drive.',
      );
    }

    _driveApi = drive.DriveApi(client);
    return _driveApi!;
  }

  @override
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        _driveApi = null; // Re-initialize with active user client
        await _getDriveApi();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  @override
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    _currentUser ??= await _googleSignIn.signInSilently();
    return _currentUser?.email;
  }

  @override
  Future<DriveBackupSnapshot> uploadFile({
    required String name,
    required String content,
    Map<String, String>? appProperties,
  }) async {
    final driveApi = await _getDriveApi();

    final List<int> bytes = utf8.encode(content);
    final String sha256 = SecurityHash.sha256Hash(content);

    final drive.File fileMetadata = drive.File()
      ..name = name
      ..parents = [GoogleDriveBackupService.appDataFolder] // Isolate to private appDataFolder
      ..mimeType = 'application/octet-stream'
      ..appProperties = {
        ...?appProperties,
        'app': AppConstants.appName,
        'version': AppConstants.appVersion,
        'sha256': sha256,
      };

    final drive.Media media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
      contentType: 'application/octet-stream',
    );

    final drive.File createdFile = await driveApi.files.create(
      fileMetadata,
      uploadMedia: media,
      $fields: 'id, name, createdTime, modifiedTime, size, md5Checksum, appProperties',
    );

    final Map<String, String> parsedProperties = {};
    createdFile.appProperties?.forEach((key, value) {
      if (value != null) {
        parsedProperties[key] = value;
      }
    });

    return DriveBackupSnapshot(
      id: createdFile.id ?? '',
      name: createdFile.name ?? name,
      createdTime: createdFile.createdTime ?? DateTime.now(),
      modifiedTime: createdFile.modifiedTime,
      sizeBytes: int.tryParse(createdFile.size ?? '') ?? bytes.length,
      md5Checksum: createdFile.md5Checksum,
      sha256Checksum: sha256,
      appProperties: parsedProperties,
    );
  }

  @override
  Future<List<DriveBackupSnapshot>> listFiles() async {
    final driveApi = await _getDriveApi();

    final drive.FileList fileList = await driveApi.files.list(
      spaces: GoogleDriveBackupService.appDataFolder,
      q: "trashed = false and mimeType = 'application/octet-stream'",
      $fields: 'files(id, name, createdTime, modifiedTime, size, md5Checksum, appProperties)',
      orderBy: 'createdTime desc',
    );

    final List<drive.File> files = fileList.files ?? [];
    return files.map((f) {
      final Map<String, String> parsedProps = {};
      f.appProperties?.forEach((key, value) {
        if (value != null) {
          parsedProps[key] = value;
        }
      });

      return DriveBackupSnapshot(
        id: f.id ?? '',
        name: f.name ?? 'untitled_backup.enc',
        createdTime: f.createdTime ?? DateTime.now(),
        modifiedTime: f.modifiedTime,
        sizeBytes: int.tryParse(f.size ?? '') ?? 0,
        md5Checksum: f.md5Checksum,
        sha256Checksum: parsedProps['sha256'],
        appProperties: parsedProps,
      );
    }).toList();
  }

  @override
  Future<String> downloadFile(String fileId) async {
    final driveApi = await _getDriveApi();

    final dynamic media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (media is! drive.Media) {
      throw RestoreValidationException('Invalid response when downloading file ID: $fileId');
    }

    final List<int> bytes = [];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }

    return utf8.decode(bytes);
  }

  @override
  Future<void> deleteFile(String fileId) async {
    final driveApi = await _getDriveApi();
    await driveApi.files.delete(fileId);
  }
}

/// Phase 47: Google Drive Private AppData Sync Engine.
///
/// Features:
/// - Authenticates using `google_sign_in` with `https://www.googleapis.com/auth/drive.appdata` scope.
/// - Stores backup snapshots exclusively in the invisible `appDataFolder` on Google Drive.
/// - Keeps the database file private and hidden from the user's standard Drive UI to prevent accidental deletion.
/// - Integrates seamlessly with Phase 46 Checksum Integrity Restoration Engine.
class GoogleDriveBackupService {
  const GoogleDriveBackupService._();

  /// Google Drive Private AppData scope.
  static const String driveAppdataScope = drive.DriveApi.driveAppdataScope;

  /// Dedicated hidden space in Google Drive.
  static const String appDataFolder = 'appDataFolder';

  static IGoogleDriveClientBridge _clientBridge = DefaultGoogleDriveClientBridge();

  /// Configures custom client bridge for mock unit testing.
  static void setClientBridgeForTesting(IGoogleDriveClientBridge? bridge) {
    _clientBridge = bridge ?? DefaultGoogleDriveClientBridge();
  }

  /// Triggers Google Sign-In with private `drive.appdata` scope.
  static Future<bool> signIn() => _clientBridge.signIn();

  /// Signs out the user from Google Drive.
  static Future<void> signOut() => _clientBridge.signOut();

  /// Checks if user is authenticated with Google Drive.
  static Future<bool> isSignedIn() => _clientBridge.isSignedIn();

  /// Returns the current signed-in Google account email.
  static Future<String?> getCurrentUserEmail() => _clientBridge.getCurrentUserEmail();

  /// Uploads an encrypted backup snapshot payload directly into the private `appDataFolder`.
  static Future<DriveBackupSnapshot> uploadSnapshot({
    required String encryptedPayload,
    String? filename,
    Map<String, String>? appProperties,
  }) async {
    final String dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String targetName = filename ?? 'financex_drive_backup_$dateStr.enc';
    final String finalName = targetName.endsWith('.enc') ? targetName : '$targetName.enc';

    return await _clientBridge.uploadFile(
      name: finalName,
      content: encryptedPayload,
      appProperties: appProperties,
    );
  }

  /// Lists all encrypted backup snapshots available in the private `appDataFolder`.
  static Future<List<DriveBackupSnapshot>> listSnapshots() => _clientBridge.listFiles();

  /// Downloads an encrypted backup snapshot from the private `appDataFolder`.
  static Future<String> downloadSnapshot(String fileId) => _clientBridge.downloadFile(fileId);

  /// Deletes an encrypted backup snapshot from `appDataFolder`.
  static Future<void> deleteSnapshot(String fileId) => _clientBridge.deleteFile(fileId);

  /// Complete end-to-end sync pipeline:
  /// 1. Serializes local Isar database.
  /// 2. Encrypts payload with PBKDF2 + AES-256-GCM.
  /// 3. Uploads encrypted `.enc` file to Google Drive's hidden `appDataFolder`.
  static Future<DriveBackupSnapshot> backupDatabaseToDrive({
    required Isar isar,
    required String password,
    String? filename,
    int iterations = 100000,
  }) async {
    final String rawJson = await BackupService.serializeIsarDatabase(isar);
    final String encryptedJson = BackupService.encryptPayload(
      jsonPayload: rawJson,
      password: password,
      iterations: iterations,
    );

    return await uploadSnapshot(
      encryptedPayload: encryptedJson,
      filename: filename,
    );
  }

  /// Complete restore pipeline from a Google Drive AppData snapshot:
  /// 1. Downloads encrypted envelope from Google Drive `appDataFolder`.
  /// 2. Invokes Phase 46 Checksum Integrity Restoration Engine:
  ///    - Validates SHA-256 checksums (both file and ciphertext).
  ///    - Validates password decryption & MAC integrity.
  ///    - Verifies JSON structure and manifest.
  ///    - Atomically overwrites and restores the active Isar database.
  /// 3. Aborts and raises [RestoreValidationException] without altering data if validation fails.
  static Future<RestoreResult> restoreDatabaseFromDrive({
    required String fileId,
    required String password,
    Isar? isar,
    String? expectedChecksum,
  }) async {
    final String encryptedContent = await downloadSnapshot(fileId);

    return await BackupService.restoreEncryptedBackup(
      encryptedEnvelopeJson: encryptedContent,
      password: password,
      isar: isar,
      expectedFileChecksum: expectedChecksum,
    );
  }
}
