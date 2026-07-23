import 'package:diohub_database/database/enums/entity_type_filter.dart';
import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_graphql/fragments/actor.graphql.dart';

import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart'
    hide Actor;

import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/canonical_node_id.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub_models/models/issues/issue_model.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub_models/models/pull_requests/pull_request_model.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub_models/models/repositories/repository_model.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_ref.freezed.dart';

sealed class EntityRef implements Navigable {
  const EntityRef();

  /// GitHub's global GraphQL node ID (e.g. `R_kgDOBV6Mvw`).
  ///
  /// Optional — populated from GraphQL responses, omitted from URL parsing
  /// and user input. Excluded from [operator ==] / [hashCode] — entity identity
  /// is structural (owner/name/number/etc.).
  String? get nodeId;

  /// Type discriminator for persistence and filtering.
  /// Matches the 'type' value in toJson().
  /// DB column value for entity_type — derived from the sealed class identity.
  /// Single source of truth. Use this for persistence and filtering.
  String get dbType;

  /// Display label for this ref's type.
  String get typeLabel {
    for (final e in EntityTypeFilter.values) {
      if (e.dbValue == dbType) return e.displayLabel;
    }
    return dbType;
  }

  /// Parent entity's apiPath, or null for top-level entities.
  /// Used as SQL join key for hierarchical queries.
  String? get parentPath;

  /// Parent entity's nodeId, or null for top-level entities.
  /// Used for hierarchical joins (e.g. bookmark by parent repo).
  String? get parentNodeId => null;

  /// When false, [navigate] should open [webUrl] in browser instead of pushing a route.
  bool get hasNativeRoute => true;

  /// Web URL for this entity on the given server.
  Uri webUrlFor(ServerConfig server);

  /// Default web URL (GitHub.com). For [Navigable] compatibility.
  @override
  Uri get webUrl => webUrlFor(ServerConfig.gitHubDotCom);

  /// Serialize for persistence (e.g. entity store). Subclasses implement.
  Map<String, dynamic> toJson();

  /// Deserialize from JSON. [type] field discriminates the ref kind.
  static EntityRef fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'repo' => RepoRef(
        owner: json['owner'] as String,
        name: json['name'] as String,
        location: _locationFromJson(json['location'] as Map<String, dynamic>?),
        nodeId: json['nodeId'] as String?,
      ),
      'issue' => IssueRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        number: json['number'] as int,
        nodeId: json['nodeId'] as String?,
      ),
      'pr' => PullRequestRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        number: json['number'] as int,
        nodeId: json['nodeId'] as String?,
      ),
      'commit' => CommitRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        oid: json['oid'] as String,
        nodeId: json['nodeId'] as String?,
      ),
      'workflowRun' => WorkflowRunRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        runId: json['runId'] as int,
        nodeId: json['nodeId'] as String?,
      ),
      'user' => UserRef(
        login: json['login'] as String,
        tab: json['tab'] as String?,
        nodeId: json['nodeId'] as String?,
      ),
      'discussion' => DiscussionRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        number: json['number'] as int,
        nodeId: json['nodeId'] as String?,
      ),
      'topic' => TopicRef(
        name: json['name'] as String,
        nodeId: json['nodeId'] as String?,
      ),
      'wiki' => WikiRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        path: json['path'] as String,
        nodeId: json['nodeId'] as String?,
      ),
      'package' => PackageRef(
        htmlUrl: json['htmlUrl'] as String,
        nodeId: json['nodeId'] as String?,
      ),
      'codeFile' => CodeFileRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        path: json['path'] as String,
        sha: json['sha'] as String,
        nodeId: json['nodeId'] as String?,
      ),
      'release' => ReleaseRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        tagName: json['tagName'] as String,
        releaseId: json['releaseId'] as int?,
        nodeId: json['nodeId'] as String?,
      ),
      'issueComment' => IssueCommentRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        issueNumber: json['issueNumber'] as int,
        commentId: json['commentId'] as int,
        nodeId: json['nodeId'] as String?,
      ),
      'prReviewComment' => PRReviewCommentRef(
        repo: RepoRef(
          owner: json['repoOwner'] as String,
          name: json['repoName'] as String,
        ),
        prNumber: json['prNumber'] as int,
        commentId: json['commentId'] as int,
        nodeId: json['nodeId'] as String?,
      ),
      _ => throw ArgumentError('Unknown EntityRef type: $type'),
    };
  }
}

