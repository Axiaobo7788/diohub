import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/tab_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  Future<ValueNotifier<int>> pumpTabs(
    final WidgetTester tester, {
    required final bool disableAnimations,
  }) async {
    final Duration previousInterval =
        VisibilityDetectorController.instance.updateInterval;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    addTearDown(() {
      VisibilityDetectorController.instance.updateInterval = previousInterval;
    });
    final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
    addTearDown(tabIndex.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: SizedBox(
            width: 400,
            height: 600,
            child: TabPageView(
              tabIndex: tabIndex,
              tabs: const <TabConfig>[
                TabConfig(
                  label: 'Conversation',
                  icon: Icons.chat_bubble_outline,
                  body: ColoredBox(
                    key: ValueKey<String>('conversation-tab'),
                    color: Colors.white,
                  ),
                ),
                TabConfig(
                  label: 'Timeline',
                  icon: Icons.timeline,
                  body: ColoredBox(
                    key: ValueKey<String>('timeline-tab'),
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return tabIndex;
  }

  testWidgets('detail tabs use the centralized interruptible transition', (
    final WidgetTester tester,
  ) async {
    final ValueNotifier<int> tabIndex = await pumpTabs(
      tester,
      disableAnimations: false,
    );
    final PageController controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;

    tabIndex.value = 1;
    await tester.pump();
    await tester.pump(kTabTransitionDuration ~/ 2);
    expect(controller.page, greaterThan(0));
    expect(controller.page, lessThan(1));

    await tester.pump(kTabTransitionDuration);
    expect(controller.page, 1);
  });

  testWidgets('detail tabs jump immediately for Reduced Motion', (
    final WidgetTester tester,
  ) async {
    final ValueNotifier<int> tabIndex = await pumpTabs(
      tester,
      disableAnimations: true,
    );
    final PageController controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;

    tabIndex.value = 1;
    await tester.pump();
    expect(controller.page, 1);
  });
}
