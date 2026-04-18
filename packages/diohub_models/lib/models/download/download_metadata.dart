import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/download/download_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'download_metadata.freezed.dart';

Map<String, dynamic> _repoRefToJson(RepoRef ref) =>
    <String, dynamic>{'owner': ref.owner, 'name': ref.name};

RepoRef _repoRefFromJson(Map<String, dynamic> json) => RepoRef(
      owner: json['owner'] as String,
      name: json['name'] as String,
    );

ReleaseAssetMetadata _releaseAssetMetadataFromJson(Map<String, dynamic> json) =>
    ReleaseAssetMetadata(
      repoRef: _repoRefFromJson(json),
      releaseTag: json['releaseTag'] as String,
      releaseNodeId: json['releaseNodeId'] as String,
      assetName: json['assetName'] as String,
      downloadCount: json['downloadCount'] as int? ?? 0,
    );
SourceArchiveMetadata _sourceArchiveMetadataFromJson(
        Map<String, dynamic> json) =>
    SourceArchiveMetadata(
      repoRef: _repoRefFromJson(json),
      releaseTag: json['releaseTag'] as String,
      format: ArchiveFormat.values.byName(json['format'] as String),
    );
RepoArchiveMetadata _repoArchiveMetadataFromJson(Map<String, dynamic> json) =>
    RepoArchiveMetadata(
      repoRef: _repoRefFromJson(json),
      branch: json['branch'] as String,
      format: ArchiveFormat.values.byName(json['format'] as String),
    );
SingleFileMetadata _singleFileMetadataFromJson(Map<String, dynamic> json) =>
    SingleFileMetadata(
      repoRef: _repoRefFromJson(json),
      branch: json['branch'] as String,
      fullPath: json['fullPath'] as String,
    );
DirectoryMetadata _directoryMetadataFromJson(Map<String, dynamic> json) =>
    DirectoryMetadata(
      repoRef: _repoRefFromJson(json),
      branch: json['branch'] as String,
      directoryPath: json['directoryPath'] as String,
      treeOid: json['treeOid'] as String,
      fileCount: json['fileCount'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      childPaths: (json['childPaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
GistFileMetadata _gistFileMetadataFromJson(Map<String, dynamic> json) =>
    GistFileMetadata(
      gistId: json['gistId'] as String,
      gistDescription: json['gistDescription'] as String?,
      ownerLogin: json['ownerLogin'] as String?,
    );
ArtifactDownloadMetadata _artifactDownloadMetadataFromJson(
        Map<String, dynamic> json) =>
    ArtifactDownloadMetadata(
      workflowRunRef: WorkflowRunRef(
        repo: RepoRef(
          owner: json['owner'] as String,
          name: json['name'] as String,
        ),
        runId: json['runId'] as int,
      ),
      artifactId: json['artifactId'] as int,
      artifactName: json['artifactName'] as String,
    );

@freezed
sealed class DownloadMetadata with _$DownloadMetadata {
  const DownloadMetadata._();

  const factory DownloadMetadata.releaseAsset({
    required RepoRef repoRef,
    required String releaseTag,
    required String releaseNodeId,
    required String assetName,
    @Default(0) int downloadCount,
  }) = ReleaseAssetMetadata;

  const factory DownloadMetadata.sourceArchive({
    required RepoRef repoRef,
    required String releaseTag,
    required ArchiveFormat format,
  }) = SourceArchiveMetadata;

  const factory DownloadMetadata.repoArchive({
    required RepoRef repoRef,
    required String branch,
    required ArchiveFormat format,
  }) = RepoArchiveMetadata;

  const factory DownloadMetadata.singleFile({
    required RepoRef repoRef,
    required String branch,
    required String fullPath,
  }) = SingleFileMetadata;

  const factory DownloadMetadata.directory({
    required RepoRef repoRef,
    required String branch,
    required String directoryPath,
    required String treeOid,
    @Default(0) int fileCount,
    @Default(0) int totalBytes,
    List<String>? childPaths,
  }) = DirectoryMetadata;

  const factory DownloadMetadata.gistFile({
    required String gistId,
    String? gistDescription,
    String? ownerLogin,
  }) = GistFileMetadata;

  const factory DownloadMetadata.artifactDownload({
    required WorkflowRunRef workflowRunRef,
    required int artifactId,
    required String artifactName,
  }) = ArtifactDownloadMetadata;

  Map<String, dynamic> toJson() => map(
        releaseAsset: (m) => m.toJson(),
        sourceArchive: (m) => m.toJson(),
        repoArchive: (m) => m.toJson(),
        singleFile: (m) => m.toJson(),
        directory: (m) => m.toJson(),
        gistFile: (m) => m.toJson(),
        artifactDownload: (m) => m.toJson(),
      );

  static DownloadMetadata fromJson(Map<String, dynamic> json) {
    final String type = json['type'] as String? ?? '';
    return switch (type) {
      'releaseAsset' => _releaseAssetMetadataFromJson(json),
      'sourceArchive' => _sourceArchiveMetadataFromJson(json),
      'repoArchive' => _repoArchiveMetadataFromJson(json),
      'singleFile' => _singleFileMetadataFromJson(json),
      'directory' => _directoryMetadataFromJson(json),
      'gistFile' => _gistFileMetadataFromJson(json),
      'artifactDownload' => _artifactDownloadMetadataFromJson(json),
      _ => throw ArgumentError('Unknown DownloadMetadata type: $type'),
    };
  }
}

extension ReleaseAssetMetadataX on ReleaseAssetMetadata {
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'releaseAsset',
        ..._repoRefToJson(repoRef),
        'releaseTag': releaseTag,
        'releaseNodeId': releaseNodeId,
        'assetName': assetName,
        'downloadCount': downloadCount,
      };
}

extension SourceArchiveMetadataX on SourceArchiveMetadata {
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'sourceArchive',
        ..._repoRefToJson(repoRef),
        'releaseTag': releaseTag,
        'format': format.name,
      };
}

extension RepoArchiveMetadataX on RepoArchiveMetadata {
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'repoArchive',
        ..._repoRefToJson(repoRef),
        'branch': branch,
        'format': format.name,
      };
}

extension SingleFileMetadataX on SingleFileMetadata {
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'singleFile',
        ..._repoRefToJson(repoRef),
        'branch': branch,
        'fullPath': fullPath,
      };
}

extension DirectoryMetadataX on DirectoryMetadata {
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'directory',
        ..._repoRefToJson(repoRef),
        'branch': branch,
        'directoryPath': directoryPath,
        'treeOid': treeOid,
        'fileCount': fileCount,
        'totalBytes': totalBytes,
        if (childPaths != null) 'childPaths': childPaths,
      };
}

extension GistFileMetadataX on GistFileMetadata {
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'gistFile',
        'gistId': gistId,
        if (gistDescription != null) 'gistDescription': gistDescription,
        if (ownerLogin != null) 'ownerLogin': ownerLogin,
      };
}

extension ArtifactDownloadMetadataX on ArtifactDownloadMetadata {
  RepoRef get repoRef => workflowRunRef.repo;
  int get runId => workflowRunRef.runId;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': 'artifactDownload',
        'owner': repoRef.owner,
        'name': repoRef.name,
        'runId': runId,
        'artifactId': artifactId,
        'artifactName': artifactName,
      };
}
