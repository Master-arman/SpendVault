import 'package:finance_app/core/constants/app_constants.dart';
import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/features/automation/domain/bank_sms_parser.dart';
import 'package:finance_app/features/automation/domain/payment_app_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Phase 30: Whitelist & Privacy Security Switches Screen.
/// Provides granular toggles to enable/disable specific banks, payment apps,
/// toggle auto-confirm mode, anomaly alerts, and clear historical notification parser logs.
class AutomationSettingsScreen extends StatefulWidget {
  const AutomationSettingsScreen({
    super.key,
    this.initialAutoConfirm = true,
    this.initialAnomalyDetection = true,
    this.initialNotificationSync = true,
    this.initialSmsSync = true,
    this.onClearLogs,
  });

  final bool initialAutoConfirm;
  final bool initialAnomalyDetection;
  final bool initialNotificationSync;
  final bool initialSmsSync;
  final Future<void> Function()? onClearLogs;

  @override
  State<AutomationSettingsScreen> createState() =>
      _AutomationSettingsScreenState();
}

class _AutomationSettingsScreenState extends State<AutomationSettingsScreen> {
  late bool _autoConfirm;
  late bool _anomalyDetection;
  late bool _notificationSync;
  late bool _smsSync;

  // Granular Whitelist states
  late Map<String, bool> _enabledPaymentApps;
  late Map<String, bool> _enabledBankSenders;

  int _auditLogsCount = 42; // Simulated active audit log count

  static const Map<String, String> _bankDisplayNames = {
    'HDFCBK': 'HDFC Bank',
    'SBIINB': 'State Bank of India',
    'AXISBK': 'Axis Bank',
    'ICICIB': 'ICICI Bank',
    'KOTAKB': 'Kotak Mahindra Bank',
    'PUNJNB': 'Punjab National Bank',
    'CANBNK': 'Canara Bank',
    'UNIONB': 'Union Bank of India',
    'INDUSB': 'IndusInd Bank',
    'YESBNK': 'Yes Bank',
    'BOIBNK': 'Bank of India',
    'FEDBNK': 'Federal Bank',
  };

  @override
  void initState() {
    super.initState();
    _autoConfirm = widget.initialAutoConfirm;
    _anomalyDetection = widget.initialAnomalyDetection;
    _notificationSync = widget.initialNotificationSync;
    _smsSync = widget.initialSmsSync;

    _enabledPaymentApps = {
      for (final pkg in PaymentAppFilter.paymentApps.keys) pkg: true,
    };

    _enabledBankSenders = {
      for (final bank in BankSmsParser.verifiedBankSenders) bank: true,
    };
  }

  void _toggleAllPaymentApps(bool enable) {
    HapticFeedback.selectionClick();
    setState(() {
      for (final key in _enabledPaymentApps.keys) {
        _enabledPaymentApps[key] = enable;
      }
    });
  }

  void _toggleAllBankSenders(bool enable) {
    HapticFeedback.selectionClick();
    setState(() {
      for (final key in _enabledBankSenders.keys) {
        _enabledBankSenders[key] = enable;
      }
    });
  }

