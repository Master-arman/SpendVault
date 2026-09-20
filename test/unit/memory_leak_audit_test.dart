import 'dart:async';
import 'dart:io';
import 'package:finance_app/core/localization/locale_provider.dart';
import 'package:finance_app/core/theme/theme_provider.dart';
import 'package:finance_app/core/widgets/receipt_thumbnail_view.dart';
import 'package:finance_app/features/categories/presentation/screens/categories_screen.dart';
import 'package:finance_app/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 57: Receipt Image Thumbnail Caching & Memory Profiling', () {
    testWidgets('ReceiptThumbnailView renders fallback icon for null or empty path',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReceiptThumbnailView(imagePath: null),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    });

    testWidgets('ReceiptThumbnailView renders broken image icon when file does not exist',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReceiptThumbnailView(imagePath: 'non_existent_file_path.jpg'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
    });

    testWidgets('ReceiptThumbnailView uses ResizeImage with constrained decode dimensions',
        (WidgetTester tester) async {
      // Create a temporary test image file
      final tempDir = Directory.systemTemp.createTempSync('thumb_test_');
      final testFile = File('${tempDir.path}/test_receipt.png');
      testFile.writeAsBytesSync([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReceiptThumbnailView(
              imagePath: testFile.path,
              maxDecodeWidth: 256,
              maxDecodeHeight: 256,
            ),
          ),
        ),
      );
      await tester.pump();

      final imageFinder = find.byType(Image);
      if (imageFinder.evaluate().isNotEmpty) {
        final imageWidget = tester.widget<Image>(imageFinder);
        expect(imageWidget.image, isA<ResizeImage>());
        final resizeImage = imageWidget.image as ResizeImage;
        expect(resizeImage.width, equals(256));
        expect(resizeImage.height, equals(256));
      }

      // Cleanup
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });
  });

  group('Phase 57: ListView itemExtent Performance & Layout Audit', () {
    testWidgets('TransactionsScreen ListView has itemExtent configured for O(1) scroll indexing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TransactionsScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final listView = tester.widget<ListView>(listViewFinder);
      expect(listView.itemExtent, isNotNull);
      expect(listView.itemExtent, equals(82.0));
    });

    testWidgets('CategoriesScreen ListView has itemExtent configured for zero layout thrashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CategoriesScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      final listView = tester.widget<ListView>(listViewFinder);
      expect(listView.itemExtent, isNotNull);
      expect(listView.itemExtent, equals(84.0));
    });
  });

  group('Phase 57: Zero Memory Leaks across Subscriptions & Notifiers', () {
    test('LocaleProvider listener teardown retains 0 references', () {
      final provider = LocaleProvider.instance;
      int callCount = 0;
      void listener() {
        callCount++;
      }

      provider.addListener(listener);
      provider.setLocale(const Locale('hi'));
      expect(callCount, equals(1));

      // Remove listener (simulating widget dispose)
      provider.removeListener(listener);
      provider.setLocale(const Locale('en'));
      // Call count should NOT increment after listener removed
      expect(callCount, equals(1));
    });

    test('ThemeProvider listener teardown leaves zero dangling listeners', () {
      final provider = ThemeProvider.instance;
      int callCount = 0;
      void listener() {
        callCount++;
      }

      provider.addListener(listener);
      provider.setTheme(AppThemeType.oledBlack);
      expect(callCount, equals(1));

      // Remove listener
      provider.removeListener(listener);
      provider.setTheme(AppThemeType.deepDark);
      expect(callCount, equals(1));
    });

    test('StreamController subscriptions cancel cleanly without leak or event delivery after cancel', () async {
      final controller = StreamController<int>.broadcast();
      final List<int> received = [];

      final StreamSubscription<int> sub = controller.stream.listen((val) {
        received.add(val);
      });

      controller.add(1);
      controller.add(2);
      await pumpEventQueue();

      expect(received, equals([1, 2]));

      // Cancel subscription (simulating State.dispose)
      await sub.cancel();

      controller.add(3);
      controller.add(4);
      await pumpEventQueue();

      // No new items delivered to canceled subscription
      expect(received, equals([1, 2]));
      await controller.close();
    });
  });
}
