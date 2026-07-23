import 'package:auto_route/auto_route.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:flutter/widgets.dart';

/// Maps [EntityRef] to [PageRouteInfo]. Lives in routes/ so models stay route-agnostic.
extension EntityRefRouting on EntityRef {
  PageRouteInfo toRoute() =>
      switch (this) {
            RepoRef r => r._repoRoute(),
            IssueRef r => IssueDetailRoute(issueRef: r),
            PullRequestRef r =>
              r.diffPath != null && r.diffPath!.isNotEmpty
                  ? FileDiffRoute(pullRef: r, path: r.diffPath!)
                  : PullRequestDetailRoute(pullRef: r),
            CommitRef r => CommitInfoRoute(commitRef: r),
            WorkflowRunRef r => RepositoryRoute(repo: r.repo),
            UserRef r => UserProfileRoute(userRef: r),
            DiscussionRef r => RepositoryRoute(repo: r.repo),
            TopicRef r => SearchRoute(initialQuery: 'topic:${r.name}'),
            WikiRef r => WikiViewer(repo: r.repo, slug: r.path),
            PackageRef _ => throw UnsupportedError(
              'PackageRef has no native route',
            ),
            CodeFileRef r => RepoRef(
              owner: r.repo.owner,
              name: r.repo.name,
              location: RepoLocationBlob(branch: r.sha, filePath: r.path),
            )._repoRoute(),
            ReleaseRef r => RepositoryRoute(
              repo: RepoRef(
                owner: r.repo.owner,
                name: r.repo.name,
                location: const RepoLocationReleases(),
              ),
            ),
            IssueCommentRef r => IssueDetailRoute(
              issueRef: IssueRef(repo: r.repo, number: r.issueNumber),
            ),
            PRReviewCommentRef r => PullRequestDetailRoute(
              pullRef: PullRequestRef(repo: r.repo, number: r.prNumber),
            ),
          }
          as PageRouteInfo;

  List<PageRouteInfo> toRouteStack() => switch (this) {
    RepoScopedRef r => [RepositoryRoute(repo: r.repo), toRoute()],
    _ => [toRoute()],
  };
}

extension _RepoRefRouting on RepoRef {
  PageRouteInfo _repoRoute() =>
      switch (location) {
            null ||
            RepoLocationRoot() ||
            RepoLocationIssues() ||
            RepoLocationPulls() ||
            RepoLocationCommits() ||
            RepoLocationReleases() ||
            RepoLocationDiscussions() ||
            RepoLocationProjects() ||
            RepoLocationActions() ||
            RepoLocationSecurity() ||
            RepoLocationInsights() ||
            RepoLocationLicense() => RepositoryRoute(repo: this),
            RepoLocationTree() => RepositoryRoute(repo: this),
            RepoLocationBlob(
              :final branch,
              :final filePath,
              :final lineStart,
              :final lineEnd,
            ) =>
              FileViewerRoute(
                repoRef: this,
                branch: branch,
                filePath: filePath,
                lineStart: lineStart,
                lineEnd: lineEnd,
              ),
            RepoLocationWiki() => RepositoryRoute(repo: this),
            RepoLocationNewIssue() => NewIssueRoute(repoRef: this),
            RepoLocationCompare(:final baseRef, :final headRef) =>
              CompareViewRoute(repoRef: this, base: baseRef, head: headRef),
          }
          as PageRouteInfo;
}

/// Navigation for [PRReviewRef] (not an [EntityRef]); used by review screens.
extension PRReviewRefRouting on PRReviewRef {
  PageRouteInfo toRoute() => PullRequestDetailRoute(pullRef: pullRef);

  Future<void> navigate(BuildContext context) => context.router.push(toRoute());
}

/// Navigation to comment screen for [IssueRef].
extension IssueRefCommentNav on IssueRef {
  PageRouteInfo toCommentRoute() => CommentRoute(issueRef: this);

  Future<void> navigateToComment(BuildContext context) =>
      context.router.push(toCommentRoute());
}

/// Navigation to comment screen for [PullRequestRef].
extension PullRequestRefCommentNav on PullRequestRef {
  PageRouteInfo toCommentRoute() => CommentRoute(pullRef: this);

  Future<void> navigateToComment(BuildContext context) =>
      context.router.push(toCommentRoute());
}
