// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i26;
import 'package:collection/collection.dart' as _i30;
import 'package:diohub/common/diff/models.dart' as _i29;
import 'package:diohub/models/global_list_destination.dart' as _i32;
import 'package:diohub/view/authentication/auth_screen.dart' as _i1;
import 'package:diohub/view/changelog/changelog_screen.dart' as _i2;
import 'package:diohub/view/global_lists/global_lists_screen.dart' as _i11;
import 'package:diohub/view/home/home.dart' as _i12;
import 'package:diohub/view/issues_pulls/comment_screen.dart' as _i4;
import 'package:diohub/view/issues_pulls/edit_issue_screen.dart' as _i7;
import 'package:diohub/view/issues_pulls/edit_pull_request_screen.dart' as _i8;
import 'package:diohub/view/issues_pulls/issue_detail_screen.dart' as _i13;
import 'package:diohub/view/issues_pulls/new_pull_request_screen.dart' as _i16;
import 'package:diohub/view/issues_pulls/pull_request_detail_screen.dart'
    as _i18;
import 'package:diohub/view/issues_pulls/widgets/file_diff_screen.dart' as _i9;
import 'package:diohub/view/landing/widgets/landing_loading_screen.dart'
    as _i14;
import 'package:diohub/view/notifications/notifications_md3_screen.dart'
    as _i17;
import 'package:diohub/view/profile/user_profile_screen.dart' as _i24;
import 'package:diohub/view/repository/code/file_viewer_screen.dart' as _i10;
import 'package:diohub/view/repository/commits/commit_info_screen.dart' as _i5;
import 'package:diohub/view/repository/commits/widgets/changes_viewer.dart'
    as _i3;
import 'package:diohub/view/repository/compare_view_screen.dart' as _i6;
import 'package:diohub/view/repository/issues/new_issue_screen.dart' as _i15;
import 'package:diohub/view/repository/repository_screen.dart' as _i19;
import 'package:diohub/view/repository/wiki/wiki_viewer.dart' as _i25;
import 'package:diohub/view/search/search.dart' as _i22;
import 'package:diohub/view/settings/settings_screen.dart' as _i23;
import 'package:diohub/view/ssh/ssh_connections_screen.dart' as _i20;
import 'package:diohub/view/ssh/ssh_terminal_screen.dart' as _i21;
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart' as _i34;
import 'package:diohub_models/models/entity_ref.dart' as _i28;
import 'package:diohub_models/models/home_filter.dart' as _i33;
import 'package:diohub_models/models/repositories/code/code_tree_node.dart'
    as _i31;
import 'package:flutter/foundation.dart' as _i35;
import 'package:flutter/material.dart' as _i27;

/// generated route for
/// [_i1.AuthScreen]
class AuthRoute extends _i26.PageRouteInfo<void> {
  const AuthRoute({List<_i26.PageRouteInfo>? children})
    : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthScreen();
    },
  );
}

/// generated route for
/// [_i2.ChangelogScreen]
class ChangelogRoute extends _i26.PageRouteInfo<void> {
  const ChangelogRoute({List<_i26.PageRouteInfo>? children})
    : super(ChangelogRoute.name, initialChildren: children);

  static const String name = 'ChangelogRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      return const _i2.ChangelogScreen();
    },
  );
}

/// generated route for
/// [_i3.ChangesViewer]
class ChangesViewer extends _i26.PageRouteInfo<ChangesViewerArgs> {
  ChangesViewer({
    required String? patch,
    required String? contentURL,
    required String? fileType,
    _i27.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         ChangesViewer.name,
         args: ChangesViewerArgs(
           patch: patch,
           contentURL: contentURL,
           fileType: fileType,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'ChangesViewer';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChangesViewerArgs>();
      return _i3.ChangesViewer(
        args.patch,
        args.contentURL,
        args.fileType,
        key: args.key,
      );
    },
  );
}

class ChangesViewerArgs {
  const ChangesViewerArgs({
    required this.patch,
    required this.contentURL,
    required this.fileType,
    this.key,
  });