/// URL-shaped location within a repo (mirrors GitHub path).
/// Use [RepoRef.location] when present; resolve to initial tab/branch/path in one place.
@freezed
sealed class RepoLocation with _$RepoLocation {
  const RepoLocation._();

  const factory RepoLocation.root() = RepoLocationRoot;
  const factory RepoLocation.tree({required String branch, String? path}) =
      RepoLocationTree;
  const factory RepoLocation.blob({
    required String branch,
    required String filePath,
    int? lineStart,
    int? lineEnd,
  }) = RepoLocationBlob;
  const factory RepoLocation.issues() = RepoLocationIssues;
  const factory RepoLocation.pulls() = RepoLocationPulls;
  const factory RepoLocation.commits({String? branch}) = RepoLocationCommits;
  const factory RepoLocation.wiki({String? page}) = RepoLocationWiki;
  const factory RepoLocation.releases() = RepoLocationReleases;
  const factory RepoLocation.discussions() = RepoLocationDiscussions;
  const factory RepoLocation.projects() = RepoLocationProjects;
  const factory RepoLocation.actions() = RepoLocationActions;
  const factory RepoLocation.security() = RepoLocationSecurity;
  const factory RepoLocation.insights() = RepoLocationInsights;
  const factory RepoLocation.license() = RepoLocationLicense;
  const factory RepoLocation.newIssue({String? templateId}) =
      RepoLocationNewIssue;
  const factory RepoLocation.compare({String? baseRef, String? headRef}) =
      RepoLocationCompare;
}

/// An entity that belongs to a specific repository.
/// All subclasses inherit [repo] and [parentPath].
sealed class RepoScopedRef extends EntityRef {
  const RepoScopedRef({required this.repo, this.nodeId});
  final RepoRef repo;

  @override
  final String? nodeId;

  @override
  String? get parentPath => repo.apiPath;

  @override
  String? get parentNodeId => repo.nodeId;
}

Map<String, dynamic>? _locationToJson(RepoLocation? loc) => switch (loc) {
  null => null,
  RepoLocationRoot() => {'locType': 'root'},
  RepoLocationTree(:final branch, :final path) => {
    'locType': 'tree',
    'branch': branch,
    if (path != null) 'path': path,
  },
  RepoLocationBlob(
    :final branch,
    :final filePath,
    :final lineStart,
    :final lineEnd,
  ) =>
    {
      'locType': 'blob',
      'branch': branch,
      'filePath': filePath,
      if (lineStart != null) 'lineStart': lineStart,
      if (lineEnd != null) 'lineEnd': lineEnd,
    },
  RepoLocationIssues() => {'locType': 'issues'},
  RepoLocationPulls() => {'locType': 'pulls'},
  RepoLocationCommits(:final branch) => {
    'locType': 'commits',
    if (branch != null) 'branch': branch,
  },
  RepoLocationWiki(:final page) => {
    'locType': 'wiki',
    if (page != null) 'page': page,
  },
  RepoLocationReleases() => {'locType': 'releases'},
  RepoLocationDiscussions() => {'locType': 'discussions'},
  RepoLocationProjects() => {'locType': 'projects'},
  RepoLocationActions() => {'locType': 'actions'},
  RepoLocationSecurity() => {'locType': 'security'},
  RepoLocationInsights() => {'locType': 'insights'},
  RepoLocationLicense() => {'locType': 'license'},
  RepoLocationNewIssue(:final templateId) => {
    'locType': 'newIssue',
    if (templateId != null) 'templateId': templateId,
  },
  RepoLocationCompare(:final baseRef, :final headRef) => {
    'locType': 'compare',
    if (baseRef != null) 'baseRef': baseRef,
    if (headRef != null) 'headRef': headRef,
  },
};

