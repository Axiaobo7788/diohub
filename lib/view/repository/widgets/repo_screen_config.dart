import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/view/repository/widgets/config/repo_tabs.dart';
import 'package:diohub/common/widgets/status_flag_row.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/code_browser/code_browser_state_provider.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';

import 'package:diohub/common/nav_center/dock/bookmark_dock_pill.dart';
import 'package:diohub/providers/entity_store_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/view/repository/widgets/config/repo_entity_config.dart';

/// Extension to build NavCenter [ScreenConfig] from repository GQL data.
extension RepositoryScreenConfigX on RepoInfo {
  ScreenConfig toScreenConfig(
    BuildContext context,
    WidgetRef ref, {
    required RepoRef repoRef,
    required GlobalKey<RepositoryReadmeState> readmeStateKey,
    required Future<void> Function()? onRefresh,
    required Future<bool> Function(int tabIndex) onWillPop,
    String? initialTabPath,
  }) {
    final repo = this;
    final entity = repo.entityConfig(context, ref);
    final tabs = repo.tabs(context, ref, readmeStateKey: readmeStateKey);
    final List<StatusFlag> repoFlags = repo.statusFlags;
    final String? description = switch (repo.description) {
      final d? when d.isNotEmpty => d,
      _ => null,
    };
    final List<ExpandedZoneDetail> expandedZoneContent = <ExpandedZoneDetail>[
      if (description != null) ExpandedZoneText(description),
      if (repoFlags.isNotEmpty) FlagSummary(repoFlags),
    ];
    final int codeTabIndex = tabs.indexWhere(
      (TabConfig p) => p.label == 'Code',
    );
    final Future<bool> Function(int) wrappedOnWillPop = codeTabIndex >= 0
        ? (int tabIndex) async {
            if (tabIndex == codeTabIndex) {
              final popped = ref
                  .read(codeBrowserStateProvider(repoRef).notifier)
                  .popDirectory();
              if (popped) return false;
            }
            return onWillPop(tabIndex);
          }
        : onWillPop;
    return ScreenConfig(
      entity: entity,
      tabs: tabs,
      expandedZoneContent: expandedZoneContent,
      onRefresh: onRefresh,
      initialTabPath: initialTabPath,
      onWillPop: wrappedOnWillPop,
      screenInlineControls: (ctx, r) => [
        bookmarkDockPill(
          ref: r,
          entityRef: repoRef,
          snapshot: repo.toSnapshot(),
          contextRepo: repoRef,
        ),
      ],
    );
  }
}