  final String? patch;

  final String? contentURL;

  final String? fileType;

  final _i27.Key? key;

  @override
  String toString() {
    return 'ChangesViewerArgs{patch: $patch, contentURL: $contentURL, fileType: $fileType, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChangesViewerArgs) return false;
    return patch == other.patch &&
        contentURL == other.contentURL &&
        fileType == other.fileType &&
        key == other.key;
  }

  @override
  int get hashCode =>
      patch.hashCode ^ contentURL.hashCode ^ fileType.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i4.CommentScreen]
class CommentRoute extends _i26.PageRouteInfo<CommentRouteArgs> {
  CommentRoute({
    _i27.Key? key,
    _i28.IssueRef? issueRef,
    _i28.PullRequestRef? pullRef,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         CommentRoute.name,
         args: CommentRouteArgs(key: key, issueRef: issueRef, pullRef: pullRef),
         initialChildren: children,
       );

  static const String name = 'CommentRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommentRouteArgs>(
        orElse: () => const CommentRouteArgs(),
      );
      return _i4.CommentScreen(
        key: args.key,
        issueRef: args.issueRef,
        pullRef: args.pullRef,
      );
    },
  );
}

class CommentRouteArgs {
  const CommentRouteArgs({this.key, this.issueRef, this.pullRef});

  final _i27.Key? key;

  final _i28.IssueRef? issueRef;

  final _i28.PullRequestRef? pullRef;

  @override
  String toString() {
    return 'CommentRouteArgs{key: $key, issueRef: $issueRef, pullRef: $pullRef}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CommentRouteArgs) return false;
    return key == other.key &&
        issueRef == other.issueRef &&
        pullRef == other.pullRef;
  }

  @override
  int get hashCode => key.hashCode ^ issueRef.hashCode ^ pullRef.hashCode;
}

/// generated route for
/// [_i5.CommitInfoScreen]
class CommitInfoRoute extends _i26.PageRouteInfo<CommitInfoRouteArgs> {
  CommitInfoRoute({
    required _i28.CommitRef commitRef,
    _i27.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         CommitInfoRoute.name,
         args: CommitInfoRouteArgs(commitRef: commitRef, key: key),
         initialChildren: children,
       );

  static const String name = 'CommitInfoRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CommitInfoRouteArgs>();
      return _i5.CommitInfoScreen(commitRef: args.commitRef, key: args.key);
    },
  );
}

class CommitInfoRouteArgs {
  const CommitInfoRouteArgs({required this.commitRef, this.key});

  final _i28.CommitRef commitRef;

  final _i27.Key? key;

  @override
  String toString() {
    return 'CommitInfoRouteArgs{commitRef: $commitRef, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CommitInfoRouteArgs) return false;
    return commitRef == other.commitRef && key == other.key;
  }

  @override
  int get hashCode => commitRef.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i6.CompareViewScreen]
class CompareViewRoute extends _i26.PageRouteInfo<CompareViewRouteArgs> {
  CompareViewRoute({
    _i27.Key? key,
    required _i28.RepoRef repoRef,
    String? base,
    String? head,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         CompareViewRoute.name,
         args: CompareViewRouteArgs(
           key: key,
           repoRef: repoRef,
           base: base,
           head: head,
         ),
         initialChildren: children,
       );

  static const String name = 'CompareViewRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CompareViewRouteArgs>();
      return _i6.CompareViewScreen(
        key: args.key,
        repoRef: args.repoRef,
        base: args.base,
        head: args.head,
      );
    },
  );
}

class CompareViewRouteArgs {
  const CompareViewRouteArgs({
    this.key,
    required this.repoRef,
    this.base,
    this.head,
  });

  final _i27.Key? key;

  final _i28.RepoRef repoRef;

  final String? base;

  final String? head;

