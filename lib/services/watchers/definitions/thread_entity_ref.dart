/// Maps notification [Thread] to [EntityRef] for tap navigation.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/notifications_model.dart';

/// Build an [EntityRef] from a notification thread when possible.
/// Returns null if the subject URL cannot be parsed.
EntityRef? entityRefFromThread(Thread thread) {
  final url = thread.subject.url;
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  // API path: /repos/owner/repo/issues/42 or /repos/owner/repo/pulls/42
  final path = uri.path;
  final parts = path.split('/');
  if (parts.length < 5) return null;
  final repoIndex = parts.indexOf('repos');
  if (repoIndex < 0 || repoIndex + 4 > parts.length) return null;
  final owner = parts[repoIndex + 1];
  final repoName = parts[repoIndex + 2];
  final repo = RepoRef(owner: owner, name: repoName);
  final type = thread.subject.type;
  if (type == NotificationSubjectType.issue) {
    final numStr = parts[repoIndex + 4];
    final number = int.tryParse(numStr);
    if (number == null) return null;
    return IssueRef(repo: repo, number: number);
  }
  if (type == NotificationSubjectType.pullRequest) {
    final numStr = parts[repoIndex + 4];
    final number = int.tryParse(numStr);
    if (number == null) return null;
    return PullRequestRef(repo: repo, number: number);
  }
  if (type == NotificationSubjectType.release) {
    final tagOrId = parts.length > repoIndex + 4 ? parts[repoIndex + 4] : null;
    if (tagOrId == null) return null;
    final releaseId = int.tryParse(tagOrId);
    return ReleaseRef(repo: repo, tagName: tagOrId, releaseId: releaseId);
  }
  if (type == NotificationSubjectType.discussion) {
    final numStr = parts.length > repoIndex + 4 ? parts[repoIndex + 4] : null;
    final number = numStr != null ? int.tryParse(numStr) : null;
    if (number == null) return null;
    return DiscussionRef(repo: repo, number: number);
  }
  if (type == NotificationSubjectType.commit) {
    final oid = parts.length > repoIndex + 4 ? parts[repoIndex + 4] : null;
    if (oid == null || oid.isEmpty) return null;
    return CommitRef(repo: repo, oid: oid);
  }
  return null;
}
