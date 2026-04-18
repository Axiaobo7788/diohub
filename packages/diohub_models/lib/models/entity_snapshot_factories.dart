import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/fragments/repo_card_fields.graphql.dart';

import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';

import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

import 'package:diohub_models/models/canonical_node_id.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub_models/models/repositories/repository_model.dart';

extension RepoCardSnapshot on RepoCardData {
  EntitySnapshot toSnapshot() => EntitySnapshot(
        title: name,
        language: primaryLanguage?.name,
        languageColor: primaryLanguage?.color,
        stars: stargazerCount,
        isPrivate: isPrivate,
        isFork: isFork,
        isArchived: isArchived,
        authorLogin: owner.when(
          organization: (o) => o.login,
          user: (u) => u.login,
          orElse: () => '',
        ),
        authorAvatarUrl: owner.when(
          organization: (o) => o.avatarUrl,
          user: (u) => u.avatarUrl,
          orElse: () => '',
        ).toString(),
        updatedAt: pushedAt,
      );
}

extension IssueCardSnapshot on IssueCardData {
  EntitySnapshot toSnapshot() => EntitySnapshot(
        title: title,
        state: issueState.name.toLowerCase(),
        stateReason: stateReason?.name.toLowerCase(),
        authorLogin: author?.login,
        authorAvatarUrl: author?.avatarUrl.toString(),
        labels: labels?.nodes
            ?.whereType<IssueCardLabelNode>()
            .map((l) => SnapshotLabel(name: l.name, color: l.color))
            .toList(),
        milestone: milestone?.title,
        commentCount: comments.totalCount,
        updatedAt: updatedAt,
      );
}

extension PullCardSnapshot on PullCardData {
  EntitySnapshot toSnapshot() => EntitySnapshot(
        title: title,
        state: merged ? 'merged' : pullRequestState.name.toLowerCase(),
        isDraft: isDraft,
        authorLogin: author?.login,
        authorAvatarUrl: author?.avatarUrl.toString(),
        labels: labels?.nodes
            ?.whereType<PullCardLabelNode>()
            .map((l) => SnapshotLabel(name: l.name, color: l.color))
            .toList(),
        reviewDecision: reviewDecision?.name.toLowerCase(),
        milestone: milestone?.title,
        commentCount: totalCommentsCount ?? comments.totalCount,
        updatedAt: updatedAt,
      );
}

extension IssueInfoOnlySnapshot on IssueInfo {
  EntitySnapshot toSnapshot() => EntitySnapshot(
        title: title,
        state: issueState.name.toLowerCase(),
        stateReason: stateReason?.name.toLowerCase(),
        authorLogin: author?.login,
        authorAvatarUrl: author?.avatarUrl.toString(),
        labels: labels?.nodes
            ?.whereType<IssueLabelNode>()
            .map((l) => SnapshotLabel(name: l.name, color: l.color))
            .toList(),
        milestone: milestone?.title,
        commentCount: comments.totalCount,
        updatedAt: updatedAt,
      );
}

extension PullInfoOnlySnapshot on PullInfo {
  EntitySnapshot toSnapshot() => EntitySnapshot(
        title: title,
        state: merged ? 'merged' : pullRequestState.name.toLowerCase(),
        isDraft: isDraft,
        authorLogin: author?.login,
        authorAvatarUrl: author?.avatarUrl.toString(),
        labels: labels?.nodes
            ?.whereType<PullLabelNode>()
            .map((l) => SnapshotLabel(name: l.name, color: l.color))
            .toList(),
        reviewDecision: reviewDecision?.name.toLowerCase(),
        milestone: milestone?.title,
        commentCount: totalCommentsCount ?? comments.totalCount,
        updatedAt: updatedAt,
      );
}

extension RepositoryModelSnapshot on Repository {
  EntitySnapshot toSnapshot() => EntitySnapshot(
        title: name,
        language: language,
        stars: stargazersCount,
        isPrivate: isPrivate,
        isFork: fork,
        isArchived: archived,
        authorLogin: owner.login,
        authorAvatarUrl: owner.avatarUrl,
      );
}

extension IssueModelSnapshot on Issue {
  EntitySnapshot toSnapshot() => EntitySnapshot(
        title: title,
        state: state?.name.toLowerCase(),
        stateReason: stateReason?.name.toLowerCase(),
        authorLogin: user?.login,
        authorAvatarUrl: user?.avatarUrl,
        labels: labels
            .map((l) => SnapshotLabel(name: l.name, color: l.color))
            .toList(),
        commentCount: comments,
        updatedAt: updatedAt,
      );
}

extension RepoInfoRef on RepoInfo {
  RepoRef get toRef {
    final ownerLogin = owner.when(
      user: (final RepoOwnerAsUser u) => u.login,
      organization: (final RepoOwnerAsOrg o) => o.login,
      orElse: () => '',
    );
    return RepoRef(
      owner: ownerLogin,
      name: name,
      nodeId: id.asGitHubNodeId,
    );
  }
}

extension IssueInfoRef on IssueInfo {
  IssueRef get toRef => IssueRef.fromRepositoryIssue(this);
}

extension PullInfoRef on PullInfo {
  PullRequestRef get toRef => PullRequestRef.fromRepositoryPullRequest(this);
}
