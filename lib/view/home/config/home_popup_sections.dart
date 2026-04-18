import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/common/misc/action_card_builder.dart';
import 'package:diohub/common/misc/collapsible_action_buttons.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/trailing_indicator.dart';
import 'package:diohub/common/popup/entity_popup_menu.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/providers/notifications/notification_count_provider.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/home/widgets/repo_picker_bottom_sheet.dart';
import 'package:diohub/view/home/widgets/switch_account_sheet.dart';
import 'package:diohub/view/repository/issues/widgets/template_picker_sheet.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';

TrailingIndicator? buildNotificationCountTrailing(WidgetRef ref) {
  return CountTrailing(() {
    final a = ref.read(unreadNotificationCountProvider);
    if (!a.hasValue) return null;
    final v = a.value!;
    return v > 0 ? v : null;
  });
}

List<PopupMenuSection> buildHomePopupSections(
  BuildContext context,
  WidgetRef ref,
  ViewerInfo viewer,
) {
  final String login = viewer.login;
  final String profileUrl = ref.webUrl('/$login').toString();

  final premiumRouting = ref.read(premiumRoutingProvider);
  final downloadsRoute = premiumRouting.downloadsRoute();
  final downloadPopupItems = ref
      .read(premiumActionsProvider)
      .downloadPopupItems(context, ref);

  return <PopupMenuSection>[
    PopupMenuSection(
      style: PopupSectionStyle.primary,
      actions: <ActionButtonData>[
        if (downloadsRoute != null && downloadPopupItems.isNotEmpty)
          ...downloadPopupItems.cast<ActionButtonData>(),
        if (downloadsRoute != null && downloadPopupItems.isEmpty)
          MinorActionButton(
            icon: Octicons.download,
            label: 'Downloads',
            onTap: () => AutoRouter.of(context).push(downloadsRoute),
          ),
        MinorActionButton(
          label: 'New Issue',
          icon: Octicons.plus,
          onTap: () async {
            final RepoRef? repoRef = await RepoPickerBottomSheet.show(
              context,
              login,
            );
            if (repoRef == null) return;
            try {
              final data = await ref.read(repositoryProvider(repoRef).future);
              final templates = data.repository?.issueTemplates?.toList() ?? [];
              final selected = await TemplatePickerSheet.show(
                context,
                templates: templates,
                showBlankOption: true,
              );
              await AutoRouter.of(
                context,
              ).push(NewIssueRoute(repoRef: repoRef, template: selected));
            } catch (e, st) {
              AppLogger.warning(
                'New issue navigation or template picker failed',
                error: e,
                stackTrace: st,
                tag: 'HomeScreenConfig',
              );
            }
          },
        ),
        MinorActionButton(
          label: 'Switch Account',
          icon: Icons.swap_horiz_rounded,
          onTap: () => SwitchAccountSheet.show(context, ref),
        ),
      ],
    ),
    PopupMenuSection(
      style: PopupSectionStyle.utility,
      actions: <ActionButtonData>[
        MinorActionButton(
          label: 'Copy Profile URL',
          icon: Icons.copy,
          onTap: () async {
            await ref.read(clipboardServiceProvider).copy(profileUrl);
          },
        ),
        MinorActionButton(
          label: 'Share Profile',
          icon: Icons.share,
          onTap: () => Share.share(profileUrl),
        ),
        MinorActionButton(
          label: 'Open in Browser',
          icon: Icons.open_in_browser,
          onTap: () => launchUrl(Uri.parse(profileUrl)),
        ),
      ],
    ),
  ];
}
