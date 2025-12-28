import 'package:dio/dio.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for ReadmeImageClassifier
final readmeImageClassifierProvider = Provider<ReadmeImageClassifier>((ref) {
  return ReadmeImageClassifier(Dio());
});

/// Riverpod provider family for caching image classification results
final readmeImageResultProvider =
    FutureProvider.family<ReadmeImageResult, String>(
  (ref, url) async {
    final classifier = ref.watch(readmeImageClassifierProvider);
    return await classifier.load(url);
  },
);
