import 'package:dio/dio.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';

final class ReadmeImageResourceSpecs {
  const ReadmeImageResourceSpecs({
    required this.source,
    required this.artifact,
  });

  final ResourceSpec<ReadmeImageSource?> source;
  final ResourceSpec<ReadmeImageResult> artifact;
}

typedef ReadmeImageResourceSpecFactory =
    ReadmeImageResourceSpecs Function({
      required String url,
      required ResourceScope scope,
    });

const ResourcePolicy readmeImageSourcePolicy = ResourcePolicy(
  freshFor: Duration(minutes: 1),
  retainFor: Duration(minutes: 5),
  allowPrefetch: false,
);

const ResourcePolicy readmeImageArtifactPolicy = ResourcePolicy(
  freshFor: Duration(minutes: 1),
  retainFor: Duration(minutes: 5),
  allowPrefetch: false,
);

const int readmeImageMaxSourceWeight =
    (kMaxReadmeImageBytes + resourceWeightUnitBytes - 1) ~/
    resourceWeightUnitBytes;
const int readmeImageRasterArtifactWeight = 1;
const int readmeImageMaxRasterDependencyChainWeight =
    readmeImageMaxSourceWeight + readmeImageRasterArtifactWeight;

ResourceId<ReadmeImageSource?> readmeImageSourceResourceId({
  required final String url,
  required final ResourceScope scope,
}) => ResourceId<ReadmeImageSource?>(
  kind: 'readme-image-source',
  version: 1,
  scope: scope,
  key: _normalizedUrl(url),
);

ResourceId<ReadmeImageResult> readmeImageArtifactResourceId({
  required final String url,
  required final ResourceScope scope,
}) => ResourceId<ReadmeImageResult>(
  kind: 'readme-image-artifact',
  version: 2,
  scope: scope,
  key: _normalizedUrl(url),
);

ReadmeImageResourceSpecs readmeImageResourceSpecs({
  required final String url,
  required final ResourceScope scope,
  required final ReadmeImageClassifier classifier,
}) {
  final String normalizedUrl = _normalizedUrl(url);
  final Set<ResourceTag> tags = <ResourceTag>{
    ResourceTag('readme-image', normalizedUrl),
  };
  final ResourceSpec<ReadmeImageSource?> source =
      ResourceSpec<ReadmeImageSource?>(
        id: readmeImageSourceResourceId(url: normalizedUrl, scope: scope),
        policy: readmeImageSourcePolicy,
        tags: tags,
        contract: 'unauthenticated-readme-image-source-v1',
        load: (final ResourceLoadContext _) async {
          try {
            final ReadmeImageSource value = await classifier.fetch(
              normalizedUrl,
            );
            return ResourceLoadResult<ReadmeImageSource?>(
              data: value,
              estimatedWeight: resourceWeightForBytes(value.bytes.length),
            );
          } on DioException {
            return const ResourceLoadResult<ReadmeImageSource?>(data: null);
          } on FormatException {
            return const ResourceLoadResult<ReadmeImageSource?>(data: null);
          } on ReadmeImageTooLarge {
            return const ResourceLoadResult<ReadmeImageSource?>(data: null);
          }
        },
      );
  final ResourceSpec<ReadmeImageResult> artifact =
      ResourceSpec<ReadmeImageResult>(
        id: readmeImageArtifactResourceId(url: normalizedUrl, scope: scope),
        policy: readmeImageArtifactPolicy,
        tags: tags,
        contract: 'readme-image-classification-v2',
        workKind: ResourceWorkKind.compute,
        dependencies: <ResourceId<dynamic>>{source.id},
        load: (final ResourceLoadContext context) async {
          final ReadmeImageSource? value = (await context.require(source)).data;
          if (value == null) {
            return ResourceLoadResult<ReadmeImageResult>(
              data: ReadmeImageResult.unavailable(),
              origin: ResourceOrigin.derived,
            );
          }
          final ReadmeImageClassification classification = await context
              .runInWorker<ReadmeImageSource, ReadmeImageClassification>(
                value,
                classifyReadmeImageSource,
              );
          final ReadmeImageResult result = materializeReadmeImageResult(
            value,
            classification,
          );
          return ResourceLoadResult<ReadmeImageResult>(
            data: result,
            origin: ResourceOrigin.derived,
            estimatedWeight: classification.kind == ReadmeImageKind.svg
                ? resourceWeightForBytes(
                    (classification.svgString?.length ?? 0) * 2,
                  )
                : readmeImageRasterArtifactWeight,
          );
        },
      );
  return ReadmeImageResourceSpecs(source: source, artifact: artifact);
}

void invalidateReadmeImageResource({
  required final ResourceRuntime runtime,
  required final ResourceScope scope,
  required final String url,
}) {
  runtime.invalidate(
    ResourceSelector.forId(readmeImageSourceResourceId(url: url, scope: scope)),
  );
}

String _normalizedUrl(final String url) {
  final Uri? uri = Uri.tryParse(url);
  return uri == null ? url : uri.replace(fragment: '').toString();
}
