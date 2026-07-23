import 'package:diohub/common/animations/app_motion_media_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
