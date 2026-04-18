import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';

/// Domain data for a deployment card. Adapter from GQL node.
class DeploymentCardData {
  const DeploymentCardData({
    required this.id,
    required this.environment,
    this.state,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.refName,
    this.commitAbbreviatedOid,
    this.commitMessage,
    this.commitFullOid,
    this.creatorLogin,
    this.creatorAvatarUrl,
    this.latestStatusState,
    this.latestStatusCreatedAt,
    this.latestStatusDescription,
    this.latestStatusLogUrl,
  });

  final String id;
  final String environment;
  final String? state;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
  final String? refName;
  final String? commitAbbreviatedOid;
  final String? commitMessage;
  final String? commitFullOid;
  final String? creatorLogin;
  final String? creatorAvatarUrl;
  final String? latestStatusState;
  final String? latestStatusCreatedAt;
  final String? latestStatusDescription;
  final String? latestStatusLogUrl;

  factory DeploymentCardData.fromGql(
    final DeploymentNode node,
  ) {
    final String? stateName = node.state?.name;
    final String? statusStateName = node.latestStatus?.state?.name;
    return DeploymentCardData(
      id: node.id,
      environment: node.environment ??
          node.latestEnvironment ??
          node.originalEnvironment ??
          'Unknown',
      state: stateName,
      description: node.description,
      createdAt: node.createdAt?.toIso8601String(),
      updatedAt: node.updatedAt?.toIso8601String(),
      refName: node.ref?.name,
      commitAbbreviatedOid: node.commit?.abbreviatedOid,
      commitMessage: node.commit?.message,
      commitFullOid: node.commitOid,
      creatorLogin: node.creator.login,
      creatorAvatarUrl: node.creator.avatarUrl?.toString(),
      latestStatusState: statusStateName,
      latestStatusCreatedAt:
          node.latestStatus?.createdAt?.toIso8601String(),
      latestStatusDescription: node.latestStatus?.description,
      latestStatusLogUrl: node.latestStatus?.logUrl?.toString(),
    );
  }
}
