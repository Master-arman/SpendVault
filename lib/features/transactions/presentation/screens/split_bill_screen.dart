import 'package:finance_app/core/theme/app_colors.dart';
import 'package:finance_app/core/theme/theme_toggle_button.dart';
import 'package:finance_app/core/utils/currency_formatter.dart';
import 'package:finance_app/features/transactions/domain/bill_split_calculator.dart';
import 'package:finance_app/features/transactions/presentation/widgets/split_bill_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Screen for splitting group bills, computing debt shares, and tracking reimbursements.
class SplitBillScreen extends StatefulWidget {
  const SplitBillScreen({
    super.key,
    this.initialBillAmount = 1200.0,
    this.initialParticipants = 4,
    this.categoryName = 'Food & Dining',
  });

  final double initialBillAmount;
  final int initialParticipants;
  final String categoryName;

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  late final TextEditingController _billController;
  late int _participantsCount;
  late double _totalBill;
  late List<SplitParticipant> _participants;

  @override
  void initState() {
    super.initState();
    _totalBill = widget.initialBillAmount;
    _participantsCount = widget.initialParticipants;
    _billController = TextEditingController(text: _totalBill.toStringAsFixed(2));
    _generateParticipants();
  }

  void _generateParticipants() {
    final double perPerson = _participantsCount > 0 ? _totalBill / _participantsCount : _totalBill;
    _participants = [
      SplitParticipant(name: 'You (Host)', shareAmount: perPerson, isSettled: true),
      for (int i = 1; i < _participantsCount; i++)
        SplitParticipant(name: 'Participant $i', shareAmount: perPerson),
    ];
  }

  void _updateBill(String text) {
    final double? val = double.tryParse(text);
    if (val != null && val >= 0) {
      setState(() {
        _totalBill = val;
        _generateParticipants();
      });
    }
  }

  void _incrementParticipants() {
    HapticFeedback.selectionClick();
    setState(() {
      _participantsCount++;
      _generateParticipants();
    });
  }

  void _decrementParticipants() {
    if (_participantsCount > 2) {
      HapticFeedback.selectionClick();
      setState(() {
        _participantsCount--;
        _generateParticipants();
      });
    }
  }

  void _toggleSettled(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _participants[index].isSettled = !_participants[index].isSettled;
    });
  }

  @override
  void dispose() {
    _billController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BillSplitResult split = BillSplitCalculator.calculate(
      totalBill: _totalBill,
      participantsCount: _participantsCount,
    );

    final double settledReimbursement = _participants
        .where((p) => p.isSettled && p.name != 'You (Host)')
        .fold(0.0, (sum, p) => sum + p.shareAmount);

    final double remainingExpenseBucket = BillSplitCalculator.applyReimbursementToExpenseBucket(
      currentExpenseTotal: _totalBill,
      reimbursementAmount: settledReimbursement,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Bill & Reimburse'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Amount Input Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL BILL AMOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentIndigo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _billController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                          ),
                          onChanged: _updateBill,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Number of Participants Counter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Participants',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Including yourself',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _decrementParticipants,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: _participantsCount > 2 ? AppColors.indigoLight : AppColors.textDisabled,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCardElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_participantsCount',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _incrementParticipants,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.indigoLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Debt Calculation Summary Grid (User Share & Lent Amount)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR SHARE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(split.userShare),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigoLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('B / N (Actual Expense)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderStroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LENT AMOUNT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(split.lentAmount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warningAmber,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('B - (B / N) (To Collect)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Automated Tags Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderStroke),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag_rounded, size: 16, color: AppColors.indigoLight),
                  const SizedBox(width: 8),
                  const Text(
                    'Auto Tags:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 6,
                    children: BillSplitCalculator.splitTags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigoLight,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reimbursement Ledger List & Direct Category Offset
            const Text(
              'Group Debtors & Paybacks',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paybacks deduct directly from the ${widget.categoryName} expense bucket ($remainingExpenseBucket net bucket) instead of taxable income.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _participants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final participant = _participants[index];
                final bool isHost = participant.name == 'You (Host)';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: participant.isSettled ? AppColors.successGreen.withValues(alpha: 0.4) : AppColors.borderStroke,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            participant.isSettled ? Icons.check_circle_rounded : Icons.pending_rounded,
                            size: 18,
                            color: participant.isSettled ? AppColors.successGreen : AppColors.warningAmber,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            participant.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(participant.shareAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (!isHost) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _toggleSettled(index),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                backgroundColor: participant.isSettled
                                    ? AppColors.successGreen.withValues(alpha: 0.15)
                                    : AppColors.accentIndigo.withValues(alpha: 0.15),
                              ),
                              child: Text(
                                participant.isSettled ? 'Settled' : 'Mark Paid',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: participant.isSettled ? AppColors.successGreen : AppColors.indigoLight,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Share Breakdown & Save Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('screen_share_breakdown_button'),
                    onPressed: () async {
                      final buffer = StringBuffer();
                      buffer.writeln('🧾 Bill Split: ${widget.categoryName}');
                      buffer.writeln('💰 Total Bill: ${CurrencyFormatter.format(_totalBill)}');
                      buffer.writeln('👥 Total People: $_participantsCount');
                      buffer.writeln('------------------------------');
                      for (final p in _participants) {
                        buffer.writeln('• ${p.name}: ${CurrencyFormatter.format(p.shareAmount)}${p.isSettled ? " [Paid]" : " [Pending]"}');
                      }
                      buffer.writeln('------------------------------');
                      buffer.writeln('You owe ${CurrencyFormatter.format(split.userShare)} for ${widget.categoryName}.');

                      final shareText = buffer.toString();
                      await Share.share(
                        shareText,
                        subject: 'Bill Split Breakdown',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.accentCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.accentCyan),
                    label: const Text(
                      'Share Breakdown',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accentCyan),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    key: const Key('screen_custom_split_dialog_button'),
                    onPressed: () {
                      SplitBillDialog.show(
                        context: context,
                        initialTotalAmount: _totalBill,
                        initialTitle: widget.categoryName,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentIndigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text(
                      'Custom Split',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
