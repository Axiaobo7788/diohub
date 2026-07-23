import 'package:dio/dio.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

const Duration kReadmeImageCacheDuration = Duration(minutes: 1);

/// Riverpod provider for ReadmeImageClassifier
final Provider<ReadmeImageClassifier> readmeImageClassifierProvider =
    Provider<ReadmeImageClassifier>(
      (final Ref ref) => ReadmeImageClassifier(
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 12),
          ),
        ),
      ),
    );

/// Riverpod provider family for caching image classification results
final FutureProviderFamily<ReadmeImageResult, String>
readmeImageResultProvider = FutureProvider.autoDispose
    .family<ReadmeImageResult, String>((final Ref ref, final String url) async {
      keepAliveFor(ref, duration: kReadmeImageCacheDuration);
      // readmeImageClassifierProvider is a stable singleton — use ref.read
      // instead of ref.watch since the value never changes.
      final ReadmeImageClassifier classifier = ref.read(
        readmeImageClassifierProvider,
      );
      try {
        return await classifier.load(url);
      } on DioException {
        // README images are optional document content. A timeout or corrupt image
        // must not fail the Riverpod provider tree or the surrounding document.
        return ReadmeImageResult.unavailable();
      }
    });