RepoLocation? _locationFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return switch (json['locType'] as String?) {
    'root' => const RepoLocation.root(),
    'tree' => RepoLocation.tree(
      branch: json['branch'] as String,
      path: json['path'] as String?,
    ),
    'blob' => RepoLocation.blob(
      branch: json['branch'] as String,
      filePath: json['filePath'] as String,
      lineStart: json['lineStart'] as int?,
      lineEnd: json['lineEnd'] as int?,
    ),
    'issues' => const RepoLocation.issues(),
    'pulls' => const RepoLocation.pulls(),
    'commits' => RepoLocation.commits(branch: json['branch'] as String?),
    'wiki' => RepoLocation.wiki(page: json['page'] as String?),
    'releases' => const RepoLocation.releases(),
    'discussions' => const RepoLocation.discussions(),
    'projects' => const RepoLocation.projects(),
    'actions' => const RepoLocation.actions(),
    'security' => const RepoLocation.security(),
    'insights' => const RepoLocation.insights(),
    'license' => const RepoLocation.license(),
    'newIssue' => RepoLocation.newIssue(
      templateId: json['templateId'] as String?,
    ),
    'compare' => RepoLocation.compare(
      baseRef: json['baseRef'] as String?,
      headRef: json['headRef'] as String?,
    ),
    _ => null,
  };
}

@freezed
abstract class RepoRef extends EntityRef with _$RepoRef {
  const RepoRef._();

  const factory RepoRef({
    required String owner,
    required String name,
    RepoLocation? location,
    String? nodeId,
  }) = _RepoRef;

  factory RepoRef.fromRepository(final Repository repo) =>
      RepoRef(owner: repo.owner.login, name: repo.name);

  factory RepoRef.fromPrBranchRepo(final PrBranchRepo repo) =>
      RepoRef(owner: repo.owner.login, name: repo.name);

  factory RepoRef.fromEventRepo(final EventRepo repo) {
    final String? fullName = repo.name?.trim();
    if (fullName == null || fullName.isEmpty) {
      throw ArgumentError.value(
        repo.name,
        'repo.name',
        'Cannot create a repository reference from a redacted event repo',
      );
    }
    return RepoRef.fromFullName(fullName);
  }

  factory RepoRef.fromMinimalRepository(final MinimalRepository repo) =>
      RepoRef.fromFullName(repo.fullName);

  /// Build from GQL repo card fragment (e.g. from search, timeline, repo list).
  factory RepoRef.fromRepoCardFields(final RepoCardData data) {
    final ownerLogin = switch (data.owner) {
      Fragment$actor actor => actor.login,
      _ => throw ArgumentError('Invalid owner type: ${data.owner.runtimeType}'),
    };
    return RepoRef(
      owner: ownerLogin,
      name: data.name,
      nodeId: data.id.asGitHubNodeId,
    );
  }

  factory RepoRef.fromFullName(final String fullName) {
    final List<String> parts = fullName.split('/');
    if (parts.length != 2) {
      throw ArgumentError(
        'Invalid full name format: $fullName. Expected "owner/name"',
      );
    }
    return RepoRef(owner: parts[0], name: parts[1]);
  }

  factory RepoRef.fromApiUrl(final String apiUrl) {
    final Uri uri = Uri.parse(apiUrl);
    final List<String> segments = uri.pathSegments;
    if (segments.length >= 3 && segments[0] == 'repos') {
      return RepoRef(owner: segments[1], name: segments[2]);
    }
    throw ArgumentError('Invalid repo API URL: $apiUrl');
  }

