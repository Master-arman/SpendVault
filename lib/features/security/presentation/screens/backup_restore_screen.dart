import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/utils/security_hash.dart';
import 'package:finance_app/features/security/domain/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

/// Phase 45 & Phase 46: Backup & Restoration Screen
///
/// Features:
/// 1. Create password-protected AES-256-GCM encrypted database backups (`.enc`).
/// 2. Pick and restore encrypted backup files with SHA-256 checksum verification.
/// 3. Validates decryption under user password and displays pre-restore entity counts.
/// 4. Aborts immediately and alerts user if decryption or checksum verification fails.
class BackupRestoreScreen extends StatefulWidget {
  final Isar? isar;

  const BackupRestoreScreen({
    super.key,
    this.isar,
  });

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _exportPasswordController = TextEditingController();
  final _restorePasswordController = TextEditingController();
  final _checksumController = TextEditingController();

  bool _isExporting = false;
  bool _isRestoring = false;
  bool _obscureExportPassword = true;
  bool _obscureRestorePassword = true;

  File? _selectedRestoreFile;
  String? _calculatedFileChecksum;
  RestoreResult? _dryRunResult;
  String? _errorMessage;

  @override
  void dispose() {
    _exportPasswordController.dispose();
    _restorePasswordController.dispose();
    _checksumController.dispose();
    super.dispose();
  }

  Future<void> _pickBackupFile() async {
    setState(() {
      _errorMessage = null;
      _dryRunResult = null;
    });

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['enc', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String content = await file.readAsString();
        final String checksum = SecurityHash.sha256Hash(content);

        setState(() {
          _selectedRestoreFile = file;
          _calculatedFileChecksum = checksum;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select file: $e';
      });
    }
  }

  Future<void> _handleExportBackup() async {
    final password = _exportPasswordController.text.trim();
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password with at least 6 characters.'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    if (widget.isar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database instance is unavailable.'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final String payloadJson = await BackupService.serializeIsarDatabase(widget.isar!);
      await BackupService.backupAndShare(
        jsonPayload: payloadJson,
        password: password,
      );

      if (mounted) {
        _exportPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Encrypted backup created and shared successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Export failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _validateAndPreviewRestore() async {
    if (_selectedRestoreFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an encrypted backup file (.enc) first.'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    final password = _restorePasswordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the vault password used during export.'),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
      _dryRunResult = null;
    });

    try {
      final expectedChecksum = _checksumController.text.trim();
      final result = await BackupService.restoreFromFile(
        backupFile: _selectedRestoreFile!,
        password: password,
        isar: null, // Dry-run mode for validation and inspection
        expectedFileChecksum: expectedChecksum.isEmpty ? null : expectedChecksum,
      );

      setState(() {
        _dryRunResult = result;
      });
    } on RestoreValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      _showAlertModal(
        title: 'Validation & Decryption Failed',
        content: e.message,
        isError: true,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Validation error: $e';
      });
      _showAlertModal(
        title: 'Restoration Error',
        content: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _executeAtomicRestore() async {
    if (_selectedRestoreFile == null || widget.isar == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber),
            SizedBox(width: 8),
            Text('Overwrite Database?', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Restoring will replace all current transactions, accounts, categories, and subscriptions with the contents of this backup file. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Overwrite & Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    try {
      final expectedChecksum = _checksumController.text.trim();
      final result = await BackupService.restoreFromFile(
        backupFile: _selectedRestoreFile!,
        password: _restorePasswordController.text,
        isar: widget.isar!,
        expectedFileChecksum: expectedChecksum.isEmpty ? null : expectedChecksum,
      );

      if (mounted) {
        _showAlertModal(
          title: 'Restoration Successful',
          content: 'Database restored successfully.\n\nRestored entities:\n'
              '• Accounts: ${result.restoredCounts['accounts'] ?? 0}\n'
              '• Categories: ${result.restoredCounts['categories'] ?? 0}\n'
              '• Transactions: ${result.restoredCounts['transactions'] ?? 0}\n'
              '• Subscriptions: ${result.restoredCounts['subscriptions'] ?? 0}',
          isError: false,
        );
      }
    } on RestoreValidationException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
        _showAlertModal(
          title: 'Restoration Aborted',
          content: e.message,
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Restore failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  void _showAlertModal({
    required String title,
    required String content,
    required bool isError,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: isError ? AppColors.expenseRed : AppColors.successGreen,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isError ? AppColors.expenseRed : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSlateBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Backup & Restore Vault',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 24),
          _buildExportCard(),
          const SizedBox(height: 24),
          _buildRestoreCard(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(_errorMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Backups are encrypted using AES-256-GCM with PBKDF2 key derivation (100,000 iterations). During restore, SHA-256 checksums and decryption authentication tags are strictly validated before overwriting the database.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Create Encrypted Backup',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Export an encrypted snapshot of all accounts, transactions, and categories.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _exportPasswordController,
              obscureText: _obscureExportPassword,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Master Password',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkSlateBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureExportPassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureExportPassword = !_obscureExportPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isExporting ? null : _handleExportBackup,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share_outlined),
                label: Text(_isExporting ? 'Generating Vault File...' : 'Export & Share Backup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreCard() {
    return Card(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restore_page_outlined, color: AppColors.accentIndigo),
                SizedBox(width: 8),
                Text(
                  'Restore from Encrypted Backup',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a .enc backup file and verify integrity checksums before restoring.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentIndigo,
                side: const BorderSide(color: AppColors.accentIndigo),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _pickBackupFile,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(
                _selectedRestoreFile != null
                    ? _selectedRestoreFile!.path.split(Platform.pathSeparator).last
                    : 'Choose .enc Backup File',
              ),
            ),
            if (_calculatedFileChecksum != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkSlateBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderStroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'File SHA-256 Checksum:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _calculatedFileChecksum!,
                      style: const TextStyle(
                        color: AppColors.accentIndigo,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _checksumController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Expected SHA-256 Checksum (Optional)',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkSlateBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _restorePasswordController,
              obscureText: _obscureRestorePassword,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Vault Password',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkSlateBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRestorePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureRestorePassword = !_obscureRestorePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderStroke),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isRestoring ? null : _validateAndPreviewRestore,
                    child: const Text('Validate & Preview'),
                  ),
                ),
                if (_dryRunResult != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isRestoring ? null : _executeAtomicRestore,
                      child: const Text('Restore Database'),
                    ),
                  ),
                ],
              ],
            ),
            if (_dryRunResult != null) ...[
              const SizedBox(height: 16),
              _buildDryRunSummary(_dryRunResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDryRunSummary(RestoreResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 18),
              SizedBox(width: 6),
              Text(
                'Integrity & Decryption Verified',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ready to restore:\n'
            '• Accounts: ${result.restoredCounts['accounts'] ?? 0}\n'
            '• Categories: ${result.restoredCounts['categories'] ?? 0}\n'
            '• Transactions: ${result.restoredCounts['transactions'] ?? 0}\n'
            '• Subscriptions: ${result.restoredCounts['subscriptions'] ?? 0}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.expenseRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.expenseRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.expenseRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.expenseRed, fontSize: 13, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
