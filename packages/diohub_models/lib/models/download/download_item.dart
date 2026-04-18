import 'package:diohub_models/models/download/download_metadata.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'download_item.freezed.dart';
part 'download_item.g.dart';

enum DownloadType {
  releaseAsset,
  sourceArchive,
  repoArchive,
  singleFile,
  directoryArchive,
  gistFile,
  workflowArtifact,
}

enum ArchiveFormat {
  zip,
  tarGz,
}

DownloadType _typeFromString(String? v) {
  if (v == null) return DownloadType.singleFile;
  return DownloadType.values.byName(v);
}

@freezed
abstract class DownloadItem with _$DownloadItem {
  const DownloadItem._();

  factory DownloadItem({
    required String id,
    required String displayName,
    required String fileName,
    required String downloadUrl,
    int? totalBytes,
    @JsonKey(fromJson: _typeFromString, toJson: _downloadTypeToJson)
    required DownloadType type,
    String? contentType,
    required DateTime createdAt,
    @JsonKey(fromJson: _metadataFromJson, toJson: _metadataToJson)
    required DownloadMetadata metadata,
  }) = _DownloadItem;

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);
}

String _downloadTypeToJson(DownloadType t) => t.name;

DownloadMetadata _metadataFromJson(Map<String, dynamic> json) =>
    DownloadMetadata.fromJson(json);

Map<String, dynamic> _metadataToJson(DownloadMetadata m) => m.toJson();