  factory RepoRef.fromHtmlUrl(final String htmlUrl) {
    try {
      final uri = Uri.parse(htmlUrl);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 2) {
        return RepoRef(owner: segments[0], name: segments[1]);
      }
      throw ArgumentError('Invalid repo HTML URL format: $htmlUrl');
    } catch (e) {
      throw ArgumentError(
        'Failed to parse repo HTML URL: $htmlUrl (${e.toString()})',
      );
    }
  }

  @override
  String get dbType => 'repo';

  @override
  String? get parentPath => null;

  String get fullName => '$owner/$name';

  @override
  String get apiPath => '/repos/$owner/$name';

  @override
  Uri webUrlFor(ServerConfig server) => server.webUrl('/$owner/$name');

  @override
  String toString() => fullName;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'repo',
    'owner': owner,
    'name': name,
    if (location != null) 'location': _locationToJson(location),
    if (nodeId != null) 'nodeId': nodeId,
  };
}

@freezed
abstract class IssueRef extends RepoScopedRef with _$IssueRef {
  const IssueRef._({required RepoRef repo}) : super(repo: repo);

  const factory IssueRef({
    required RepoRef repo,
    required int number,
    String? nodeId,
  }) = _IssueRef;

  factory IssueRef.fromIssue(final Issue issue) => IssueRef(
    repo: RepoRef.fromRepository(issue.repository!),
    number: issue.number,
  );

  /// Build from GQL issue card fragment (e.g. from search, timeline, list).
  factory IssueRef.fromIssueCardFields(final IssueCardData data) => IssueRef(
    repo: RepoRef(
      owner: data.repository.owner.login,
      name: data.repository.name,
    ),
    number: data.number,
    nodeId: data.id.asGitHubNodeId,
  );

  /// Build from issue detail query (issueInfoOnly / issuePullInfo).
  factory IssueRef.fromRepositoryIssue(final IssueInfo data) => IssueRef(
    repo: RepoRef(
      owner: data.repository.owner.login,
      name: data.repository.name,
    ),
    number: data.number,
    nodeId: data.id.asGitHubNodeId,
  );

  factory IssueRef.fromApiUrl(final String apiUrl) {
    final Uri uri = Uri.parse(apiUrl);
    final List<String> segments = uri.pathSegments;
    if (segments.length >= 5 &&
        segments[0] == 'repos' &&
        segments[3] == 'issues') {
      return IssueRef(
        repo: RepoRef(owner: segments[1], name: segments[2]),
        number: int.parse(segments[4]),
      );
    }
    throw ArgumentError('Invalid issue API URL: $apiUrl');
  }

  factory IssueRef.fromHtmlUrl(final String htmlUrl) {
    try {
      final uri = Uri.parse(htmlUrl);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 4 && segments[2] == 'issues') {
        final number = int.tryParse(segments[3]);
        if (number != null) {
          return IssueRef(
            repo: RepoRef(owner: segments[0], name: segments[1]),
            number: number,
          );
        }
      }
      throw ArgumentError('Invalid issue HTML URL format: $htmlUrl');
    } catch (e) {
      throw ArgumentError(
        'Failed to parse issue HTML URL: $htmlUrl (${e.toString()})',
      );
    }
  }

  @override
  String get dbType => 'issue';
  @override
  String get apiPath => '${repo.apiPath}/issues/$number';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.owner}/${repo.name}/issues/$number');

  @override
  String toString() => '${repo.fullName}#$number';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'issue',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'number': number,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

@freezed
abstract class PullRequestRef extends RepoScopedRef with _$PullRequestRef {
  const PullRequestRef._({required RepoRef repo}) : super(repo: repo);

  const factory PullRequestRef({
    required RepoRef repo,
    required int number,
    String? diffPath,
    String? nodeId,
  }) = _PullRequestRef;

  factory PullRequestRef.fromPullRequest(final PullRequest pr) {
    final PrBranchRepo repo = pr.baseBranch.repo!;
    return PullRequestRef(
      repo: RepoRef.fromPrBranchRepo(repo),
      number: pr.number,
    );
  }

  /// Build from GQL pull request card fragment (e.g. from search, timeline, list).
  factory PullRequestRef.fromPullCardFields(final PullCardData data) =>
      PullRequestRef(
        repo: RepoRef(
          owner: data.repository.owner.login,
          name: data.repository.name,
        ),
        number: data.number,
        nodeId: data.id.asGitHubNodeId,
      );

