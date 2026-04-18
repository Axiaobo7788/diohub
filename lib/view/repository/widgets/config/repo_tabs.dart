import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot_factories.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub_graphql/schema_typedefs.dart';

import 'package:diohub/view/repository/widgets/config/repo_content_tabs.dart';
import 'package:diohub/view/repository/widgets/config/repo_info_tabs.dart';
import 'package:diohub/view/repository/widgets/config/repo_store_tabs.dart';
import 'package:diohub/view/repository/widgets/config/repo_management_tabs.dart';

typedef RepoTabContext = ({
  BuildContext context,
  WidgetRef ref,
  RepoRef repoRef,
  RepoInfo repo,
  RepositoryPermission? permission,
  String defaultBranchName,
});

List<TabConfig> buildTabs({
  required BuildContext context,
  required WidgetRef ref,
  required RepoRef repoRef,
  required RepoInfo repo,
  required GlobalKey<RepositoryReadmeState> readmeStateKey,
}) {
  final ctx = (
    context: context,
    ref: ref,
    repoRef: repoRef,
    repo: repo,
    permission: repo.viewerPermission,
    defaultBranchName: repo.defaultBranchRef?.name ?? 'main',
  );

  return [
    ...buildContentTabs(ctx, readmeStateKey),
    ...buildInfoTabs(ctx),
    ...buildStoreTabs(ctx),
    ...buildManagementTabs(ctx),
  ];
}

extension RepoInfoTabs on RepoInfo {
  List<TabConfig> tabs(
    BuildContext context,
    WidgetRef ref, {
    required GlobalKey<RepositoryReadmeState> readmeStateKey,
  }) =>
      buildTabs(
        context: context,
        ref: ref,
        repoRef: toRef,
        repo: this,
        readmeStateKey: readmeStateKey,
      );
}
