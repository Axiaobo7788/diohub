import 'dart:core';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/common/misc/deep_link_widget.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/wrappers/api_wrapper_widget.dart';
import 'package:diohub/graphql/queries/issues_pulls/__generated__/issue_pull_info.data.gql.dart';
import 'package:diohub/providers/issue_pulls/issue_provider.dart';
import 'package:diohub/providers/issue_pulls/pull_provider.dart';
import 'package:diohub/routes/router.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/issues/issues_service.dart';
import 'package:diohub/utils/utils.dart';
import 'package:diohub/view/issues_pulls/issue_screen.dart';
import 'package:diohub/view/issues_pulls/pull_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

IssuePullRoute issuePullScreenRoute(final PathData path) =>
    getRoute<IssuePullRoute>(
      path,
      onDeepLink: (final PathData path) => IssuePullRoute(
        ownerName: path.component(0)!,
        repoName: path.component(1)!,
        number: int.parse(path.component(3)!),
      ),
      onAPILink: (final PathData path) => IssuePullRoute(
        ownerName: path.component(1)!,
        repoName: path.component(2)!,
        number: int.parse(path.component(4)!),
      ),
    );

@RoutePage()
class IssuePullScreen extends DeepLinkWidget {
  const IssuePullScreen({
    required this.number,
    required this.repoName,
    required this.ownerName,
    super.key,
    this.commentsSince,
    this.initialIndex = 0,
  });

  final DateTime? commentsSince;
  final int initialIndex;
  final int number;
  final String ownerName;
  final String repoName;

  @override
  State<IssuePullScreen> createState() => _IssuePullScreenState();
}

class _IssuePullScreenState extends DeepLinkWidgetState<IssuePullScreen> {
  final GlobalKey<
          APIWrapperState<GissuePullInfoData_repository_issueOrPullRequest>>
      key = GlobalKey<
          APIWrapperState<GissuePullInfoData_repository_issueOrPullRequest>>();

  @override
  void handleDeepLink(final PathData deepLinkData) {
    // TODO(namanshergill): implement handleDeepLink
  }

  Future<void> onRefresh() async {
    await key.currentState?.refreshData();
  }

  @override
  Widget build(final BuildContext context) =>
      APIWrapper<GissuePullInfoData_repository_issueOrPullRequest>.deferred(
        apiCall: ({required final bool refresh}) async =>
            IssuesService.getIssuePullInfo(
          widget.number,
          repo: widget.repoName,
          user: widget.ownerName,
          refresh: refresh,
        ),
        key: key,
        loadingBuilder: (final BuildContext context) => Scaffold(
          appBar: AppBar(
            elevation: 0,
          ),
          body: const LoadingIndicator(),
        ),
        errorBuilder: (final BuildContext context, final Object? data) =>
            Scaffold(
          appBar: AppBar(
            elevation: 0,
          ),
          body: Center(
            child: Text(data.toString()),
          ),
        ),
        builder: (
          final BuildContext context,
          final GissuePullInfoData_repository_issueOrPullRequest data,
        ) =>
            data.when(
          issue: (
            final GissuePullInfoData_repository_issueOrPullRequest__asIssue p0,
          ) =>
              ChangeNotifierProvider<IssueProvider>(
            create: (final BuildContext context) => IssueProvider(p0),
            lazy: false,
            builder: (final BuildContext context, final Widget? child) =>
                IssueScreen(
              p0,
              onRefresh: onRefresh,
            ),
          ),
          pullRequest: (
            final GissuePullInfoData_repository_issueOrPullRequest__asPullRequest
                p0,
          ) =>
              ChangeNotifierProvider<PullProvider>(
            create: (final BuildContext context) => PullProvider(p0),
            lazy: false,
            builder: (final BuildContext context, final Widget? child) =>
                PullScreen(
              data as GpullInfo, onRefresh: onRefresh,
              // apiWrapperController: apiWrapperController,
            ),
          ),
          orElse: unimplemented,
        ),
      );
}
