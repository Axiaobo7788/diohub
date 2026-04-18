import 'package:diohub/common/misc/profile_banner.dart';
import 'package:diohub/common/nav_center/models/entity_config.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/screen_config.dart';
import 'package:diohub/common/widgets/user_status_pill.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/home/config/home_popup_sections.dart';
import 'package:diohub/view/home/config/home_primary_tabs.dart';
import 'package:diohub/view/home/config/home_secondary_positions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pure config builder for the Home screen.
///
/// Returns a [ScreenConfig] that declaratively describes all 8 positions,
/// the entity header (user info), and popup sections (downloads, new issue,
/// switch account, utilities). [NavCenterShell] consumes the config.
ScreenConfig buildHomeScreenConfig({
  required ViewerInfo viewer,
  required WidgetRef ref,
  required BuildContext context,
  String? filter,
  String? initialTabPath,
  List<ExpandedZoneDetail>? expandedZoneContent,
  Widget? bottomOverlay,
  required Widget Function(
    BuildContext, [
    ValueNotifier<Future<void> Function()?>?,
  ]) eventsViewBuilder,
  required TabBody orgsBody,
}) {
  final ValueNotifier<Future<void> Function()?> notificationsRefreshRegistrar =
      ValueNotifier<Future<void> Function()?>(null);
  final ValueNotifier<Future<void> Function()?> feedRefreshRegistrar =
      ValueNotifier<Future<void> Function()?>(null);
  final List<TabConfig> tabs = <TabConfig>[
    ...buildTabs(context, ref, viewer, eventsViewBuilder,
        feedRefreshRegistrar, notificationsRefreshRegistrar),
    ...buildHomeSecondaryPositions(context, ref, viewer, orgsBody),
  ];

  final String name =
      viewer.name?.trim().isNotEmpty == true ? viewer.name! : viewer.login;
  final String? subtitle =
      viewer.name?.trim().isNotEmpty == true ? '@${viewer.login}' : null;

  final EntityConfig entityConfig = EntityConfig(
    leading: ProfileTile.avatar(
      avatarUrl: viewer.avatarUrl.toString(),
      userLogin: viewer.login,
      padding: EdgeInsets.zero,
      size: 44,
    ),
    title: Text(name),
    subtitle: subtitle != null ? Text(subtitle) : null,
    statusIndicators: viewer.status?.message != null
        ? UserStatusPill(
            emoji: viewer.status!.emoji,
            message: viewer.status!.message,
            indicatesLimitedAvailability:
                viewer.status!.indicatesLimitedAvailability,
            compact: true,
          )
        : null,
    metadataSections: const <MetadataSectionData>[],
    actionSections: buildHomePopupSections(context, ref, viewer),
  );

  return ScreenConfig(
    entity: entityConfig,
    tabs: tabs,
    initialTabPath: initialTabPath ?? 'dashboard',
    expandedZoneContent: expandedZoneContent,
    bottomOverlay: bottomOverlay,
    onRefresh: () async => ref.invalidate(currentUserProvider),
  );
}
