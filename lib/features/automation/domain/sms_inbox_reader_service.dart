import 'dart:io';
import 'package:flutter/services.dart';
import 'package:finance_app/features/automation/domain/bank_sms_parser.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:finance_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:finance_app/features/transactions/domain/models/transaction_model.dart';
import 'package:finance_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:finance_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:finance_app/features/accounts/domain/models/account_model.dart';
import 'package:finance_app/features/accounts/domain/repositories/account_repository.dart';

class SmsSyncResult {
  const SmsSyncResult({
    required this.totalSmsRead,
    required this.transactionsParsed,
    required this.transactionsAdded,
    required this.transactions,
    this.errorMessage,
  });

  final int totalSmsRead;
  final int transactionsParsed;
  final int transactionsAdded;
  final List<TransactionModel> transactions;
  final String? errorMessage;
}

/// Service that reads incoming or stored SMS messages from the device inbox
/// and parses them into structured banking transactions.
class SmsInboxReaderService {
  factory SmsInboxReaderService() => _instance;
  SmsInboxReaderService._internal();
  static final SmsInboxReaderService _instance = SmsInboxReaderService._internal();

  static const MethodChannel _channel = MethodChannel('com.spendvault.app/sms_reader');
  final BankSmsParser _smsParser = const BankSmsParser();
  final TransactionRepository _transactionRepository = TransactionRepositoryImpl();
  final AccountRepository _accountRepository = AccountRepositoryImpl();

