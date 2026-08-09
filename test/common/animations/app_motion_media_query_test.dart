import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/common/animations/app_motion_media_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('none and reduced presets both request root Reduced Motion', () {
    for (final AnimationPreset preset in AnimationPreset.values) {
      final bool expected =
          preset == AnimationPreset.none || preset == AnimationPreset.reduced;
      expect(preset.disableAnimations, expected, reason: preset.name);
      expect(
        AppearanceSettings(animationPreset: preset).disableAnimations,
        expected,
        reason: '${preset.name} AppearanceSettings',
      );
    }
  });

  for (final ({bool app, bool expected, bool platform}) scenario
      in <({bool app, bool expected, bool platform})>[
        (app: false, platform: false, expected: false),
        (app: true, platform: false, expected: true),
        (app: false, platform: true, expected: true),
      ]) {
    testWidgets('app=${scenario.app} platform=${scenario.platform} '
        'resolves disableAnimations=${scenario.expected}', (
      final WidgetTester tester,
    ) async {
      const Key probeKey = ValueKey<String>('motion-media-query-probe');
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: scenario.platform),
            child: AppMotionMediaQuery(
              appAnimationsDisabled: scenario.app,
              child: const SizedBox(key: probeKey),
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byKey(probeKey));
      expect(MediaQuery.disableAnimationsOf(context), scenario.expected);
    });
  }

  for (final ({AnimationPreset preset, bool expected, bool platform}) scenario
      in <({AnimationPreset preset, bool expected, bool platform})>[
        (preset: AnimationPreset.normal, platform: false, expected: false),
        (preset: AnimationPreset.reduced, platform: false, expected: true),
        (preset: AnimationPreset.none, platform: false, expected: true),
        (preset: AnimationPreset.enhanced, platform: true, expected: true),
      ]) {
    testWidgets('root merge honors ${scenario.preset.name} and '
        'platform=${scenario.platform}', (final WidgetTester tester) async {
      const Key probeKey = ValueKey<String>('preset-motion-probe');
      final AppearanceSettings appearance = AppearanceSettings(
        animationPreset: scenario.preset,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: scenario.platform),
            child: AppMotionMediaQuery(
              appAnimationsDisabled: appearance.disableAnimations,
              child: const SizedBox(key: probeKey),
            ),
          ),
        ),
      );

      expect(
        MediaQuery.disableAnimationsOf(tester.element(find.byKey(probeKey))),
        scenario.expected,
      );
    });
  }
}
