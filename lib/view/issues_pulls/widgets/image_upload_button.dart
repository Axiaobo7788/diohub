// ignore: no_dart_io_in_view
// ignore: no_dart_io_in_view
import 'dart:io';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/compose/image_upload_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Button that picks an image, uploads it to Catbox.moe, and calls
/// [onInsertMarkdown] with markdown image syntax. Used in compose body editors
/// (e.g. CommentBox, ComposeScaffold toolbar).
class ImageUploadButton extends ConsumerStatefulWidget {
  const ImageUploadButton({
    required this.onInsertMarkdown,
    super.key,
  });

  final void Function(String markdown) onInsertMarkdown;

  @override
  ConsumerState<ImageUploadButton> createState() => _ImageUploadButtonState();
}

class _ImageUploadButtonState extends ConsumerState<ImageUploadButton> {
  bool _uploading = false;

  Future<void> _onTap() async {
    if (_uploading) return;
    final ImagePicker picker = ImagePicker();
    final XFile? xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null || !mounted) return;
    final File file = File(xFile.path);
    if (!file.existsSync()) {
      if (mounted) {
        ref.read(notificationServiceProvider).error('Image file not found');
      }
      return;
    }
    setState(() => _uploading = true);
    try {
      final String? url = await ref
          .read(imageUploadProvider.notifier)
          .mutate(file);
      if (!mounted) return;
      if (url != null) {
        widget.onInsertMarkdown('\n![image]($url)\n');
      } else {
        ref.read(notificationServiceProvider).error('Upload failed');
      }
    } catch (e, st) {
      AppLogger.warning(
        'Image upload failed',
        error: e,
        stackTrace: st,
        tag: 'ImageUploadButton',
      );
      if (!mounted) return;
      ref.read(notificationServiceProvider).error('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(final BuildContext context) => IconButton(
        onPressed: _uploading ? null : _onTap,
        tooltip: 'Upload image',
        icon: _uploading ? const ButtonSpinner(size: 20) : const Icon(Icons.add_photo_alternate_outlined),
      );
}