  @override
  String toString() {
    return 'CompareViewRouteArgs{key: $key, repoRef: $repoRef, base: $base, head: $head}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CompareViewRouteArgs) return false;
    return key == other.key &&
        repoRef == other.repoRef &&
        base == other.base &&
        head == other.head;
  }

  @override
  int get hashCode =>
      key.hashCode ^ repoRef.hashCode ^ base.hashCode ^ head.hashCode;
}

/// generated route for
/// [_i7.EditIssueScreen]
class EditIssueRoute extends _i26.PageRouteInfo<EditIssueRouteArgs> {
  EditIssueRoute({
    required _i28.IssueRef issueRef,
    _i27.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         EditIssueRoute.name,
         args: EditIssueRouteArgs(issueRef: issueRef, key: key),
         initialChildren: children,
       );

  static const String name = 'EditIssueRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditIssueRouteArgs>();
      return _i7.EditIssueScreen(issueRef: args.issueRef, key: args.key);
    },
  );
}

class EditIssueRouteArgs {
  const EditIssueRouteArgs({required this.issueRef, this.key});

  final _i28.IssueRef issueRef;

  final _i27.Key? key;

  @override
  String toString() {
    return 'EditIssueRouteArgs{issueRef: $issueRef, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditIssueRouteArgs) return false;
    return issueRef == other.issueRef && key == other.key;
  }

  @override
  int get hashCode => issueRef.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i8.EditPullRequestScreen]
class EditPullRequestRoute
    extends _i26.PageRouteInfo<EditPullRequestRouteArgs> {
  EditPullRequestRoute({
    required _i28.PullRequestRef pullRef,
    _i27.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         EditPullRequestRoute.name,
         args: EditPullRequestRouteArgs(pullRef: pullRef, key: key),
         initialChildren: children,
       );

  static const String name = 'EditPullRequestRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditPullRequestRouteArgs>();
      return _i8.EditPullRequestScreen(pullRef: args.pullRef, key: args.key);
    },
  );
}

class EditPullRequestRouteArgs {
  const EditPullRequestRouteArgs({required this.pullRef, this.key});

  final _i28.PullRequestRef pullRef;

  final _i27.Key? key;

  @override
  String toString() {
    return 'EditPullRequestRouteArgs{pullRef: $pullRef, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditPullRequestRouteArgs) return false;
    return pullRef == other.pullRef && key == other.key;
  }

  @override
  int get hashCode => pullRef.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i9.FileDiffScreen]
class FileDiffRoute extends _i26.PageRouteInfo<FileDiffRouteArgs> {
  FileDiffRoute({
    required _i28.PullRequestRef pullRef,
    required String path,
    _i27.Key? key,
    Set<(int?, int?)>? highlightedLines,
    bool? viewedState,
    _i27.ValueChanged<_i29.DiffLineTapDetails>? onLineTap,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         FileDiffRoute.name,
         args: FileDiffRouteArgs(
           pullRef: pullRef,
           path: path,
           key: key,
           highlightedLines: highlightedLines,
           viewedState: viewedState,
           onLineTap: onLineTap,
         ),
         initialChildren: children,
       );

  static const String name = 'FileDiffRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FileDiffRouteArgs>();
      return _i9.FileDiffScreen(
        pullRef: args.pullRef,
        path: args.path,
        key: args.key,
        highlightedLines: args.highlightedLines,
        viewedState: args.viewedState,
        onLineTap: args.onLineTap,
      );
    },
  );
}

class FileDiffRouteArgs {
  const FileDiffRouteArgs({
    required this.pullRef,
    required this.path,
    this.key,
    this.highlightedLines,
    this.viewedState,
    this.onLineTap,
  });

  final _i28.PullRequestRef pullRef;

  final String path;

  final _i27.Key? key;

  final Set<(int?, int?)>? highlightedLines;

  final bool? viewedState;

  final _i27.ValueChanged<_i29.DiffLineTapDetails>? onLineTap;

