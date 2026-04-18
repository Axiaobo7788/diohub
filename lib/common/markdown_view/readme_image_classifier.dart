import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum ReadmeImageKind { svg, raster }

class ReadmeImageResult {
  const ReadmeImageResult._({
    required this.kind,
    required this.bytes,
    this.svgString,
  });

  factory ReadmeImageResult.svg(final String svg, final Uint8List bytes) =>
      ReadmeImageResult._(
        kind: ReadmeImageKind.svg,
        bytes: bytes,
        svgString: svg,
      );

  factory ReadmeImageResult.raster(final Uint8List bytes) =>
      ReadmeImageResult._(
        kind: ReadmeImageKind.raster,
        bytes: bytes,
      );
  final ReadmeImageKind kind;
  final Uint8List bytes;
  final String? svgString;
}

class ReadmeImageClassifier {
  ReadmeImageClassifier(this.dio);
  final Dio dio;

  /// Fetch + classify ---------------------------------------------------------
  Future<ReadmeImageResult> load(final String url) async {
    final Response<List<int>> response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final Uint8List bytes = Uint8List.fromList(response.data!);
    final Map<String, List<String>> headers = response.headers.map;

    final bool isSvg = _isSvg(headers, bytes);

    if (isSvg) {
      final String svg = _decodeUtf8(bytes);
      return ReadmeImageResult.svg(svg, bytes);
    }

    // Fallback B: unknown → raster
    return ReadmeImageResult.raster(bytes);
  }

  /// Detection ---------------------------------------------------------------

  bool _isSvg(
    final Map<String, List<String>> headers,
    final Uint8List bytes,
  ) {
    // 1. Content-Type header (strong signal)
    final String? ct = headers['content-type']?.first.toLowerCase();
    if (ct != null) {
      if (ct.contains('image/svg+xml')) {
        return true;
      }

      if (ct.startsWith('image/')) {
        return false;
      }
    }

    // 2. Content sniff (fallback)
    if (_looksLikeSvg(bytes)) {
      return true;
    }

    // 3. Unknown → raster (fallback B)
    return false;
  }

  bool _looksLikeSvg(final Uint8List bytes) {
    final String prefix = _decodeUtf8(bytes, maxChars: 512).trimLeft();

    if (prefix.startsWith('<svg')) return true;
    if (prefix.startsWith('<?xml') && prefix.contains('<svg')) {
      return true;
    }

    return false;
  }

  /// Utils -------------------------------------------------------------------

  String _decodeUtf8(final Uint8List bytes, {final int? maxChars}) {
    final Uint8List slice = (maxChars != null && bytes.length > maxChars)
        ? bytes.sublist(0, maxChars)
        : bytes;

    return utf8.decode(slice, allowMalformed: true);
  }
}
