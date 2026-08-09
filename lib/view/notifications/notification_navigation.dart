import 'package:auto_route/auto_route.dart';
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/utils/open_in_app_browser.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the best native destination for a GitHub notification subject.
Future<void> openNotificationThread(
  final BuildContext context,
  final WidgetRef ref,
  final Thread notification,
) async {
  final String? subjectUrl = notification.subject.url;
  final NotificationSubjectType? type = notification.subject.type;

  try {
    switch (type) {
      case NotificationSubjectType.issue when _hasValue(subjectUrl):
        await IssueRef.fromApiUrl(subjectUrl!).navigate(context, ref);
        return;
      case NotificationSubjectType.pullRequest when _hasValue(subjectUrl):
        await PullRequestRef.fromApiUrl(subjectUrl!).navigate(context, ref);
        return;
      case NotificationSubjectType.commit when _hasValue(subjectUrl):
        await CommitRef.fromApiUrl(subjectUrl!).navigate(context, ref);
        return;
      case NotificationSubjectType.release:
        final List<String> parts = notification.repository.fullName.split('/');
        if (parts.length >= 2) {
          await RepoRef(
            owner: parts[0],
            name: parts[1],
            location: const RepoLocationReleases(),
          ).navigate(context, ref);
          return;
        }
      case NotificationSubjectType.checkSuite:
        final _ParsedActionsRun? parsed = _parseActionsRunIdFromUrl(
          notification.url ?? subjectUrl ?? '',
        );
        if (parsed != null) {
          final WorkflowRunRef workflowRunRef = WorkflowRunRef(
            repo: RepoRef(owner: parsed.owner, name: parsed.repoName),
            runId: parsed.runId,
          );
          final PageRouteInfo? route = ref
              .read(premiumRoutingProvider)
              .resolveEntityRoute(workflowRunRef);
          await context.router.push<void>(
            route ?? RepositoryRoute(repo: workflowRunRef.repo),
          );
          return;
        }
      case NotificationSubjectType.discussion:
        final String? url = notification.url;
        if (_hasValue(url)) {
          await openInAppBrowser(Uri.parse(url!));
          return;
        }
      default:
        break;
    }
  } on Object catch (error, stackTrace) {
    AppLogger.warning(
      'Failed to open notification thread natively',
      error: error,
      stackTrace: stackTrace,
      tag: 'Notifications',
    );
  }

  final String? fallback = notification.url;
  if (_hasValue(fallback)) {
    await launchUrl(Uri.parse(fallback!));
  }
}

bool _hasValue(final String? value) => value != null && value.isNotEmpty;

final class _ParsedActionsRun {
  const _ParsedActionsRun({
    required this.owner,
    required this.repoName,
    required this.runId,
  });

  final String owner;
  final String repoName;
  final int runId;
}

_ParsedActionsRun? _parseActionsRunIdFromUrl(final String url) {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.pathSegments.isEmpty) {
    return null;
  }
  final List<String> segments = uri.pathSegments;
  if (segments.length >= 5 &&
      segments[2] == 'actions' &&
      segments[3] == 'runs') {
    final int? runId = int.tryParse(segments[4]);
    if (runId != null) {
      return _ParsedActionsRun(
        owner: segments[0],
        repoName: segments[1],
        runId: runId,
      );
    }
  }
  if (segments.length >= 6 &&
      segments[0] == 'repos' &&
      segments[3] == 'actions' &&
      segments[4] == 'runs') {
    final int? runId = int.tryParse(segments[5]);
    if (runId != null) {
      return _ParsedActionsRun(
        owner: segments[1],
        repoName: segments[2],
        runId: runId,
      );
    }
  }
  return null;
}
