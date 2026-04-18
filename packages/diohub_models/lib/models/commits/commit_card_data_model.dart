import 'package:diohub_graphql/fragments/fragment_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'commit_card_data_model.freezed.dart';

/// Repository information for commit contributions
@freezed
abstract class CommitRepositoryInfo with _$CommitRepositoryInfo {
  const factory CommitRepositoryInfo({
    required final String owner,
    required final String name,
    required final String url,
    required final int count,
    final String? id,
    final RepoCardData? repoCardFields,
  }) = _CommitRepositoryInfo;
}

/// Unified data model for CommitCard
@freezed
abstract class CommitCardDataModel with _$CommitCardDataModel {
  const factory CommitCardDataModel({
    required final int count,
    required final DateTime date,
    required final List<CommitRepositoryInfo> repositories,
  }) = _CommitCardDataModel;
  const CommitCardDataModel._();

  /// Factory for creating from EventsModel (PushEvent).
  /// [server] used for fallback repo URL when [event.repo.url] is null.
  factory CommitCardDataModel.fromPushEvent(
    final EventsModel event, {
    final ServerConfig? server,
  }) {
    final EventPayload payload = event.payload;
    final int commitCount = payload.head != null ? 1 : 0;
    final DateTime date = event.createdAt;

    final EventRepo repo = event.repo;
    final String repoName = repo.name;
    final RepoRef repoRef = RepoRef.fromFullName(repoName);
    final ServerConfig cfg = server ?? ServerConfig.gitHubDotCom;
    final String url = repo.url ?? cfg.webUrl('/$repoName').toString();

    return CommitCardDataModel(
      count: commitCount,
      date: date,
      repositories: <CommitRepositoryInfo>[
        CommitRepositoryInfo(
          owner: repoRef.owner,
          name: repoRef.name,
          url: url,
          count: commitCount,
        ),
      ],
    );
  }

  /// Total number of repositories
  int get repositoryCount => repositories.length;

  /// Primary repository (first one, used for display)
  CommitRepositoryInfo? get primaryRepository =>
      repositories.isNotEmpty ? repositories.first : null;
}
