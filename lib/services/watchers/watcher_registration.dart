/// Centralised registration of all watcher types with [WatcherFactory].
///
/// Both the foreground [WatcherManager] and the background isolate call
/// [registerAllWatcherFactories] so there is exactly one place to add
/// new watcher types.
library;

import 'package:diohub/services/watchers/definitions/branch_run_watcher.dart';
import 'package:diohub/services/watchers/definitions/code_scanning_watcher.dart';
import 'package:diohub/services/watchers/definitions/deployment_status_watcher.dart';
import 'package:diohub/services/watchers/definitions/follower_watcher.dart';
import 'package:diohub/services/watchers/definitions/inbox_poll_watcher.dart';
import 'package:diohub/services/watchers/definitions/issue_state_watcher.dart';
import 'package:diohub/services/watchers/definitions/milestone_progress_watcher.dart';
import 'package:diohub/services/watchers/definitions/org_pat_request_watcher.dart';
import 'package:diohub/services/watchers/definitions/pending_deployment_watcher.dart';
import 'package:diohub/services/watchers/definitions/pr_merge_status_watcher.dart';
import 'package:diohub/services/watchers/definitions/release_watcher.dart';
import 'package:diohub/services/watchers/definitions/run_status_watcher.dart';
import 'package:diohub/services/watchers/definitions/scheduled_workflow_watcher.dart';
import 'package:diohub/services/watchers/definitions/secret_scanning_watcher.dart';
import 'package:diohub/services/watchers/definitions/star_count_watcher.dart';
import 'package:diohub/services/watchers/definitions/vulnerability_alert_watcher.dart';
import 'package:diohub/services/watchers/serializable_watcher.dart';

/// Register every concrete watcher type.
///
/// Call once at startup (foreground) and once in the background entry.
/// Adding a new watcher type = add one line here.
void registerAllWatcherFactories() {
  // Tier 1: Core (existing)
  WatcherFactory.register('inbox_poll', InboxPollWatcher.fromJson);
  WatcherFactory.register('run_status', RunStatusWatcher.fromJson);

  // Tier 2: PR & Issue Status
  WatcherFactory.register('pr_merge_status', PRMergeStatusWatcher.fromJson);
  WatcherFactory.register('issue_state', IssueStateWatcher.fromJson);
  WatcherFactory.register('release', ReleaseWatcher.fromJson);
  WatcherFactory.register('deployment_status', DeploymentStatusWatcher.fromJson);
  WatcherFactory.register('pending_deployment', PendingDeploymentWatcher.fromJson);

  // Tier 3: Security
  WatcherFactory.register('vulnerability_alert', VulnerabilityAlertWatcher.fromJson);
  WatcherFactory.register('secret_scanning', SecretScanningWatcher.fromJson);
  WatcherFactory.register('code_scanning', CodeScanningWatcher.fromJson);

  // Tier 4-5: Social & CI
  WatcherFactory.register('star_count', StarCountWatcher.fromJson);
  WatcherFactory.register('follower', FollowerWatcher.fromJson);
  WatcherFactory.register('branch_run', BranchRunWatcher.fromJson);
  WatcherFactory.register('scheduled_workflow', ScheduledWorkflowWatcher.fromJson);

  // Tier 6: Project Management & Organization
  WatcherFactory.register('milestone_progress', MilestoneProgressWatcher.fromJson);
  WatcherFactory.register('org_pat_request', OrgPatRequestWatcher.fromJson);
}
