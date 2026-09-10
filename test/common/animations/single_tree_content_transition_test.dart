import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/animations/single_tree_content_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('peer content enters without retaining an outgoing subtree', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleTreeContentTransition(
            transitionKey: 'unread',
            horizontalDirection: 1,
            child: SizedBox.square(
              key: ValueKey<String>('single-real-tree'),
              dimension: 40,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('single-real-tree')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Transform>(
            find.byKey(
              const ValueKey<String>('single-tree-content-translation'),
            ),
          )
          .transform
          .getTranslation()
          .x,
      closeTo(kTabTransitionOffset, 0.01),
    );
  });

  testWidgets('single-tree content is static for Reduced Motion', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SingleTreeContentTransition(
            transitionKey: 'all',
            horizontalDirection: -1,
            child: SizedBox(key: ValueKey<String>('reduced-motion-content')),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('single-tree-content-translation')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('reduced-motion-content')),
      findsOneWidget,
    );
  });
}
