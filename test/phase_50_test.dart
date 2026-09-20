import 'dart:io';
import 'package:finance_app/features/security/presentation/dialogs/wipe_data_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class MockIsar implements Isar {
  bool cleared = false;
  bool transactionCalled = false;

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) async {
    transactionCalled = true;
    return await callback();
  }

  @override
  Future<void> clear() async {
    cleared = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 50: Secure Wipe & Database Factory Reset Tests', () {
    late MockIsar mockIsar;
    late Directory tempReceiptsDir;

    setUp(() async {
      mockIsar = MockIsar();
      tempReceiptsDir = await Directory.systemTemp.createTemp('wipe_test_receipts_');
      final sampleReceipt = File('${tempReceiptsDir.path}/receipt_001.jpg');
      await sampleReceipt.writeAsString('sample dummy image data');
    });

    tearDown(() async {
      if (await tempReceiptsDir.exists()) {
        await tempReceiptsDir.delete(recursive: true);
      }
    });

    testWidgets('1. Safeguard: Erase button is initially disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WipeDataDialog(
              isar: mockIsar,
              receiptCacheDirectory: tempReceiptsDir,
            ),
          ),
        ),
      );

      expect(find.text('Factory Reset & Wipe'), findsOneWidget);
      expect(find.byKey(const Key('wipe_confirmation_input')), findsOneWidget);

      final ElevatedButton eraseButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('confirm_wipe_button')),
      );

      expect(eraseButton.onPressed, isNull);
    });

    testWidgets('2. Safeguard: Typing invalid text keeps button disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WipeDataDialog(
              isar: mockIsar,
              receiptCacheDirectory: tempReceiptsDir,
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('wipe_confirmation_input')), 'delete');
      await tester.pumpAndSettle();

      ElevatedButton eraseButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('confirm_wipe_button')),
      );
      expect(eraseButton.onPressed, isNull);

      await tester.enterText(find.byKey(const Key('wipe_confirmation_input')), 'CONFIRM');
      await tester.pumpAndSettle();

      eraseButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('confirm_wipe_button')),
      );
      expect(eraseButton.onPressed, isNull);
    });

    testWidgets('3. Confirmation: Typing exact keyword "DELETE" enables button and executes atomic reset', (tester) async {
      bool resetCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => WipeDataDialog.show(
                  ctx,
                  isar: mockIsar,
                  receiptCacheDirectory: tempReceiptsDir,
                  onResetComplete: () {
                    resetCompleted = true;
                  },
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('wipe_confirmation_input')), 'DELETE');
      await tester.pumpAndSettle();

      final ElevatedButton eraseButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('confirm_wipe_button')),
      );
      expect(eraseButton.onPressed, isNotNull);

      // Tap Erase All Data
      await tester.tap(find.byKey(const Key('confirm_wipe_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockIsar.transactionCalled, isTrue);
      expect(mockIsar.cleared, isTrue);
      expect(resetCompleted, isTrue);

      // Verify cached receipt images were wiped
      final List<FileSystemEntity> remainingFiles = tempReceiptsDir.listSync();
      expect(remainingFiles.isEmpty, isTrue);
    });

    testWidgets('4. Cancel button dismisses dialog without modifying database', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => WipeDataDialog.show(
                  ctx,
                  isar: mockIsar,
                  receiptCacheDirectory: tempReceiptsDir,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Factory Reset & Wipe'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Factory Reset & Wipe'), findsNothing);
      expect(mockIsar.cleared, isFalse);
    });
  });
}