  /// Checks if SMS permission is granted on Android
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? has = await _channel.invokeMethod<bool>('hasSmsPermission');
      return has ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests SMS permission from the user
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('requestSmsPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Reads internal SMS inbox, parses bank messages, and imports them into SpendVault
  Future<SmsSyncResult> syncSmsInbox({int limit = 200}) async {
    if (!Platform.isAndroid) {
      return const SmsSyncResult(
        totalSmsRead: 0,
        transactionsParsed: 0,
        transactionsAdded: 0,
        transactions: [],
        errorMessage: 'SMS sync is only supported on Android devices.',
      );
    }

    final bool granted = await hasPermission();
    if (!granted) {
      final bool requested = await requestPermission();
      if (!requested) {
        return const SmsSyncResult(
          totalSmsRead: 0,
          transactionsParsed: 0,
          transactionsAdded: 0,
          transactions: [],
          errorMessage: 'SMS permission was denied. Please grant SMS permission in Android settings.',
        );
      }
    }

    try {
      final List<dynamic>? rawList = await _channel.invokeMethod<List<dynamic>>(
        'readSmsInbox',
        {'limit': limit},
      );

      if (rawList == null || rawList.isEmpty) {
        return const SmsSyncResult(
          totalSmsRead: 0,
          transactionsParsed: 0,
          transactionsAdded: 0,
          transactions: [],
        );
      }

      final existingTxns = await _transactionRepository.getTransactions(limit: 1000);
      final Set<String> existingSignatures = existingTxns.map((t) {
        if (t.referenceNumber != null && t.referenceNumber!.isNotEmpty) {
          return t.referenceNumber!;
        }
        return '${t.amount}_${t.date.millisecondsSinceEpoch}_${t.merchant}';
      }).toSet();

      final List<TransactionModel> newTransactions = [];
      int parsedCount = 0;

      for (final item in rawList) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final String body = map['body'] as String? ?? '';
        final String sender = map['sender'] as String? ?? '';
        final int dateMs = (map['date'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
        final DateTime date = DateTime.fromMillisecondsSinceEpoch(dateMs);

        final ParsedTransaction? parsed = _smsParser.parse(
          body,
          sender: sender,
          receivedAt: date,
        );

        if (parsed != null && parsed.amount > 0) {
          parsedCount++;
          final String signature = (parsed.referenceNumber != null && parsed.referenceNumber!.isNotEmpty)
              ? parsed.referenceNumber!
              : '${parsed.amount}_${date.millisecondsSinceEpoch}_${parsed.merchant}';

          if (!existingSignatures.contains(signature)) {
            existingSignatures.add(signature);

            final String category = _inferCategory(parsed.merchant ?? '', parsed.type);
            final String accountMasked = parsed.accountMasked ?? 'Primary';
            final String accountName = _resolveAccountName(sender, accountMasked);

            // Auto-register account if needed
            await _ensureAccountExists(accountName, accountMasked, parsed.type);

            final txn = TransactionModel(
              id: 'sms-txn-${date.millisecondsSinceEpoch}-${newTransactions.length}',
              title: (parsed.merchant != null && parsed.merchant!.isNotEmpty)
                  ? parsed.merchant!
                  : (parsed.type == TransactionType.credit ? 'Bank Deposit' : 'Bank Expense'),
              amount: parsed.amount,
              flow: parsed.type == TransactionType.credit ? TransactionFlow.income : TransactionFlow.expense,
              category: category,
              date: date,
              accountId: 'acc-${accountMasked.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
              accountName: accountName,
              merchant: parsed.merchant,
              referenceNumber: parsed.referenceNumber,
              note: 'Auto-imported from SMS ($sender)',
              isAutomated: true,
            );

            await _transactionRepository.addTransaction(txn);
            newTransactions.add(txn);
          }
        }
      }

      return SmsSyncResult(
        totalSmsRead: rawList.length,
        transactionsParsed: parsedCount,
        transactionsAdded: newTransactions.length,
        transactions: newTransactions,
      );
    } catch (e) {
      return SmsSyncResult(
        totalSmsRead: 0,
        transactionsParsed: 0,
        transactionsAdded: 0,
        transactions: [],
        errorMessage: 'Error reading SMS inbox: $e',
      );
    }
  }

  String _resolveAccountName(String sender, String accountMasked) {
    final s = sender.toUpperCase();
    String bank = 'Bank Account';
    if (s.contains('HDFC')) {
      bank = 'HDFC Bank';
    } else if (s.contains('SBI')) {
      bank = 'SBI';
    } else if (s.contains('ICICI')) {
      bank = 'ICICI Bank';
    } else if (s.contains('AXIS')) {
      bank = 'Axis Bank';
    } else if (s.contains('KOTAK')) {
      bank = 'Kotak Bank';
    } else if (s.contains('PNB') || s.contains('PUNJ')) {
      bank = 'PNB';
    } else if (s.contains('PAYTM')) {
      bank = 'Paytm Payments';
    } else if (s.contains('BOI')) {
      bank = 'Bank of India';
    } else if (s.contains('BOB')) {
      bank = 'Bank of Baroda';
    } else if (s.contains('YES')) {
      bank = 'Yes Bank';
    } else if (s.contains('IDFC')) {
      bank = 'IDFC First';
    }

    if (accountMasked.isNotEmpty && accountMasked != 'Primary') {
      return '$bank ($accountMasked)';
    }
    return bank;
  }

  Future<void> _ensureAccountExists(String name, String masked, TransactionType type) async {
    final accounts = await _accountRepository.getAccounts();
    final id = 'acc-${masked.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
    final bool exists = accounts.any((a) => a.id == id || a.name == name);
    if (!exists) {
      final newAcc = AccountModel(
        id: id,
        name: name,
        institutionName: name.split('(').first.trim(),
        accountNumberMasked: masked.startsWith('*') || masked.startsWith('X') ? masked : '****$masked',
        balance: 0.0,
        type: type == TransactionType.credit ? AccountType.bank : AccountType.bank,
        isDefault: accounts.isEmpty,
      );
      await _accountRepository.addAccount(newAcc);
    }
  }

  String _inferCategory(String merchant, TransactionType type) {
    if (type == TransactionType.credit) {
      return 'Income';
    }
    final m = merchant.toLowerCase();
    if (m.contains('swiggy') ||
        m.contains('zomato') ||
        m.contains('food') ||
        m.contains('restaurant') ||
        m.contains('cafe') ||
        m.contains('starbucks') ||
        m.contains('mcdonald') ||
        m.contains('burger') ||
        m.contains('pizza')) {
      return 'Food & Dining';
    }
    if (m.contains('uber') ||
        m.contains('ola') ||
        m.contains('rapido') ||
        m.contains('metro') ||
        m.contains('fuel') ||
        m.contains('petrol') ||
        m.contains('irctc') ||
        m.contains('flight') ||
        m.contains('transport')) {
      return 'Transport';
    }
    if (m.contains('amazon') ||
        m.contains('flipkart') ||
        m.contains('myntra') ||
        m.contains('apple') ||
        m.contains('store') ||
        m.contains('retail') ||
        m.contains('mart') ||
        m.contains('market') ||
        m.contains('blinkit') ||
        m.contains('zepto') ||
        m.contains('instamart') ||
        m.contains('grocery')) {
      return 'Shopping';
    }
    if (m.contains('netflix') ||
        m.contains('spotify') ||
        m.contains('hotstar') ||
        m.contains('prime') ||
        m.contains('youtube') ||
        m.contains('cinema') ||
        m.contains('movie') ||
        m.contains('pvr')) {
      return 'Entertainment';
    }
    if (m.contains('bill') ||
        m.contains('electricity') ||
        m.contains('bescom') ||
        m.contains('airtel') ||
        m.contains('jio') ||
        m.contains('recharge') ||
        m.contains('water') ||
        m.contains('gas')) {
      return 'Bills & Utilities';
    }
    if (m.contains('pharmacy') ||
        m.contains('hospital') ||
        m.contains('apollo') ||
        m.contains('medplus') ||
        m.contains('doctor') ||
        m.contains('health')) {
      return 'Health & Fitness';
    }
    return 'General';
  }
}