  @override
  String toString() {
    return 'FileDiffRouteArgs{pullRef: $pullRef, path: $path, key: $key, highlightedLines: $highlightedLines, viewedState: $viewedState, onLineTap: $onLineTap}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FileDiffRouteArgs) return false;
    return pullRef == other.pullRef &&
        path == other.path &&
        key == other.key &&
        const _i30.SetEquality<(int?, int?)>().equals(
          highlightedLines,
          other.highlightedLines,
        ) &&
        viewedState == other.viewedState &&
        onLineTap == other.onLineTap;
  }

  @override
  int get hashCode =>
      pullRef.hashCode ^
      path.hashCode ^
      key.hashCode ^
      const _i30.SetEquality<(int?, int?)>().hash(highlightedLines) ^
      viewedState.hashCode ^
      onLineTap.hashCode;
}

/// generated route for
/// [_i10.FileViewerScreen]
class FileViewerRoute extends _i26.PageRouteInfo<FileViewerRouteArgs> {
  FileViewerRoute({
    required _i28.RepoRef repoRef,
    required String branch,
    required String filePath,
    String? sha,
    int? lineStart,
    int? lineEnd,
    List<_i31.CodeTreeNode>? siblingFiles,
    int initialIndex = 0,
    _i27.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         FileViewerRoute.name,
         args: FileViewerRouteArgs(
           repoRef: repoRef,
           branch: branch,
           filePath: filePath,
           sha: sha,
           lineStart: lineStart,
           lineEnd: lineEnd,
           siblingFiles: siblingFiles,
           initialIndex: initialIndex,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'FileViewerRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<FileViewerRouteArgs>();
      return _i10.FileViewerScreen(
        repoRef: args.repoRef,
        branch: args.branch,
        filePath: args.filePath,
        sha: args.sha,
        lineStart: args.lineStart,
        lineEnd: args.lineEnd,
        siblingFiles: args.siblingFiles,
        initialIndex: args.initialIndex,
        key: args.key,
      );
    },
  );
}

class FileViewerRouteArgs {
  const FileViewerRouteArgs({
    required this.repoRef,
    required this.branch,
    required this.filePath,
    this.sha,
    this.lineStart,
    this.lineEnd,
    this.siblingFiles,
    this.initialIndex = 0,
    this.key,
  });

  final _i28.RepoRef repoRef;

  final String branch;

  final String filePath;

  final String? sha;

  final int? lineStart;

  final int? lineEnd;

  final List<_i31.CodeTreeNode>? siblingFiles;

  final int initialIndex;

  final _i27.Key? key;

  @override
  String toString() {
    return 'FileViewerRouteArgs{repoRef: $repoRef, branch: $branch, filePath: $filePath, sha: $sha, lineStart: $lineStart, lineEnd: $lineEnd, siblingFiles: $siblingFiles, initialIndex: $initialIndex, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FileViewerRouteArgs) return false;
    return repoRef == other.repoRef &&
        branch == other.branch &&
        filePath == other.filePath &&
        sha == other.sha &&
        lineStart == other.lineStart &&
        lineEnd == other.lineEnd &&
        const _i30.ListEquality<_i31.CodeTreeNode>().equals(
          siblingFiles,
          other.siblingFiles,
        ) &&
        initialIndex == other.initialIndex &&
        key == other.key;
  }

  @override
  int get hashCode =>
      repoRef.hashCode ^
      branch.hashCode ^
      filePath.hashCode ^
      sha.hashCode ^
      lineStart.hashCode ^
      lineEnd.hashCode ^
      const _i30.ListEquality<_i31.CodeTreeNode>().hash(siblingFiles) ^
      initialIndex.hashCode ^
      key.hashCode;
}

/// generated route for
/// [_i11.GlobalListsScreen]
class GlobalListsRoute extends _i26.PageRouteInfo<GlobalListsRouteArgs> {
  GlobalListsRoute({
    required _i32.GlobalListDestination destination,
    _i27.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         GlobalListsRoute.name,
         args: GlobalListsRouteArgs(destination: destination, key: key),
         initialChildren: children,
       );

  static const String name = 'GlobalListsRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<GlobalListsRouteArgs>();
      return _i11.GlobalListsScreen(
        destination: args.destination,
        key: args.key,
      );
    },
  );
}

