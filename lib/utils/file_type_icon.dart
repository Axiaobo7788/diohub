import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:mime/mime.dart';

/// Returns an icon for the given file name and optional MIME type.
IconData fileTypeIcon(String fileName, String? contentType) {
  final String lower = fileName.toLowerCase();
  if (lower.endsWith('.zip') || lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
    return Octicons.file_zip;
  }
  if (lower.endsWith('.apk')) {
    return Octicons.package;
  }
  final String? mime = contentType ?? lookupMimeType(fileName);
  if (mime != null) {
    if (mime.startsWith('image/')) return Octicons.image;
    if (mime.startsWith('video/')) return Octicons.device_camera_video;
    if (mime.contains('text/') ||
        mime.contains('json') ||
        mime.contains('javascript') ||
        mime.contains('xml')) {
      return Octicons.file_code;
    }
  }
  return Octicons.file;
}
