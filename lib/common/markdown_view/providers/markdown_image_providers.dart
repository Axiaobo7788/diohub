import 'package:dio/dio.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/future_provider.dart';

/// Riverpod provider for ReadmeImageClassifier
final Provider<ReadmeImageClassifier> readmeImageClassifierProvider =
    Provider<ReadmeImageClassifier>(
        (final Ref ref) => ReadmeImageClassifier(Dio()));

/// Riverpod provider family for caching image classification results
final FutureProviderFamily<ReadmeImageResult, String>
    readmeImageResultProvider =
    FutureProvider.autoDispose.family<ReadmeImageResult, String>(
  (final Ref ref, final String url) async {
    // readmeImageClassifierProvider is a stable singleton — use ref.read
    // instead of ref.watch since the value never changes.
    final ReadmeImageClassifier classifier =
        ref.read(readmeImageClassifierProvider);
    return classifier.load(url);
  },
);
