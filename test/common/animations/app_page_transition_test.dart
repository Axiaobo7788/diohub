import 'package:diohub/common/animations/app_page_transition.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpTransition(
    final WidgetTester tester, {
    required final bool disableAnimations,
    final double progress = 0.5,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (final BuildContext context) => buildAppPageTransition(
              context,
              AlwaysStoppedAnimation<double>(progress),
              const AlwaysStoppedAnimation<double>(0),
              const SizedBox.expand(key: ValueKey<String>('page-child')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('migrated page transition uses shared motion tokens', (
    final WidgetTester tester,
  ) async {
    await pumpTransition(tester, disableAnimations: false);

    expect(
      find.byKey(const ValueKey<String>('app-page-fade-transition')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('app-page-slide-transition')),
      findsOneWidget,
    );
    expect(kPageTransitionDuration, const Duration(milliseconds: 240));
    expect(kPageTransitionReverseDuration, const Duration(milliseconds: 220));
  });

  testWidgets('page transition uses a visible logical-pixel offset', (
    final WidgetTester tester,
  ) async {
    await pumpTransition(tester, disableAnimations: false, progress: 0);

    expect(
      tester.getTopLeft(find.byKey(const ValueKey<String>('page-child'))).dx,
      closeTo(kPageTransitionOffset, 0.01),
    );
  });

  testWidgets('migrated page transition removes movement for Reduced Motion', (
    final WidgetTester tester,
  ) async {
    await pumpTransition(tester, disableAnimations: true);

    expect(
      find.byKey(const ValueKey<String>('app-page-fade-transition')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('app-page-slide-transition')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey<String>('page-child')), findsOneWidget);
  });
}