  /// Build from pull request detail query (pullInfoOnly / issuePullInfo).
  factory PullRequestRef.fromRepositoryPullRequest(final PullInfo data) =>
      PullRequestRef(
        repo: RepoRef(
          owner: data.repository.owner.login,
          name: data.repository.name,
        ),
        number: data.number,
        nodeId: data.id.asGitHubNodeId,
      );

  factory PullRequestRef.fromApiUrl(final String apiUrl) {
    final Uri uri = Uri.parse(apiUrl);
    final List<String> segments = uri.pathSegments;
    if (segments.length >= 5 &&
        segments[0] == 'repos' &&
        segments[3] == 'pulls') {
      return PullRequestRef(
        repo: RepoRef(owner: segments[1], name: segments[2]),
        number: int.parse(segments[4]),
      );
    }
    throw ArgumentError('Invalid PR API URL: $apiUrl');
  }

  factory PullRequestRef.fromHtmlUrl(final String htmlUrl) {
    try {
      final uri = Uri.parse(htmlUrl);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 4 && segments[2] == 'pull') {
        final number = int.tryParse(segments[3]);
        if (number != null) {
          return PullRequestRef(
            repo: RepoRef(owner: segments[0], name: segments[1]),
            number: number,
          );
        }
      }
      throw ArgumentError('Invalid PR HTML URL format: $htmlUrl');
    } catch (e) {
      throw ArgumentError(
        'Failed to parse PR HTML URL: $htmlUrl (${e.toString()})',
      );
    }
  }

  @override
  String get dbType => 'pr';
  @override
  String get apiPath => '${repo.apiPath}/pulls/$number';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.owner}/${repo.name}/pull/$number');

  @override
  String toString() => '${repo.fullName}#$number';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'pr',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'number': number,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Ref for PR review flows (view review / submit review). Carries pull ref and review node id.
/// Not an [EntityRef]; used so routes take a single ref instead of raw params.
/// [pullNodeID] is derived from [pullRef.nodeId].
@freezed
abstract class PRReviewRef with _$PRReviewRef {
  const PRReviewRef._();

  const factory PRReviewRef({
    required PullRequestRef pullRef,
    required String reviewNodeID,
  }) = _PRReviewRef;

  /// GitHub GraphQL node ID for the pull request. From [pullRef.nodeId].
  String get pullNodeID => pullRef.nodeId!;
}

@freezed
abstract class CommitRef extends RepoScopedRef with _$CommitRef {
  const CommitRef._({required RepoRef repo}) : super(repo: repo);

  const factory CommitRef({
    required RepoRef repo,
    required String oid,
    String? nodeId,
  }) = _CommitRef;

  factory CommitRef.fromCommit(final Commit commit, final RepoRef repo) =>
      CommitRef(repo: repo, oid: commit.sha);

  factory CommitRef.fromGcommitListItem(
    final CommitNode commit,
    final RepoRef repo,
  ) => CommitRef(repo: repo, oid: commit.oid);

  factory CommitRef.fromApiUrl(final String apiUrl) {
    final Uri uri = Uri.parse(apiUrl);
    final List<String> segments = uri.pathSegments;
    if (segments.length >= 5 &&
        segments[0] == 'repos' &&
        segments[3] == 'commits') {
      return CommitRef(
        repo: RepoRef(owner: segments[1], name: segments[2]),
        oid: segments[4],
      );
    }
    throw ArgumentError('Invalid commit API URL: $apiUrl');
  }

  factory CommitRef.fromHtmlUrl(final String htmlUrl) {
    try {
      final uri = Uri.parse(htmlUrl);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length >= 4 && segments[2] == 'commit') {
        return CommitRef(
          repo: RepoRef(owner: segments[0], name: segments[1]),
          oid: segments[3],
        );
      }
      throw ArgumentError('Invalid commit HTML URL format: $htmlUrl');
    } catch (e) {
      throw ArgumentError(
        'Failed to parse commit HTML URL: $htmlUrl (${e.toString()})',
      );
    }
  }

  @override
  String get dbType => 'commit';
  @override
  String get apiPath => '${repo.apiPath}/commits/$oid';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.owner}/${repo.name}/commit/$oid');

  @override
  String toString() => '${repo.fullName}@${oid.substring(0, 7)}';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'commit',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'oid': oid,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Workflow run (Actions) in a repo.
