import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/bottom_sheet/paginated_list_sheet.dart';
import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/page_source.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub_graphql/queries/repositories/repo_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/download/download_item.dart';
import 'package:diohub_models/models/download/download_metadata.dart';
import 'package:diohub/providers/database_providers.dart'
    show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/opacities.dart';
import 'package:diohub/utils/file_type_icon.dart';
import 'package:diohub/utils/format_bytes.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a bottom sheet listing a release's assets with download indicators.
/// Uses cursor pagination via [PaginatedListSheetBody].
/// [repoRef], [releaseNodeId], [releaseTag], and [releaseName] identify the release.
void showReleaseAssetsSheet(
  BuildContext context,
  WidgetRef ref, {
  required RepoRef repoRef,
  required String releaseNodeId,
  required String releaseTag,
  required String releaseName,
}) {
  AppSheet.scrollable<void>(
    context,
    header: AppSheetHeader.text(
      'Release assets',
      subtitle: Text(
        '$releaseName · $releaseTag',
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
    bodyBuilder:
        (
          BuildContext ctx,
          StateSetter setState,
          ScrollController scrollController,
        ) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ..._buildSourceArchiveHeader(
                ctx,
                repoRef: repoRef,
                releaseTag: releaseTag,
                releaseName: releaseName,
              ),
              Expanded(
                child: PaginatedListSheetBody<ReleaseAssetNode>(
                  scrollController: scrollController,
                  createController: () =>
                      PaginationController<ReleaseAssetNode, ReleaseAssetNode>(
                        source: CursorForwardSource<ReleaseAssetNode>(
                          fetch: ({required int first, String? after}) {
                            final apiClient = ref.read(apiClientProvider);
                            return repoRef
                                .releases(apiClient)
                                .fetchReleaseAssetsPage(
                                  releaseNodeId,
                                  first: first,
                                  after: after,
                                );
                          },
                        ),
                        idOf: (final ReleaseAssetNode a) => a.id,
                        pageSize: 30,
                      ),
                  itemBuilder:
                      (
                        final BuildContext context,
                        final WidgetRef ref,
                        final ReleaseAssetNode asset,
                        final int index,
                        final void Function(ItemPatch patch) applyPatch,
                      ) => _buildAssetTile(
                        context,
                        asset,
                        repoRef: repoRef,
                        releaseNodeId: releaseNodeId,
                        releaseTag: releaseTag,
                        releaseName: releaseName,
                      ),
                  emptyBuilder: (final BuildContext context) => Padding(
                    padding: context.spacing.spaciousPadding,
                    child: Center(
                      child: Text(
                        'No assets',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
  );
}

List<Widget> _buildSourceArchiveHeader(
  BuildContext context, {
  required RepoRef repoRef,
  required String releaseTag,
  required String releaseName,
}) {
  final String zipUrl = '${repoRef.apiPath}/zipball/$releaseTag';
  final String tarGzUrl = '${repoRef.apiPath}/tarball/$releaseTag';
  return <Widget>[
    Padding(
      padding: context.spacing.listInset,
      child: Row(
        children: <Widget>[
          Text(
            'Source code ',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
    const Divider(height: 1),
  ];
}

DownloadItem _buildSourceArchiveItem(
  RepoRef repoRef,
  String releaseName,
  String releaseTag,
  ArchiveFormat format,
  String downloadUrl,
  String displayName,
) {
  final String suffix = format == ArchiveFormat.zip ? 'zip' : 'tar.gz';
  return DownloadItem(
    id: '${repoRef.owner}-${repoRef.name}-$releaseTag-$suffix',
    displayName: displayName,
    fileName: '${releaseName.replaceAll(RegExp(r'[^\w\-.]'), '_')}.$suffix',
    downloadUrl: downloadUrl,
    totalBytes: null,
    type: DownloadType.sourceArchive,
    contentType: null,
    createdAt: DateTime.now(),
    metadata: DownloadMetadata.sourceArchive(
      repoRef: repoRef,
      releaseTag: releaseTag,
      format: format,
    ),
  );
}

String _assetSubtitle(ReleaseAssetNode asset) {
  final String sizeStr = formatBytes(asset.size);
  final int count = asset.downloadCount;
  final String countStr = count == 1 ? '1 download' : '$count downloads';
  return '$sizeStr · $countStr';
}

Widget _buildAssetTile(
  BuildContext context,
  ReleaseAssetNode asset, {
  required RepoRef repoRef,
  required String releaseNodeId,
  required String releaseTag,
  required String releaseName,
}) {
  final String downloadUrl = asset.downloadUrl.toString();
  return ListTile(
    leading: Icon(
      fileTypeIcon(asset.name, asset.contentType),
      color: context.colorScheme.primary,
      size: 24,
    ),
    title: Text(
      asset.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodyLarge,
    ),
    subtitle: Text(
      _assetSubtitle(asset),
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

DownloadItem _buildDownloadItem(
  ReleaseAssetNode asset, {
  required RepoRef repoRef,
  required String releaseNodeId,
  required String releaseTag,
}) {
  final String downloadUrl = asset.downloadUrl.toString();
  return DownloadItem(
    id: asset.id,
    displayName: asset.name,
    fileName: asset.name,
    downloadUrl: downloadUrl,
    totalBytes: asset.size,
    type: DownloadType.releaseAsset,
    contentType: asset.contentType,
    createdAt: DateTime.now(),
    metadata: DownloadMetadata.releaseAsset(
      repoRef: repoRef,
      releaseTag: releaseTag,
      releaseNodeId: releaseNodeId,
      assetName: asset.name,
      downloadCount: asset.downloadCount,
    ),
  );
}
