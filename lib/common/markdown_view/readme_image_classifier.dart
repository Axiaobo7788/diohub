import 'dart:typed_data';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum ReadmeImageKind { svg, raster }

class ReadmeImageResult {
  final ReadmeImageKind kind;
  final Uint8List bytes;
  final String? svgString;

  const ReadmeImageResult._({
    required this.kind,
    required this.bytes,
    this.svgString,
  });

  factory ReadmeImageResult.svg(String svg, Uint8List bytes) {
    return ReadmeImageResult._(
      kind: ReadmeImageKind.svg,
      bytes: bytes,
      svgString: svg,
    );
  }

  factory ReadmeImageResult.raster(Uint8List bytes) {
    return ReadmeImageResult._(
      kind: ReadmeImageKind.raster,
      bytes: bytes,
    );
  }
}

class ReadmeImageClassifier {
  final Dio dio;

  ReadmeImageClassifier(this.dio);

  /// Fetch + classify ---------------------------------------------------------
  Future<ReadmeImageResult> load(String url) async {
    final response = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = Uint8List.fromList(response.data!);
    final headers = response.headers.map;

    final isSvg = _isSvg(headers, bytes);

    if (isSvg) {
      final svg = _decodeUtf8(bytes);
      return ReadmeImageResult.svg(svg, bytes);
    }

    // Fallback B: unknown → raster
    return ReadmeImageResult.raster(bytes);
  }

  /// Detection ---------------------------------------------------------------

  bool _isSvg(
    Map<String, List<String>> headers,
    Uint8List bytes,
  ) {
    // 1. Content-Type header (strong signal)
    final ct = headers['content-type']?.first.toLowerCase();
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

  bool _looksLikeSvg(Uint8List bytes) {
    final prefix = _decodeUtf8(bytes, maxChars: 512).trimLeft();

    if (prefix.startsWith('<svg')) return true;
    if (prefix.startsWith('<?xml') && prefix.contains('<svg')) {
      return true;
    }

    return false;
  }

  /// Utils -------------------------------------------------------------------

  String _decodeUtf8(Uint8List bytes, {int? maxChars}) {
    final slice =
        (maxChars != null && bytes.length > maxChars)
            ? bytes.sublist(0, maxChars)
            : bytes;

    return utf8.decode(slice, allowMalformed: true);
  }
}