class GlobalListsRouteArgs {
  const GlobalListsRouteArgs({required this.destination, this.key});

  final _i32.GlobalListDestination destination;

  final _i27.Key? key;

  @override
  String toString() {
    return 'GlobalListsRouteArgs{destination: $destination, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GlobalListsRouteArgs) return false;
    return destination == other.destination && key == other.key;
  }

  @override
  int get hashCode => destination.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i12.HomeScreen]
class HomeRoute extends _i26.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    _i27.Key? key,
    String? initialTabPath,
    _i33.HomeFilter? filter,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         HomeRoute.name,
         args: HomeRouteArgs(
           key: key,
           initialTabPath: initialTabPath,
           filter: filter,
         ),
         initialChildren: children,
       );

  static const String name = 'HomeRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<HomeRouteArgs>(
        orElse: () => const HomeRouteArgs(),
      );
      return _i12.HomeScreen(
        key: args.key,
        initialTabPath: args.initialTabPath,
        filter: args.filter,
      );
    },
  );
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, this.initialTabPath, this.filter});

  final _i27.Key? key;

  final String? initialTabPath;

  final _i33.HomeFilter? filter;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, initialTabPath: $initialTabPath, filter: $filter}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HomeRouteArgs) return false;
    return key == other.key &&
        initialTabPath == other.initialTabPath &&
        filter == other.filter;
  }

  @override
  int get hashCode => key.hashCode ^ initialTabPath.hashCode ^ filter.hashCode;
}

/// generated route for
/// [_i13.IssueDetailScreen]
class IssueDetailRoute extends _i26.PageRouteInfo<IssueDetailRouteArgs> {
  IssueDetailRoute({
    required _i28.IssueRef issueRef,
    _i27.Key? key,
    DateTime? commentsSince,
    int initialIndex = 0,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         IssueDetailRoute.name,
         args: IssueDetailRouteArgs(
           issueRef: issueRef,
           key: key,
           commentsSince: commentsSince,
           initialIndex: initialIndex,
         ),
         initialChildren: children,
       );

  static const String name = 'IssueDetailRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<IssueDetailRouteArgs>();
      return _i13.IssueDetailScreen(
        issueRef: args.issueRef,
        key: args.key,
        commentsSince: args.commentsSince,
        initialIndex: args.initialIndex,
      );
    },
  );
}

class IssueDetailRouteArgs {
  const IssueDetailRouteArgs({
    required this.issueRef,
    this.key,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final _i28.IssueRef issueRef;

  final _i27.Key? key;

  final DateTime? commentsSince;

  final int initialIndex;

  @override
  String toString() {
    return 'IssueDetailRouteArgs{issueRef: $issueRef, key: $key, commentsSince: $commentsSince, initialIndex: $initialIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IssueDetailRouteArgs) return false;
    return issueRef == other.issueRef &&
        key == other.key &&
        commentsSince == other.commentsSince &&
        initialIndex == other.initialIndex;
  }

  @override
  int get hashCode =>
      issueRef.hashCode ^
      key.hashCode ^
      commentsSince.hashCode ^
      initialIndex.hashCode;
}

/// generated route for
/// [_i14.LandingLoadingScreen]
class LandingLoadingRoute extends _i26.PageRouteInfo<void> {
  const LandingLoadingRoute({List<_i26.PageRouteInfo>? children})
    : super(LandingLoadingRoute.name, initialChildren: children);

  static const String name = 'LandingLoadingRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      return const _i14.LandingLoadingScreen();
    },
  );
}

