import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/context_dock/pills/basic_dock_pill.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:diohub/common/nav_center/builders/common_metadata_builders.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub_models/models/search/sort_config.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/common/nav_center/settings/settings_section.dart';
import 'package:diohub/common/nav_center/settings/settings_sheet_action_row.dart';
import 'package:diohub/common/nav_center/settings/settings_text_field_row.dart';
import 'package:diohub/common/nav_center/settings/settings_toggle_row.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/providers/users/user_contributions_provider.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/common/widgets/expandable_option_list_widget.dart'
    as option_list;
import 'package:diohub/common/widgets/metadata_composites.dart';
import 'package:diohub/common/widgets/metadata_rows.dart';
import 'package:diohub/common/widgets/metadata_section_sliver.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub/common/widgets/user_status_pill.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub/models/contributions/contribution_query_models.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub_models/models/database_types.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/contribution_query_utils.dart';
import 'package:diohub/utils/markdown_emoji.dart';
import 'package:diohub/view/profile/about/user_about_screen.dart';
import 'package:diohub/view/profile/about/widgets/tabbed_contribution_section.dart';
import 'package:diohub/view/profile/followers/profile_followers_tab.dart';
import 'package:diohub/view/profile/following/profile_following_tab.dart';
import 'package:diohub/view/profile/gists/profile_gists_tab.dart';
import 'package:diohub/view/profile/members/profile_members_tab.dart';
import 'package:diohub/view/profile/teams/profile_teams_tab.dart';
import 'package:diohub/view/profile/organizations/profile_organizations_tab.dart';
import 'package:diohub/view/profile/widgets/create_gist_sheet.dart';
import 'package:diohub/view/profile/widgets/email_management_sheet.dart';
import 'package:diohub/view/profile/packages/profile_packages_tab.dart';
import 'package:diohub/view/profile/projects/profile_projects_tab.dart';
import 'package:diohub/view/profile/sponsors/profile_sponsors_tab.dart';
import 'package:diohub/view/profile/stars/profile_stars_tab.dart';
import 'package:diohub/view/profile/watching/profile_watching_tab.dart';
import 'package:diohub/providers/users/keys_refresh_trigger_provider.dart';
import 'package:diohub/providers/profile/keys_tab_index_provider.dart';
import 'package:diohub/view/profile/keys/profile_keys_tab.dart';
import 'package:diohub/view/profile/widgets/gpg_key_sheet.dart';
import 'package:diohub/view/profile/widgets/key_cards.dart';
import 'package:diohub/common/popup/popup_section_assemblers.dart';
import 'package:diohub/view/profile/widgets/profile_popup_sections.dart';
import 'package:diohub/view/profile/widgets/config/profile_metadata_builders.dart';
import 'package:diohub/view/profile/widgets/config/profile_org_tabs.dart';
import 'package:diohub/view/profile/widgets/config/profile_settings_and_sheets.dart';
import 'package:diohub/view/profile/widgets/config/profile_user_tabs.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:diohub/common/events/events.dart';
import 'package:url_launcher/url_launcher.dart';