@freezed
abstract class WorkflowRunRef extends RepoScopedRef with _$WorkflowRunRef {
  const WorkflowRunRef._({required RepoRef repo}) : super(repo: repo);

  const factory WorkflowRunRef({
    required RepoRef repo,
    required int runId,
    String? nodeId,
  }) = _WorkflowRunRef;

  @override
  bool get hasNativeRoute => true;

  @override
  String get dbType => 'workflowRun';
  @override
  String get apiPath => '${repo.apiPath}/actions/runs/$runId';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.owner}/${repo.name}/actions/runs/$runId');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'workflowRun',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'runId': runId,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

@freezed
abstract class UserRef extends EntityRef with _$UserRef {
  const UserRef._();

  const factory UserRef({required String login, String? tab, String? nodeId}) =
      _UserRef;

  factory UserRef.fromUser(final SimpleUser user) => UserRef(login: user.login);

  factory UserRef.fromActor(final Actor actor) => UserRef(login: actor.login);

  factory UserRef.fromMinimalOwner(final MinimalOwner owner) =>
      UserRef(login: owner.login);

  @override
  String get dbType => 'user';
  @override
  String? get parentPath => null;

  @override
  String get apiPath => '/users/$login';

  @override
  Uri webUrlFor(ServerConfig server) {
    final String q = tab != null ? '?tab=$tab' : '';
    return server.webUrl('/$login$q');
  }

  @override
  String toString() => '@$login';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'user',
    'login': login,
    if (tab != null) 'tab': tab,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Discussion in a repo (browser-only for now).
@freezed
abstract class DiscussionRef extends RepoScopedRef with _$DiscussionRef {
  const DiscussionRef._({required RepoRef repo}) : super(repo: repo);

  const factory DiscussionRef({
    required RepoRef repo,
    required int number,
    String? nodeId,
  }) = _DiscussionRef;

  factory DiscussionRef.fromApiUrl(final String apiUrl) {
    final Uri uri = Uri.parse(apiUrl);
    final List<String> segments = uri.pathSegments;
    if (segments.length >= 5 &&
        segments[0] == 'repos' &&
        segments[3] == 'discussions') {
      return DiscussionRef(
        repo: RepoRef(owner: segments[1], name: segments[2]),
        number: int.parse(segments[4]),
      );
    }
    throw ArgumentError('Invalid Discussion API URL: $apiUrl');
  }

  @override
  bool get hasNativeRoute => false;

  @override
  String get dbType => 'discussion';
  @override
  String get apiPath => '${repo.apiPath}/discussions/$number';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.fullName}/discussions/$number');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'discussion',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'number': number,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Topic (in-app search with topic:name filter).
@freezed
abstract class TopicRef extends EntityRef with _$TopicRef {
  const TopicRef._();

  const factory TopicRef({required String name, String? nodeId}) = _TopicRef;

  @override
  String get dbType => 'topic';
  @override
  String? get parentPath => null;

  @override
  bool get hasNativeRoute => true;

  @override
  String get apiPath => '';

  @override
  Uri webUrlFor(ServerConfig server) => server.webUrl('/topics/$name');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'topic',
    'name': name,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Wiki page (browser-only).
@freezed
abstract class WikiRef extends RepoScopedRef with _$WikiRef {
  const WikiRef._({required RepoRef repo}) : super(repo: repo);

  const factory WikiRef({
    required RepoRef repo,
    required String path,
    String? nodeId,
  }) = _WikiRef;

  @override
  bool get hasNativeRoute => true;