/// generated route for
/// [_i15.NewIssueScreen]
class NewIssueRoute extends _i26.PageRouteInfo<NewIssueRouteArgs> {
  NewIssueRoute({
    required _i28.RepoRef repoRef,
    _i27.Key? key,
    _i34.RepoIssueTemplate? template,
    String? initialBody,
    String? initialTitle,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         NewIssueRoute.name,
         args: NewIssueRouteArgs(
           repoRef: repoRef,
           key: key,
           template: template,
           initialBody: initialBody,
           initialTitle: initialTitle,
         ),
         initialChildren: children,
       );

  static const String name = 'NewIssueRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewIssueRouteArgs>();
      return _i15.NewIssueScreen(
        repoRef: args.repoRef,
        key: args.key,
        template: args.template,
        initialBody: args.initialBody,
        initialTitle: args.initialTitle,
      );
    },
  );
}

class NewIssueRouteArgs {
  const NewIssueRouteArgs({
    required this.repoRef,
    this.key,
    this.template,
    this.initialBody,
    this.initialTitle,
  });

  final _i28.RepoRef repoRef;

  final _i27.Key? key;

  final _i34.RepoIssueTemplate? template;

  final String? initialBody;

  final String? initialTitle;

  @override
  String toString() {
    return 'NewIssueRouteArgs{repoRef: $repoRef, key: $key, template: $template, initialBody: $initialBody, initialTitle: $initialTitle}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewIssueRouteArgs) return false;
    return repoRef == other.repoRef &&
        key == other.key &&
        template == other.template &&
        initialBody == other.initialBody &&
        initialTitle == other.initialTitle;
  }

  @override
  int get hashCode =>
      repoRef.hashCode ^
      key.hashCode ^
      template.hashCode ^
      initialBody.hashCode ^
      initialTitle.hashCode;
}

/// generated route for
/// [_i16.NewPullRequestScreen]
class NewPullRequestRoute extends _i26.PageRouteInfo<NewPullRequestRouteArgs> {
  NewPullRequestRoute({
    required _i28.RepoRef repoRef,
    _i27.Key? key,
    String? initialBaseRef,
    String? initialHeadRef,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         NewPullRequestRoute.name,
         args: NewPullRequestRouteArgs(
           repoRef: repoRef,
           key: key,
           initialBaseRef: initialBaseRef,
           initialHeadRef: initialHeadRef,
         ),
         initialChildren: children,
       );

  static const String name = 'NewPullRequestRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewPullRequestRouteArgs>();
      return _i16.NewPullRequestScreen(
        repoRef: args.repoRef,
        key: args.key,
        initialBaseRef: args.initialBaseRef,
        initialHeadRef: args.initialHeadRef,
      );
    },
  );
}

class NewPullRequestRouteArgs {
  const NewPullRequestRouteArgs({
    required this.repoRef,
    this.key,
    this.initialBaseRef,
    this.initialHeadRef,
  });

  final _i28.RepoRef repoRef;

  final _i27.Key? key;

  final String? initialBaseRef;

  final String? initialHeadRef;

  @override
  String toString() {
    return 'NewPullRequestRouteArgs{repoRef: $repoRef, key: $key, initialBaseRef: $initialBaseRef, initialHeadRef: $initialHeadRef}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewPullRequestRouteArgs) return false;
    return repoRef == other.repoRef &&
        key == other.key &&
        initialBaseRef == other.initialBaseRef &&
        initialHeadRef == other.initialHeadRef;
  }

  @override
  int get hashCode =>
      repoRef.hashCode ^
      key.hashCode ^
      initialBaseRef.hashCode ^
      initialHeadRef.hashCode;
}

/// generated route for
/// [_i17.NotificationsScreen]
class NotificationsRoute extends _i26.PageRouteInfo<void> {
  const NotificationsRoute({List<_i26.PageRouteInfo>? children})
    : super(NotificationsRoute.name, initialChildren: children);

  static const String name = 'NotificationsRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      return const _i17.NotificationsScreen();
    },
  );
}

