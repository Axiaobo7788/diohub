import 'package:diohub/common/misc/ref_list_item.dart';
import 'package:diohub/common/misc/repository_card.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub_models/models/commits/commit_card_data_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
// ignore: no_view_import_in_common
import 'package:diohub/view/profile/about/widgets/contribution_breakdown_row.dart';
import 'package:flutter/material.dart';

/// Unified timeline content for commit/push events
class TimelineCommitContent extends StatelessWidget {
  const TimelineCommitContent({
    required this.commitData,
    this.branchName,
    this.userLogin,
    this.userEmail,
    super.key,
  });

  final CommitCardDataModel commitData;
  final String? branchName;
  final String? userLogin;
  final String? userEmail;

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...commitData.repositories.map((final CommitRepositoryInfo repoInfo) {
            if (repoInfo.repoCardFields != null) {
              final repoCard = repoInfo.repoCardFields!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  BorderedContainer(
                    ref: RepoRef.fromRepoCardFields(repoCard),
                    child: RepositoryCard(repoCard),
                  ),
                  if (branchName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RefListItem(
                        variant: RefListItemVariant.branch,
                        branchData: RefListItemBranchData(name: branchName!),
                      ),
                    ),
                  if (repoInfo.count > 0)
                    ContributionBreakdownRow(commits: repoInfo.count),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  RepoCardLoading(
                    RepoRef.fromApiUrl(repoInfo.url),
                  ),
                  if (branchName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RefListItem(
                        variant: RefListItemVariant.branch,
                        branchData: RefListItemBranchData(name: branchName!),
                      ),
                    ),
                  if (repoInfo.count > 0)
                    ContributionBreakdownRow(commits: repoInfo.count),
                ],
              );
            }
          }),
        ],
      );
}
