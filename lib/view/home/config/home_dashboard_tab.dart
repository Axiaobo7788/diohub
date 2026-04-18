import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/view/home/dashboard/dashboard_section_composer.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

TabConfig buildDashboardTab(WidgetRef ref) {
  final showCustomize = ref
      .read(premiumScreensProvider)
      .showDashboardCustomizeSheet();
  return TabConfig(
    deeplinkPath: 'dashboard',
    label: 'Dashboard',
    icon: Octicons.home,
    category: TabCategory.primary,
    keepAlive: true,
    body: TabBodyPage(
      body: SliverBuilderBody(
        sliverBuilder: (ctx, ref) => [const DashboardSectionComposer()],
      ),
    ),
    dockActions: showCustomize != null
        ? (ctx, ref) => [
            BasicDockPill(
              iconData: Octicons.gear,
              label: 'Customize',
              onTapAction: (ref) => showCustomize(ctx, ref),
            ),
          ]
        : (ctx, ref) => [],
  );
}
