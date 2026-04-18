/// Mutation to upload an image to Catbox and return the URL.
/// Used by compose toolbar (e.g. ImageUploadButton).
library;

import 'dart:io';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/riverpod/mutation_state.dart';
import 'package:diohub/services/image_upload/catbox_upload_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImageUploadMutationNotifier extends Notifier<MutationState<String>>
    with MutationNotifierMixin<String> {
  late final CatboxUploadService _uploadService = CatboxUploadService();

  @override
  MutationState<String> build() {
    initMutationDisposal();
    return MutationState.idle();
  }

  /// Uploads [file] and returns the image URL on success.
  /// Caller can await and use the returned URL or watch state.
  Future<String?> mutate(File file) async {
    if (state is MutationLoading<String>) return null;
    state = MutationState.loading();
    try {
      final String url = await _uploadService.uploadImage(file);
      state = MutationState.success(url);
      scheduleReset();
      return url;
    } catch (e, st) {
      AppLogger.warning(
        'Image upload failed',
        error: e,
        stackTrace: st,
        tag: 'ImageUpload',
      );
      state = MutationState.error(e, st);
      scheduleReset();
      return null;
    }
  }
}

final imageUploadProvider =
    NotifierProvider<ImageUploadMutationNotifier, MutationState<String>>(
  ImageUploadMutationNotifier.new,
);