  @override
  String get dbType => 'wiki';
  @override
  String get apiPath => '${repo.apiPath}/wiki/$path';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.fullName}/wiki/$path');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'wiki',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'path': path,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Package (browser-only).
@freezed
abstract class PackageRef extends EntityRef with _$PackageRef {
  const PackageRef._();

  const factory PackageRef({required String htmlUrl, String? nodeId}) =
      _PackageRef;

  @override
  String get dbType => 'package';
  @override
  String? get parentPath => null;

  @override
  bool get hasNativeRoute => false;

  @override
  String get apiPath => '';

  @override
  Uri webUrlFor(ServerConfig server) => Uri.parse(htmlUrl);

  @override
  Map<String, dynamic> toJson() => {
    'type': 'package',
    'htmlUrl': htmlUrl,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Code file in a repo (browser or code viewer).
@freezed
abstract class CodeFileRef extends RepoScopedRef with _$CodeFileRef {
  const CodeFileRef._({required RepoRef repo}) : super(repo: repo);

  const factory CodeFileRef({
    required RepoRef repo,
    required String path,
    required String sha,
    String? nodeId,
  }) = _CodeFileRef;

  @override
  bool get hasNativeRoute => true;

  @override
  String get dbType => 'codeFile';
  @override
  String get apiPath => '${repo.apiPath}/contents/$path';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.fullName}/blob/$sha/$path');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'codeFile',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'path': path,
    'sha': sha,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Release in a repo (tag + optional release id).
@freezed
abstract class ReleaseRef extends RepoScopedRef with _$ReleaseRef {
  const ReleaseRef._({required RepoRef repo}) : super(repo: repo);

  const factory ReleaseRef({
    required RepoRef repo,
    required String tagName,
    int? releaseId,
    String? nodeId,
  }) = _ReleaseRef;

  @override
  String get dbType => 'release';
  @override
  String get apiPath => '${repo.apiPath}/releases/tags/$tagName';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.fullName}/releases/tag/$tagName');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'release',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'tagName': tagName,
    if (releaseId != null) 'releaseId': releaseId,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// Issue comment (independently bookmarkable).
@freezed
abstract class IssueCommentRef extends RepoScopedRef with _$IssueCommentRef {
  const IssueCommentRef._({required RepoRef repo}) : super(repo: repo);

  const factory IssueCommentRef({
    required RepoRef repo,
    required int issueNumber,
    required int commentId,
    String? nodeId,
  }) = _IssueCommentRef;

  IssueRef get issue => IssueRef(repo: repo, number: issueNumber);

  @override
  String get dbType => 'issueComment';
  @override
  String get apiPath => '${repo.apiPath}/issues/comments/$commentId';

  @override
  Uri webUrlFor(ServerConfig server) => server.webUrl(
    '/${repo.fullName}/issues/$issueNumber#issuecomment-$commentId',
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': 'issueComment',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'issueNumber': issueNumber,
    'commentId': commentId,
    if (nodeId != null) 'nodeId': nodeId,
  };
}

/// PR review comment (independently bookmarkable).
@freezed
abstract class PRReviewCommentRef extends RepoScopedRef
    with _$PRReviewCommentRef {
  const PRReviewCommentRef._({required RepoRef repo}) : super(repo: repo);

  const factory PRReviewCommentRef({
    required RepoRef repo,
    required int prNumber,
    required int commentId,
    String? nodeId,
  }) = _PRReviewCommentRef;

  PullRequestRef get pullRequest =>
      PullRequestRef(repo: repo, number: prNumber);

  @override
  String get dbType => 'prReviewComment';
  @override
  String get apiPath => '${repo.apiPath}/pulls/comments/$commentId';

  @override
  Uri webUrlFor(ServerConfig server) =>
      server.webUrl('/${repo.fullName}/pull/$prNumber#discussion_r$commentId');

  @override
  Map<String, dynamic> toJson() => {
    'type': 'prReviewComment',
    'repoOwner': repo.owner,
    'repoName': repo.name,
    'prNumber': prNumber,
    'commentId': commentId,
    if (nodeId != null) 'nodeId': nodeId,
  };
}
