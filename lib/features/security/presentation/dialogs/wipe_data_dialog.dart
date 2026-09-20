import 'dart:io';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Phase 50: Secure Wipe & Database Factory Reset Dialog.
///
/// Safeguards:
/// 1. Requires the user to explicitly type the exact uppercase confirmation keyword "DELETE".
/// 2. The destructive "Factory Reset & Wipe All Data" action button remains strictly disabled
///    until the confirmation keyword matches identically.
/// 3. Executes an atomic Isar database purge (`isar.clear()`) and wipes all local cached receipt images.
class WipeDataDialog extends StatefulWidget {
  final Isar isar;
  final VoidCallback? onResetComplete;
  final Directory? receiptCacheDirectory;

  const WipeDataDialog({
    super.key,
    required this.isar,
    this.onResetComplete,
    this.receiptCacheDirectory,
  });

  /// Static helper to display the [WipeDataDialog].
  static Future<bool?> show(
    BuildContext context, {
    required Isar isar,
    VoidCallback? onResetComplete,
    Directory? receiptCacheDirectory,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WipeDataDialog(
        isar: isar,
        onResetComplete: onResetComplete,
        receiptCacheDirectory: receiptCacheDirectory,
      ),
    );
  }

  @override
  State<WipeDataDialog> createState() => _WipeDataDialogState();
}

class _WipeDataDialogState extends State<WipeDataDialog> {
  final TextEditingController _confirmationController = TextEditingController();
  bool _isWiping = false;
  String? _errorMessage;

  static const String confirmationKeyword = 'DELETE';

  bool get _isConfirmationValid => _confirmationController.text.trim() == confirmationKeyword;

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _executeSecureWipe() async {
    if (!_isConfirmationValid) return;

    setState(() {
      _isWiping = true;
      _errorMessage = null;
    });

    try {
      // 1. Atomic Isar Database Purge
      await widget.isar.writeTxn(() async {
        await widget.isar.clear();
      });

      // 2. Wipe Local Cached Receipt Images
      try {
        final Directory cacheDir =
            widget.receiptCacheDirectory ?? (await getTemporaryDirectory());
        if (cacheDir.existsSync()) {
          final List<FileSystemEntity> files = cacheDir.listSync(recursive: true);
          for (final file in files) {
            if (file is File) {
              final String name = file.path.toLowerCase();
              if (name.endsWith('.jpg') ||
                  name.endsWith('.jpeg') ||
                  name.endsWith('.png') ||
                  name.endsWith('.pdf') ||
                  name.contains('receipt')) {
                file.deleteSync();
              }
            }
          }
        }
      } catch (_) {
        // Continue even if specific cache file deletion encountered a harmless lock
      }

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
        widget.onResetComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWiping = false;
          _errorMessage = 'Failed to execute factory reset: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.expenseRed, width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.expenseRed,
            size: 28,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Factory Reset & Wipe',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.expenseRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.expenseRed.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'WARNING: This action is permanent and irreversible. All accounts, transactions, recurring subscriptions, budgets, audit logs, and cached receipt images will be permanently erased.',
                style: TextStyle(
                  color: AppColors.expenseRed,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To confirm, please type DELETE below:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('wipe_confirmation_input'),
              controller: _confirmationController,
              autofocus: true,
              enabled: !_isWiping,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  letterSpacing: 1.5,
                ),
                filled: true,
                fillColor: AppColors.darkSlateBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: _isConfirmationValid ? AppColors.expenseRed : AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.expenseRed, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isWiping ? null : () => Navigator.pop(context, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          key: const Key('confirm_wipe_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.expenseRed,
            disabledBackgroundColor: AppColors.expenseRed.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white54,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _isConfirmationValid && !_isWiping ? _executeSecureWipe : null,
          child: _isWiping
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Erase All Data'),
        ),
      ],
    );
  }
}
