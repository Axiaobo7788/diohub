import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/view/repository/md3/repository_tab_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('later Repository tab enters from the trailing side', (
    final WidgetTester tester,
  ) async {
    await _pumpTransition(tester, direction: 1);

    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('repository-tab-child')),
          )
          .dx,
      closeTo(kTabTransitionOffset, 0.01),
    );
  });

  testWidgets('earlier Repository tab enters from the leading side', (
    final WidgetTester tester,
  ) async {
    await _pumpTransition(tester, direction: -1);

    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('repository-tab-child')),
          )
          .dx,
      closeTo(-kTabTransitionOffset, 0.01),
    );
  });

  testWidgets('Reduced Motion keeps retained Repository tab stationary', (
    final WidgetTester tester,
  ) async {
    await _pumpTransition(tester, direction: 1, disableAnimations: true);

    expect(
      find.byKey(const ValueKey<String>('repository-tab-transition')),
      findsNothing,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('repository-tab-child')),
          )
          .dx,
      0,
    );
  });
}

Future<void> _pumpTransition(
  final WidgetTester tester, {
  required final int direction,
  final bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: RepositoryRetainedTabTransition(
          animation: const AlwaysStoppedAnimation<double>(0),
          direction: direction,
          child: const SizedBox.expand(
            key: ValueKey<String>('repository-tab-child'),
          ),
        ),
      ),
    ),
  );
}
