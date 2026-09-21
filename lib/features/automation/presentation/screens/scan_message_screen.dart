import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/features/automation/domain/bank_sms_parser.dart';
import 'package:finance_app/features/automation/presentation/widgets/confirm_transaction_dialog.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:flutter/material.dart';

/// Screen for scanning, pasting, and parsing bank SMS and OCR receipt messages.
/// Extracts monetary amounts via regular expressions and opens a confirmation review sheet before saving.
class ScanMessageScreen extends StatefulWidget {
  const ScanMessageScreen({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  State<ScanMessageScreen> createState() => _ScanMessageScreenState();
}

class _ScanMessageScreenState extends State<ScanMessageScreen> {
  late final TextEditingController _messageController;
  final BankSmsParser _smsParser = const BankSmsParser();

  // Preset sample SMS messages for testing and instant parsing
  final List<Map<String, String>> _sampleMessages = [
    {
      'title': 'Salary Deposit',
      'category': 'Income',
      'sms': 'Dear Customer, INR 75,000.00 credited to your A/C ending XX1234 on 21-Sep-2026 by Tech Corp Payroll. Ref: SAL-987654.',
    },
    {
      'title': 'Whole Foods Market',
      'category': 'Food & Dining',
      'sms': 'Your A/C ending XX4321 was debited with Rs. 1420.00 at Whole Foods Market on 21-Sep-2026. Info: POS txn.',
    },
    {
      'title': 'Swiggy Food Delivery',
      'category': 'Food & Dining',
      'sms': 'Sent ₹ 450.00 from A/C XX5678 to Swiggy UPI on 21-Sep-2026. UPI Ref 329847293.',
    },
    {
      'title': 'Uber Ride',
      'category': 'Transport',
      'sms': 'Paid INR 340.00 to Uber India via card ending 9988 on 21-Sep-2026. Ref: UBR9923.',
    },
    {
      'title': 'Apple Store Online',
      'category': 'Shopping',
      'sms': 'Spent Rs 2,499.00 on card ending 8812 at Apple Store Online on 21-Sep-2026.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.initialMessage ??
          'Dear Customer, INR 75,000.00 credited to your A/C ending XX1234 on 21-Sep-2026 by Tech Corp Payroll.',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Parses the input SMS text using regex and opens the review dialog.
  Future<void> _parseAndReview([String? overrideText]) async {
    final String smsBody = (overrideText ?? _messageController.text).trim();
    if (smsBody.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or paste an SMS message to parse')),
      );
      return;
    }

    // Standard Currency & Amount Regex Extraction
    final RegExp regex = RegExp(r'(?:INR|Rs\.?|₹|\$|€|£)\s*([\d,]+\.?\d*)', caseSensitive: false);
    final RegExpMatch? match = regex.firstMatch(smsBody);

    double detectedAmount = 0.0;
    if (match != null && match.group(1) != null) {
      final String rawAmount = match.group(1)!.replaceAll(',', '');
      detectedAmount = double.tryParse(rawAmount) ?? 0.0;
    }

    // Try domain parser for deeper entity recognition
    final parsed = _smsParser.parse(smsBody);
    if (parsed != null && detectedAmount == 0.0) {
      detectedAmount = parsed.amount;
    }

    // Detect Flow & Title
    final bool isCredit = smsBody.toLowerCase().contains('credit') ||
        smsBody.toLowerCase().contains('deposited') ||
        smsBody.toLowerCase().contains('received');

    String detectedTitle = 'Bank Transaction';
    // 1. Check known sample presets first
    for (final sample in _sampleMessages) {
      if (smsBody.toLowerCase().contains(sample['title']!.toLowerCase()) ||
          smsBody == sample['sms'] ||
          (sample['title'] == 'Whole Foods Market' && smsBody.toLowerCase().contains('whole foods'))) {
        detectedTitle = sample['title']!;
        break;
      }
    }

    // 2. Fallback to domain parser or keyword heuristics
    if (detectedTitle == 'Bank Transaction') {
      if (parsed != null && parsed.merchant != null && parsed.merchant!.isNotEmpty) {
        detectedTitle = parsed.merchant!;
      } else if (smsBody.toLowerCase().contains('salary')) {
        detectedTitle = 'Salary Deposit';
      } else if (smsBody.toLowerCase().contains('whole foods')) {
        detectedTitle = 'Whole Foods Market';
      } else if (smsBody.toLowerCase().contains('swiggy')) {
        detectedTitle = 'Swiggy';
      } else if (smsBody.toLowerCase().contains('uber')) {
        detectedTitle = 'Uber Ride';
      } else if (smsBody.toLowerCase().contains('apple')) {
        detectedTitle = 'Apple Store';
      }
    }

    // Clean any trailing date/info artifacts
    detectedTitle = detectedTitle
        .replaceAll(RegExp(r'\s+on\s+\d{1,2}[-/][A-Za-z0-9]+[-/]\d{2,4}.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+ref[:\s].*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+info[:\s].*$', caseSensitive: false), '')
        .trim();

    // Infer Category
    String detectedCategory = 'Shopping';
    if (isCredit) {
      detectedCategory = 'Income';
    } else if (detectedTitle.toLowerCase().contains('food') ||
        detectedTitle.toLowerCase().contains('swiggy') ||
        detectedTitle.toLowerCase().contains('restaurant')) {
      detectedCategory = 'Food & Dining';
    } else if (detectedTitle.toLowerCase().contains('uber') ||
        detectedTitle.toLowerCase().contains('ola') ||
        detectedTitle.toLowerCase().contains('fuel')) {
      detectedCategory = 'Transport';
    } else if (detectedTitle.toLowerCase().contains('apple') ||
        detectedTitle.toLowerCase().contains('amazon') ||
        detectedTitle.toLowerCase().contains('store')) {
      detectedCategory = 'Shopping';
    }

    // Crucial next step: Open pre-filled "Confirm Transaction" dialog for user review before saving
    final TransactionModel? confirmedTxn = await ConfirmTransactionDialog.show(
      context: context,
      initialAmount: detectedAmount,
      initialTitle: detectedTitle,
      initialCategory: detectedCategory,
      initialFlow: isCredit ? TransactionFlow.income : TransactionFlow.expense,
      rawMessage: smsBody,
    );

    if (confirmedTxn != null && mounted) {
      Navigator.of(context).pop(confirmedTxn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: const Key('scan_message_screen'),
      appBar: AppBar(
        title: const Text('Scan Message / SMS'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sms_rounded, color: AppColors.accentCyan, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Paste an SMS text alert or tap a banking preset below to extract amount, merchant, and category with real-time review.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SMS Text Input Area
            Text(
              'SMS / Notification Message Body',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                key: const Key('scan_message_input'),
                controller: _messageController,
                maxLines: 4,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste SMS message here (e.g. INR 1,420.00 debited at Whole Foods Market...)',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Parse & Review Button
            ElevatedButton.icon(
              key: const Key('parse_message_button'),
              onPressed: () => _parseAndReview(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.document_scanner_rounded, size: 20),
              label: const Text(
                'Parse & Review Transaction',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 24),

            // Presets Section
            Row(
              children: [
                const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.warningAmber),
                const SizedBox(width: 6),
                Text(
                  'Quick Test SMS Presets',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._sampleMessages.map((sample) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.25),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    title: Text(
                      sample['title']!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        sample['sms']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentIndigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Parse',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentIndigo,
                        ),
                      ),
                    ),
                    onTap: () {
                      _messageController.text = sample['sms']!;
                      _parseAndReview(sample['sms']!);
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