  Future<void> _showClearLogsDialog() async {
    HapticFeedback.mediumImpact();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderStroke),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: AppColors.expenseRed, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Clear Historical Logs?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'This will permanently delete all raw notification audit logs, deduplication hashes, and fallback SMS traces stored on this device.\n\nYour recorded ledger transactions will remain safe and unaffected.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expenseRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text(
                'Clear All Logs',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      if (widget.onClearLogs != null) {
        await widget.onClearLogs!();
      }
      setState(() {
        _auditLogsCount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Historical parser logs wiped successfully.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeAppsCount =
        _enabledPaymentApps.values.where((v) => v).length;
    final int activeBanksCount =
        _enabledBankSenders.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: AppColors.darkSlateBackground,
      appBar: AppBar(
        title: const Text(
          'Automation & Privacy',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('automation_scroll_view'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Privacy Shield Hero Banner
            _buildHeroShieldBanner(),

            const SizedBox(height: 24),
            _buildSectionHeader('MASTER ENGINE CONTROLS', Icons.tune_rounded),
            const SizedBox(height: 12),
            _buildMasterControlsCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('CONFIRMATION & ANOMALY RULES', Icons.shield_rounded),
            const SizedBox(height: 12),
            _buildConfirmationRulesCard(),

            const SizedBox(height: 24),
            _buildSectionHeaderWithAction(
              'PAYMENT APPS WHITELIST ($activeAppsCount/${_enabledPaymentApps.length})',
              Icons.account_balance_wallet_outlined,
              onToggleAll: (all) => _toggleAllPaymentApps(all),
              allActive: activeAppsCount == _enabledPaymentApps.length,
            ),
            const SizedBox(height: 12),
            _buildPaymentAppsCard(),

            const SizedBox(height: 24),
            _buildSectionHeaderWithAction(
              'BANK SMS SENDER CODES ($activeBanksCount/${_enabledBankSenders.length})',
              Icons.account_balance_rounded,
              onToggleAll: (all) => _toggleAllBankSenders(all),
              allActive: activeBanksCount == _enabledBankSenders.length,
            ),
            const SizedBox(height: 12),
            _buildBankSendersCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('PRIVACY ARCHITECTURE', Icons.verified_user_rounded),
            const SizedBox(height: 12),
            _buildPrivacyConsentCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('AUDIT LOGS & DATA HYGIENE', Icons.history_edu_rounded),
            const SizedBox(height: 12),
            _buildAuditLogCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroShieldBanner() {
    return Material(
      color: const Color(0xFF1E294B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: const Icon(
                Icons.security_rounded,
                color: AppColors.indigoLight,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Zero Cloud Ingestion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.successGreen,
                        size: 16,
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '100% on-device deterministic regex parsing. OTPs, passwords, and private chats are never read or stored.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.indigoLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderWithAction(
    String title,
    IconData icon, {
    required ValueChanged<bool> onToggleAll,
    required bool allActive,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.indigoLight),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => onToggleAll(!allActive),
          child: Text(
            allActive ? 'Disable All' : 'Enable All',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.indigoLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterControlsCard() {
    return Material(
      color: AppColors.surfaceCard,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _notificationSync,
            title: const Text(
              'Notification Listener Service',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Capture instant expense pushes from supported payment apps.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _notificationSync = val);
            },
          ),
          const Divider(height: 1, color: AppColors.borderStroke),
          SwitchListTile(
            value: _smsSync,
            title: const Text(
              'Bank SMS Fallback Engine',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Parse debit/credit SMS when push notifications are absent.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _smsSync = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRulesCard() {
    return Material(
      color: AppColors.surfaceCard,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _autoConfirm,
            title: const Text(
              'Auto-Confirm Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              _autoConfirm
                  ? 'Automatically saves detected transaction after 10-second timer countdown.'
                  : 'Requires manual tap on [Confirm] to persist detected transactions.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _autoConfirm = val);
            },
          ),
          const Divider(height: 1, color: AppColors.borderStroke),
          SwitchListTile(
            value: _anomalyDetection,
            title: const Row(
              children: [
                Text(
                  'Anomaly & Fraud Surge Alert',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'Flag unusual expenses exceeding 3-sigma (μ + 3σ) with high-priority warning chip.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _anomalyDetection = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAppsCard() {
    final apps = PaymentAppFilter.paymentApps.entries.toList();

    return Material(
      color: AppColors.surfaceCard,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Column(
        children: [
          for (int i = 0; i < apps.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.borderStroke),
            _buildPaymentAppTile(apps[i].key, apps[i].value),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentAppTile(String pkg, String name) {
    final bool isEnabled = _enabledPaymentApps[pkg] ?? true;
    return SwitchListTile(
      key: Key('switch_app_$pkg'),
      value: isEnabled,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceCardHover,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.phone_android_rounded,
          size: 20,
          color: isEnabled ? AppColors.indigoLight : AppColors.textDisabled,
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
      subtitle: Text(
        pkg,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'monospace',
          color: AppColors.textMuted,
        ),
      ),
      onChanged: (val) {
        HapticFeedback.selectionClick();
        setState(() => _enabledPaymentApps[pkg] = val);
      },
    );
  }

  Widget _buildBankSendersCard() {
    const bankCodes = BankSmsParser.verifiedBankSenders;

    return Material(
      color: AppColors.surfaceCard,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Column(
        children: [
          for (int i = 0; i < bankCodes.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.borderStroke),
            _buildBankSenderTile(bankCodes[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildBankSenderTile(String code) {
    final String name = _bankDisplayNames[code] ?? code;
    final bool isEnabled = _enabledBankSenders[code] ?? true;

    return SwitchListTile(
      key: Key('switch_bank_$code'),
      value: isEnabled,
      secondary: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceCardHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.borderStroke,
          ),
        ),
        child: Text(
          code,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isEnabled ? AppColors.indigoLight : AppColors.textDisabled,
          ),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isEnabled ? AppColors.textPrimary : AppColors.textMuted,
        ),
      ),
      onChanged: (val) {
        HapticFeedback.selectionClick();
        setState(() => _enabledBankSenders[code] = val);
      },
    );
  }

  Widget _buildPrivacyConsentCard() {
    return Material(
      color: AppColors.surfaceCard,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.indigoLight,
            size: 22,
          ),
        ),
        title: const Text(
          'Privacy Architecture & Consent',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: const Text(
          'Review on-device permission guarantees and security safeguards.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pushNamed(AppConstants.notificationConsentRoute);
        },
      ),
    );
  }

  Widget _buildAuditLogCard() {
    return Material(
      color: AppColors.surfaceCard,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.borderStroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historical Audit Records',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCardHover,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderStroke),
                  ),
                  child: Text(
                    '$_auditLogsCount logs stored',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Raw parsed logs are cached locally for deduplication and troubleshooting. You can purge them at any time.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('clear_audit_logs_button'),
                onPressed: _showClearLogsDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.expenseRed,
                  side: BorderSide(color: AppColors.expenseRed.withValues(alpha: 0.5)),
                  backgroundColor: AppColors.expenseRed.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text(
                  'Clear Historical Audit Logs',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
