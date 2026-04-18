import 'package:diohub_models/models/app_config.dart';
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/nav_center/dock/bookmark_dock_pill.dart';
import 'package:diohub/common/cards/issue_pull_card_data.dart';
import 'package:diohub/common/cards/state_chip.dart';
import 'package:diohub/common/issues/issue_label.dart';
import 'package:diohub/common/issues/lock_reason_picker.dart';
import 'package:diohub/common/misc/entity_header.dart';
import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub/common/misc/tap_feedback.dart';
import 'package:diohub/common/widgets/log_entry_card.dart';
import 'package:diohub/providers/logging/log_providers.dart';
import 'package:diohub/view/common/entity_logs_position.dart';
import 'package:diohub/view/logs/log_detail_sheet.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/settings/nav_center_settings.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_content_slivers.dart';
import 'package:diohub/view/issues_pulls/widgets/discussion_detail_payload.dart';
import 'package:diohub/common/popup/popup_section_assemblers.dart';
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_graphql/fragments/common_exports.dart';
import 'package:diohub_graphql/queries/issues_pulls/review_typedefs.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub_models/models/visual_state.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:diohub/providers/issue_pulls/issue_providers.dart';
import 'package:diohub/providers/issue_pulls/pr_review_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/issues_pulls/builders/shared_metadata_builders.dart';
import 'package:diohub/view/issues_pulls/widgets/pull_commits_view.dart';
import 'package:diohub/view/issues_pulls/participants/participants_position.dart';
import 'package:diohub/view/issues_pulls/pull_request/files_changed/files_changed_position.dart'
    show buildFilesChangedSlivers, FilesChangedSortOrder;
import 'package:diohub/view/issues_pulls/widgets/pull_screen_utils.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/view/issues_pulls/widgets/milestone_select_sheet.dart';
import 'package:diohub/view/issues_pulls/widgets/project_select_sheet.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/cards/popup_chip_builders.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/pagination/unfinished_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:diohub/view/issues_pulls/widgets/config/pull_metadata_builders.dart';
import 'package:diohub/view/issues_pulls/widgets/config/pull_tabs.dart';

/// Extension to build NavCenter [ScreenConfig] from pull request GQL data.
extension PullScreenConfigX on PullInfo {
  ScreenConfig toScreenConfig(
    BuildContext context,
    WidgetRef ref, {
    required PullRequestRef pullRef,
    required VoidCallback onRefresh,
    List<Widget> Function(BuildContext)? checksSliverBuilder,
    List<Widget> Function(BuildContext)? linkedIssuesSliverBuilder,
    DateTime? commentsSince,
    String? scrollToCommentId,
  }) {
    final data = this;
    return ScreenConfig(
      entity: data.toEntityConfig(context, ref),
      tabs: data.tabs(
        context,
        ref,
        checksSliverBuilder: checksSliverBuilder,
        linkedIssuesSliverBuilder: linkedIssuesSliverBuilder,
        commentsSince: commentsSince,
        scrollToCommentId: scrollToCommentId,
      ),
      onRefresh: () async => onRefresh(),
      expandedZoneContent: <ExpandedZoneDetail>[
        if (data.titleHTMLAsString.isNotEmpty)
          ExpandedZoneText(data.titleHTMLAsString),
        if (data.statusFlags.isNotEmpty) FlagSummary(data.statusFlags),
      ],
      screenInlineControls: (ctx, r) => [
        bookmarkDockPill(
          ref: r,
          entityRef: pullRef,
          snapshot: data.toSnapshot(),
          contextRepo: pullRef.repo,
        ),
      ],
    );
  }
}