/// Extension to build NavCenter [ScreenConfig] from profile GQL data (user or org).
extension ProfileScreenConfigX on UserProfileOwner {
  ScreenConfig toScreenConfig(
    BuildContext context,
    WidgetRef widgetRef, {
    required int repoCount,
    required bool hasProfileReadme,
    required String? initialTabParam,
    required ContributionQueryKey contributionQueryKey,
    required ContributionTab contributionTab,
    required void Function(int) onYearChanged,
    required void Function(DateTime?, DateTime?) onCustomRangeChanged,
    required void Function(ContributionTab) onContributionTabChanged,
    required Future<void> Function({required bool follow}) onToggleFollow,
    UserRef? userRef,
  }) {
    final userData = this;
    final String login = userData.login;
    final UserRef ref = userRef ?? UserRef(login: login);

    final List<TabConfig> tabs = userData.maybeWhen(
      user: (UserProfile user) => buildUserTabs(
        user: user,
        repoCount: repoCount,
        hasProfileReadme: hasProfileReadme,
        contributionQueryKey: contributionQueryKey,
        contributionTab: contributionTab,
        onYearChanged: onYearChanged,
        onCustomRangeChanged: onCustomRangeChanged,
        onContributionTabChanged: onContributionTabChanged,
        ref: ref,
        widgetRef: widgetRef,
        context: context,
      ),
      organization: (OrgProfile org) => buildOrgTabs(
        org: org,
        repoCount: repoCount,
        hasProfileReadme: hasProfileReadme,
        ref: ref,
        widgetRef: widgetRef,
      ),
      orElse: () => <TabConfig>[
        reposPosition(login, repoCount, ref, false),
      ],
    );

    final EntityConfig entityConfig = EntityConfig(
      leading: Builder(
        builder: (BuildContext ctx) {
          final int cache =
              (44 * MediaQuery.of(ctx).devicePixelRatio).round().clamp(1, 512);
          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: userData.avatarUrl.toString(),
              width: 44,
              height: 44,
              memCacheWidth: cache,
              memCacheHeight: cache,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 44,
                height: 44,
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              ),
            ),
          );
        },
      ),
      title: Text(emoteText(userData.maybeWhen(
        user: (u) => u.name ?? u.login,
        organization: (o) => o.name ?? o.login,
        orElse: () => userData.login,
      ))),
      subtitle: Text('@${userData.login}'),
      statusIndicators: buildStatusIndicators(userData),
      metadataSections: buildMetadataSections(context, userData, repoCount),
      actionSections: userData.popupSections(context, widgetRef),
    );

    final String? text = expandedZoneText(userData);
    final List<ExpandedZoneDetail> details = expandedZoneDetails(userData);
    final List<ExpandedZoneDetail> expandedZoneContent =
        text != null && text.isNotEmpty
            ? <ExpandedZoneDetail>[ExpandedZoneText(text), ...details]
            : details;
    return ScreenConfig(
      entity: entityConfig,
      tabs: tabs,
      expandedZoneContent: expandedZoneContent,
      initialTabPath: initialTabParam,
      onRefresh: () async {
        widgetRef.invalidate(userProvider(ref));
      },
    );
  }
}

// ── Activity sheet helpers (Option B: bottom sheet) ────────────────────────