/// generated route for
/// [_i18.PullRequestDetailScreen]
class PullRequestDetailRoute
    extends _i26.PageRouteInfo<PullRequestDetailRouteArgs> {
  PullRequestDetailRoute({
    required _i28.PullRequestRef pullRef,
    _i27.Key? key,
    DateTime? commentsSince,
    int initialIndex = 0,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         PullRequestDetailRoute.name,
         args: PullRequestDetailRouteArgs(
           pullRef: pullRef,
           key: key,
           commentsSince: commentsSince,
           initialIndex: initialIndex,
         ),
         initialChildren: children,
       );

  static const String name = 'PullRequestDetailRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PullRequestDetailRouteArgs>();
      return _i18.PullRequestDetailScreen(
        pullRef: args.pullRef,
        key: args.key,
        commentsSince: args.commentsSince,
        initialIndex: args.initialIndex,
      );
    },
  );
}

class PullRequestDetailRouteArgs {
  const PullRequestDetailRouteArgs({
    required this.pullRef,
    this.key,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final _i28.PullRequestRef pullRef;

  final _i27.Key? key;

  final DateTime? commentsSince;

  final int initialIndex;

  @override
  String toString() {
    return 'PullRequestDetailRouteArgs{pullRef: $pullRef, key: $key, commentsSince: $commentsSince, initialIndex: $initialIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PullRequestDetailRouteArgs) return false;
    return pullRef == other.pullRef &&
        key == other.key &&
        commentsSince == other.commentsSince &&
        initialIndex == other.initialIndex;
  }

  @override
  int get hashCode =>
      pullRef.hashCode ^
      key.hashCode ^
      commentsSince.hashCode ^
      initialIndex.hashCode;
}

/// generated route for
/// [_i19.RepositoryScreen]
class RepositoryRoute extends _i26.PageRouteInfo<RepositoryRouteArgs> {
  RepositoryRoute({
    required _i28.RepoRef repo,
    _i27.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         RepositoryRoute.name,
         args: RepositoryRouteArgs(repo: repo, key: key),
         initialChildren: children,
       );

  static const String name = 'RepositoryRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RepositoryRouteArgs>();
      return _i19.RepositoryScreen(repo: args.repo, key: args.key);
    },
  );
}

class RepositoryRouteArgs {
  const RepositoryRouteArgs({required this.repo, this.key});

  final _i28.RepoRef repo;

  final _i27.Key? key;

  @override
  String toString() {
    return 'RepositoryRouteArgs{repo: $repo, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RepositoryRouteArgs) return false;
    return repo == other.repo && key == other.key;
  }

  @override
  int get hashCode => repo.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i20.SSHConnectionsScreen]
class SSHConnectionsRoute extends _i26.PageRouteInfo<void> {
  const SSHConnectionsRoute({List<_i26.PageRouteInfo>? children})
    : super(SSHConnectionsRoute.name, initialChildren: children);

  static const String name = 'SSHConnectionsRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      return const _i20.SSHConnectionsScreen();
    },
  );
}

/// generated route for
/// [_i21.SSHTerminalScreen]
class SSHTerminalRoute extends _i26.PageRouteInfo<SSHTerminalRouteArgs> {
  SSHTerminalRoute({
    _i27.Key? key,
    required String connectionId,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         SSHTerminalRoute.name,
         args: SSHTerminalRouteArgs(key: key, connectionId: connectionId),
         initialChildren: children,
       );

  static const String name = 'SSHTerminalRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SSHTerminalRouteArgs>();
      return _i21.SSHTerminalScreen(
        key: args.key,
        connectionId: args.connectionId,
      );
    },
  );
}

class SSHTerminalRouteArgs {
  const SSHTerminalRouteArgs({this.key, required this.connectionId});

  final _i27.Key? key;

  final String connectionId;

  @override
  String toString() {
    return 'SSHTerminalRouteArgs{key: $key, connectionId: $connectionId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SSHTerminalRouteArgs) return false;
    return key == other.key && connectionId == other.connectionId;
  }

  @override
  int get hashCode => key.hashCode ^ connectionId.hashCode;
}

