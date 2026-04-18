import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/capabilities/capabilities.dart';
import 'package:diohub_models/models/issues/issue_pull_mutation_result.dart';
import 'package:diohub/services/git_database/git_database_service.dart';
import 'package:diohub/services/users/user_contributions_service.dart';
import 'package:diohub/services/issues/issue_creation_service.dart';
import 'package:diohub/services/issues/issue_service.dart';
import 'package:diohub/services/pulls/pull_creation_service.dart';
import 'package:diohub/services/pulls/pull_service.dart';
import 'package:diohub/services/repositories/repo_branch_service.dart';
import 'package:diohub/services/repositories/repo_collaborator_service.dart';
import 'package:diohub/services/repositories/repo_deployment_service.dart';
import 'package:diohub/services/repositories/repo_label_milestone_service.dart';
import 'package:diohub/services/repositories/repo_release_service.dart';
import 'package:diohub/services/repositories/repo_services.dart';
import 'package:diohub/services/repositories/repo_stats_service.dart';
import 'package:diohub/services/repositories/repo_workflows_service.dart';
import 'package:diohub/services/repositories/wiki_service.dart';

/// Common capability services shared by issues and pull requests.
abstract interface class CommonEntityService {
  CommentableService get commentable;
  LockableService get lockable;
  SubscribableService get subscribable;
  
  Future<IssueCommentUpdate?> updateComment(String commentNodeId, String body);
  Future<void> deleteComment(String commentNodeId);
}

/// Adapter implementation for IssueService.
class _IssueServiceAdapter implements CommonEntityService {
  final IssueService _service;
  
  _IssueServiceAdapter(this._service);
  
  @override
  CommentableService get commentable => _service.commentable;
  
  @override
  LockableService get lockable => _service.lockable;
  
  @override
  SubscribableService get subscribable => _service.subscribable;
  
  @override
  Future<IssueCommentUpdate?> updateComment(String commentNodeId, String body) =>
      _service.updateCommentById(commentNodeId, body);
  
  @override
  Future<void> deleteComment(String commentNodeId) =>
      _service.deleteCommentById(commentNodeId);
}

/// Adapter implementation for PullService.
class _PullServiceAdapter implements CommonEntityService {
  final PullService _service;
  
  _PullServiceAdapter(this._service);
  
  @override
  CommentableService get commentable => _service.commentable;
  
  @override
  LockableService get lockable => _service.lockable;
  
  @override
  SubscribableService get subscribable => _service.subscribable;
  
  @override
  Future<IssueCommentUpdate?> updateComment(String commentNodeId, String body) =>
      _service.updateCommentById(commentNodeId, body);
  
  @override
  Future<void> deleteComment(String commentNodeId) =>
      _service.deleteCommentById(commentNodeId);
}

extension EntityRefCommonServices on EntityRef {
  CommonEntityService commonServices(ApiClient client) => switch (this) {
    IssueRef r => _IssueServiceAdapter(IssueService(client, r)),
    PullRequestRef r => _PullServiceAdapter(PullService(client, r)),
    _ => throw UnsupportedError('$runtimeType has no common services'),
  };
}

extension RepoRefServices on RepoRef {
  RepositoryServices services(ApiClient client) => RepositoryServices(client, this);
  IssueCreationService issueCreation(ApiClient client) => IssueCreationService(client, this);
  PullCreationService pullCreation(ApiClient client) => PullCreationService(client, this);
  RepoBranchService branches(ApiClient client) => RepoBranchService(client, this);
  RepoReleaseService releases(ApiClient client) => RepoReleaseService(client, this);
  RepoLabelMilestoneService labelsAndMilestones(ApiClient client) =>
      RepoLabelMilestoneService(client, this);
  RepoCollaboratorService collaborators(ApiClient client) => RepoCollaboratorService(client, this);
  RepoDeploymentService deployments(ApiClient client) => RepoDeploymentService(client, this);
  GitDatabaseService gitDb(ApiClient client) => GitDatabaseService(client, this);
  WikiService wiki(ApiClient client) => WikiService(client, this);
  RepoWorkflowsService workflows(ApiClient client) => RepoWorkflowsService(client, this);
  RepoStatsService stats(ApiClient client) => RepoStatsService(client, this);
}

extension IssueRefServices on IssueRef {
  IssueService services(ApiClient client) => IssueService(client, this);
}

extension PullRequestRefServices on PullRequestRef {
  PullService services(ApiClient client) => PullService(client, this);
}

extension UserRefServices on UserRef {
  UserContributionsService contributions(ApiClient client) => UserContributionsService(client, this);
}