void _showActivityOverviewSheet(
  BuildContext context,
  ContributionTab contributionTab,
  void Function(ContributionTab) onContributionTabChanged,
) {
  final options = <option_list.ExpandableOption>[
    option_list.ExpandableOption(
      icon: Icons.insights_rounded,
      label: ContributionTab.overview.label,
      isSelected: contributionTab == ContributionTab.overview,
      onTap: () {
        onContributionTabChanged(ContributionTab.overview);
        Navigator.of(context).pop();
      },
    ),
    option_list.ExpandableOption(
      icon: Icons.show_chart_rounded,
      label: ContributionTab.deepDive.label,
      isSelected: contributionTab == ContributionTab.deepDive,
      onTap: () {
        onContributionTabChanged(ContributionTab.deepDive);
        Navigator.of(context).pop();
      },
    ),
    option_list.ExpandableOption(
      icon: Icons.timeline_rounded,
      label: ContributionTab.timeline.label,
      isSelected: contributionTab == ContributionTab.timeline,
      onTap: () {
        onContributionTabChanged(ContributionTab.timeline);
        Navigator.of(context).pop();
      },
    ),
  ];

  unawaited(
    AppSheet.simple<void>(
      context,
      header: AppSheetHeader.text('Contributions'),
      bodyBuilder: (BuildContext ctx, StateSetter setState) =>
          option_list.ExpandableOptionListWidget(
        options: options,
        onCollapse: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

void _showDateRangeSheet(
  BuildContext context,
  String userName,
  ContributionQueryKey currentQueryKey,
  DateTime? createdAt,
  void Function(int) onYearChanged,
  void Function(DateTime?, DateTime?) onCustomRangeChanged,
) {
  unawaited(
    AppSheet.simple<void>(
      context,
      header: AppSheetHeader.text('Date range'),
      bodyBuilder: (BuildContext ctx, StateSetter setState) =>
          _DateRangeExpandedContent(
        userName: userName,
        currentQueryKey: currentQueryKey,
        createdAt: createdAt,
        onYearChanged: onYearChanged,
        onCustomRangeChanged: onCustomRangeChanged,
        onCollapse: () => Navigator.of(ctx).pop(),
      ),
    ),
  );
}

class _DateRangeExpandedContent extends StatelessWidget {
  const _DateRangeExpandedContent({
    required this.userName,
    required this.currentQueryKey,
    required this.createdAt,
    required this.onYearChanged,
    required this.onCustomRangeChanged,
    required this.onCollapse,
  });

  final String userName;
  final ContributionQueryKey currentQueryKey;
  final DateTime? createdAt;
  final void Function(int) onYearChanged;
  final void Function(DateTime?, DateTime?) onCustomRangeChanged;
  final VoidCallback onCollapse;

  int? get _selectedYear => currentQueryKey.dateRange.displayYear;
  DateTime? get _customFromDate => currentQueryKey.dateRange.displayFromDate;
  DateTime? get _customToDate => currentQueryKey.dateRange.displayToDate;
  bool get _useCustomRange => currentQueryKey.dateRange.isCustomRange;

  Future<void> _showCustomDateRangePicker(
    BuildContext context,
    DateTime? earliestDate,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime initialFrom =
        _customFromDate ?? now.subtract(const Duration(days: 365));
    final DateTime initialTo = _customToDate ?? now;
    final DateTime earliest = earliestDate ?? DateTime(2000);

    final DateTime? pickedFrom = await showDatePicker(
      context: context,
      initialDate: initialFrom,
      firstDate: earliest,
      lastDate: now,
      helpText: 'Select start date',
    );
    if (pickedFrom == null) return;

    final DateTime? pickedTo = await showDatePicker(
      context: context,
      initialDate: pickedFrom.isAfter(initialTo) ? pickedFrom : initialTo,
      firstDate: pickedFrom,
      lastDate: now,
      helpText: 'Select end date',
    );
    if (pickedTo != null && context.mounted) {
      onCustomRangeChanged(pickedFrom, pickedTo);
      onCollapse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<int> availableYears = generateAvailableYears(createdAt);
    final dateRange = currentQueryKey.dateRange;
    final bool isLastYearSelected = dateRange.isLastYear;
    final bool isSinceJoiningSelected = _useCustomRange &&
        !isLastYearSelected &&
        isSinceJoining(
          useCustomRange: _useCustomRange,
          customFromDate: _customFromDate,
          createdAt: createdAt,
        );
    final bool isCustomSelected =
        _useCustomRange && !isLastYearSelected && !isSinceJoiningSelected;

    final List<option_list.ExpandableOption> options =
        <option_list.ExpandableOption>[];

    options.add(
      option_list.ExpandableOption(
        icon: Icons.calendar_today,
        label: 'Last Year',
        isSelected: isLastYearSelected,
        onTap: () => onCustomRangeChanged(null, null),
      ),
    );

    if (availableYears.isNotEmpty) {
      final List<int> sortedYears = List<int>.from(availableYears)
        ..sort((int a, int b) => b.compareTo(a));
      for (final int year in sortedYears) {
        options.add(
          option_list.ExpandableOption(
            icon: Icons.calendar_month,
            label: year.toString(),
            isSelected: !_useCustomRange && _selectedYear == year,
            onTap: () => onYearChanged(year),
          ),
        );
      }
    }

    if (createdAt != null) {
      options.add(
        option_list.ExpandableOption(
          icon: Icons.cake,
          label: 'Since joining GitHub',
          isSelected: isSinceJoiningSelected,
          onTap: () {
            final DateTime now = DateTime.now();
            onCustomRangeChanged(createdAt, now);
          },
        ),
      );
    }

    options.add(
      option_list.ExpandableOption(
        icon: Icons.date_range,
        label: 'Custom Range',
        isSelected: isCustomSelected,
        onTap: () => _showCustomDateRangePicker(context, createdAt),
        collapseOnTap: false,
      ),
    );

    return Container(
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Time Range',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: context.spacing.itemSpacing),
          option_list.ExpandableOptionListWidget(
            options: options,
            onCollapse: onCollapse,
          ),
        ],
      ),
    );
  }
}
