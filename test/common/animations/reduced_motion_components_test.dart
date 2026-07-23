import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/animations/animated_async_switcher.dart';
import 'package:diohub/common/animations/animated_content_switcher.dart'
    show AnimatedContentSwitcher;
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    final WidgetTester tester, {
    required final bool disableAnimations,
    required final Widget child,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          settingsCacheProvider.overrideWithValue(
            SettingsCache(<String, String>{}),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: child,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('platform Reduced Motion disables shimmer movement', (
    final WidgetTester tester,
  ) async {
    await pump(
      tester,
      disableAnimations: true,
      child: const ShimmerScope(child: SizedBox.square(dimension: 24)),
    );

    expect(
      find.byKey(const ValueKey<String>('shimmer-scope-static')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('shimmer-scope-animation')),
      findsNothing,
    );
  });

  testWidgets('explicit async duration cannot override Reduced Motion', (
    final WidgetTester tester,
  ) async {
    await pump(
      tester,
      disableAnimations: true,
      child: const AsyncData<int>(
        1,
      ).animatedWhen(data: _buildValue, duration: const Duration(seconds: 5)),
    );

    final AnimatedContentSwitcher switcher = tester
        .widget<AnimatedContentSwitcher>(find.byType(AnimatedContentSwitcher));
    expect(switcher.duration, Duration.zero);
  });
}

Widget _buildValue(final int value) => Text('$value');