/// generated route for
/// [_i22.SearchScreen]
class SearchRoute extends _i26.PageRouteInfo<SearchRouteArgs> {
  SearchRoute({
    _i27.Key? key,
    String? initialQuery,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         SearchRoute.name,
         args: SearchRouteArgs(key: key, initialQuery: initialQuery),
         initialChildren: children,
       );

  static const String name = 'SearchRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SearchRouteArgs>(
        orElse: () => const SearchRouteArgs(),
      );
      return _i22.SearchScreen(key: args.key, initialQuery: args.initialQuery);
    },
  );
}

class SearchRouteArgs {
  const SearchRouteArgs({this.key, this.initialQuery});

  final _i27.Key? key;

  final String? initialQuery;

  @override
  String toString() {
    return 'SearchRouteArgs{key: $key, initialQuery: $initialQuery}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SearchRouteArgs) return false;
    return key == other.key && initialQuery == other.initialQuery;
  }

  @override
  int get hashCode => key.hashCode ^ initialQuery.hashCode;
}

/// generated route for
/// [_i23.SettingsScreen]
class SettingsRoute extends _i26.PageRouteInfo<SettingsRouteArgs> {
  SettingsRoute({
    String? initialSection,
    _i27.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         SettingsRoute.name,
         args: SettingsRouteArgs(initialSection: initialSection, key: key),
         initialChildren: children,
       );

  static const String name = 'SettingsRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SettingsRouteArgs>(
        orElse: () => const SettingsRouteArgs(),
      );
      return _i23.SettingsScreen(
        initialSection: args.initialSection,
        key: args.key,
      );
    },
  );
}

class SettingsRouteArgs {
  const SettingsRouteArgs({this.initialSection, this.key});

  final String? initialSection;

  final _i27.Key? key;

  @override
  String toString() {
    return 'SettingsRouteArgs{initialSection: $initialSection, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SettingsRouteArgs) return false;
    return initialSection == other.initialSection && key == other.key;
  }

  @override
  int get hashCode => initialSection.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i24.UserProfileScreen]
class UserProfileRoute extends _i26.PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    required _i28.UserRef userRef,
    _i35.Key? key,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         UserProfileRoute.name,
         args: UserProfileRouteArgs(userRef: userRef, key: key),
         initialChildren: children,
       );

  static const String name = 'UserProfileRoute';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserProfileRouteArgs>();
      return _i24.UserProfileScreen(args.userRef, key: args.key);
    },
  );
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({required this.userRef, this.key});

  final _i28.UserRef userRef;

  final _i35.Key? key;

  @override
  String toString() {
    return 'UserProfileRouteArgs{userRef: $userRef, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserProfileRouteArgs) return false;
    return userRef == other.userRef && key == other.key;
  }

  @override
  int get hashCode => userRef.hashCode ^ key.hashCode;
}

/// generated route for
/// [_i25.WikiViewer]
class WikiViewer extends _i26.PageRouteInfo<WikiViewerArgs> {
  WikiViewer({
    _i27.Key? key,
    _i28.RepoRef? repo,
    String? slug,
    List<_i26.PageRouteInfo>? children,
  }) : super(
         WikiViewer.name,
         args: WikiViewerArgs(key: key, repo: repo, slug: slug),
         initialChildren: children,
       );

  static const String name = 'WikiViewer';

  static _i26.PageInfo page = _i26.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WikiViewerArgs>(
        orElse: () => const WikiViewerArgs(),
      );
      return _i25.WikiViewer(key: args.key, repo: args.repo, slug: args.slug);
    },
  );
}

class WikiViewerArgs {
  const WikiViewerArgs({this.key, this.repo, this.slug});

  final _i27.Key? key;

  final _i28.RepoRef? repo;

  final String? slug;

  @override
  String toString() {
    return 'WikiViewerArgs{key: $key, repo: $repo, slug: $slug}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WikiViewerArgs) return false;
    return key == other.key && repo == other.repo && slug == other.slug;
  }

  @override
  int get hashCode => key.hashCode ^ repo.hashCode ^ slug.hashCode;
}
