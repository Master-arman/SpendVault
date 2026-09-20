import 'package:finance_app/core/widgets/staggered_list_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 20: Staggered Entrance Animations Tests', () {
    testWidgets('AnimationConfiguration.staggeredList wraps child in StaggeredItem with 40ms delay',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnimationConfiguration.staggeredList(
                  position: 0,
                  delay: const Duration(milliseconds: 40),
                  child: const Text('Tile 0'),
                ),
                AnimationConfiguration.staggeredList(
                  position: 1,
                  delay: const Duration(milliseconds: 40),
                  child: const Text('Tile 1'),
                ),
                AnimationConfiguration.staggeredList(
                  position: 2,
                  delay: const Duration(milliseconds: 40),
                  child: const Text('Tile 2'),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify StaggeredItem and Text exist
      expect(find.byType(StaggeredItem), findsNWidgets(3));
      expect(find.text('Tile 0'), findsOneWidget);
      expect(find.text('Tile 1'), findsOneWidget);
      expect(find.text('Tile 2'), findsOneWidget);

      // Verify FadeTransition and SlideTransition widgets exist
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(SlideTransition), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('StaggeredListWrapper renders animated ListView',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaggeredListWrapper(
              itemCount: 5,
              delay: const Duration(milliseconds: 40),
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(StaggeredItem), findsNWidgets(5));

      await tester.pumpAndSettle();
    });
  });
}
