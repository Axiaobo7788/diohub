import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

const int kMaxReadmeImageBytes = 8 * 1024 * 1024;

enum ReadmeImageKind { svg, raster, unavailable }

final class ReadmeImageSource {
  const ReadmeImageSource({required this.bytes, this.contentType});

  final Uint8List bytes;
  final String? contentType;
}

/// Sendable classification metadata produced away from the UI isolate.
///
/// Raster bytes deliberately stay in [ReadmeImageSource]. Returning them from
/// an isolate would create a second byte buffer for the artifact.
final class ReadmeImageClassification {
  const ReadmeImageClassification.svg(final String svg)
    : kind = ReadmeImageKind.svg,
      svgString = svg;

  const ReadmeImageClassification.raster()
    : kind = ReadmeImageKind.raster,
      svgString = null;

  final ReadmeImageKind kind;
  final String? svgString;
}

final class ReadmeImageResult {
  const ReadmeImageResult._({required this.kind, this.bytes, this.svgString});

  factory ReadmeImageResult.svg(final String svg) =>
      ReadmeImageResult._(kind: ReadmeImageKind.svg, svgString: svg);

  factory ReadmeImageResult.raster(final Uint8List bytes) =>
      ReadmeImageResult._(kind: ReadmeImageKind.raster, bytes: bytes);

  factory ReadmeImageResult.unavailable() =>
      const ReadmeImageResult._(kind: ReadmeImageKind.unavailable);

  final ReadmeImageKind kind;
  final Uint8List? bytes;
  final String? svgString;
}

final class ReadmeImageTooLarge implements Exception {
  const ReadmeImageTooLarge({required this.limitBytes, this.declaredBytes});

  final int limitBytes;
  final int? declaredBytes;

  @override
  String toString() =>
      'README image exceeds $limitBytes bytes'
      '${declaredBytes == null ? '' : ' (declared $declaredBytes)'}';
}

/// Dedicated unauthenticated README asset client.
///
/// It intentionally does not use ApiClient: README image URLs can point at a
/// third-party host and must never inherit a GitHub Authorization header.
class ReadmeImageClassifier {
  ReadmeImageClassifier(this.dio, {this.maxBytes = kMaxReadmeImageBytes})
    : assert(maxBytes > 0, 'README image byte limit must be positive');

  final Dio dio;
  final int maxBytes;

  Future<ReadmeImageSource> fetch(final String url) async {
    final Uri uri = Uri.parse(url);
    if (!uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw FormatException('Unsupported README image URL', url);
    }

    final Response<ResponseBody> response = await dio.get<ResponseBody>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        maxRedirects: 5,
        headers: <String, dynamic>{
          'authorization': null,
          'cookie': null,
          'proxy-authorization': null,
        },
      ),
    );
    final ResponseBody? body = response.data;
    if (body == null) {
      return ReadmeImageSource(
        bytes: Uint8List(0),
        contentType: response.headers.value(Headers.contentTypeHeader),
      );
    }

    final int declaredBytes =
        int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        -1;
    if (declaredBytes > maxBytes) {
      throw ReadmeImageTooLarge(
        limitBytes: maxBytes,
        declaredBytes: declaredBytes,
      );
    }

    final BytesBuilder bytes = BytesBuilder(copy: false);
    int received = 0;
    await for (final Uint8List chunk in body.stream) {
      received += chunk.length;
      if (received > maxBytes) {
        throw ReadmeImageTooLarge(
          limitBytes: maxBytes,
          declaredBytes: declaredBytes < 0 ? null : declaredBytes,
        );
      }
      bytes.add(chunk);
    }
    return ReadmeImageSource(
      bytes: bytes.takeBytes(),
      contentType: response.headers.value(Headers.contentTypeHeader),
    );
  }

  /// Compatibility entry for non-Runtime callers.
  Future<ReadmeImageResult> load(final String url) async {
    final ReadmeImageSource source = await fetch(url);
    return materializeReadmeImageResult(
      source,
      classifyReadmeImageSource(source),
    );
  }
}

/// Sendable top-level transform used by ResourceRuntime's worker isolate.
ReadmeImageClassification classifyReadmeImageSource(
  final ReadmeImageSource source,
) {
  final String? contentType = source.contentType?.toLowerCase();
  final bool isSvg;
  if (contentType?.contains('image/svg+xml') ?? false) {
    isSvg = true;
  } else if (contentType?.startsWith('image/') ?? false) {
    isSvg = false;
  } else {
    isSvg = _looksLikeSvg(source.bytes);
  }

  return isSvg
      ? ReadmeImageClassification.svg(_decodeUtf8(source.bytes))
      : const ReadmeImageClassification.raster();
}

ReadmeImageResult materializeReadmeImageResult(
  final ReadmeImageSource source,
  final ReadmeImageClassification classification,
) => switch (classification.kind) {
  ReadmeImageKind.svg => ReadmeImageResult.svg(classification.svgString!),
  ReadmeImageKind.raster => ReadmeImageResult.raster(source.bytes),
  ReadmeImageKind.unavailable => ReadmeImageResult.unavailable(),
};

bool _looksLikeSvg(final Uint8List bytes) {
  final String prefix = _decodeUtf8(bytes, maxChars: 512).trimLeft();
  return prefix.startsWith('<svg') ||
      (prefix.startsWith('<?xml') && prefix.contains('<svg'));
}

String _decodeUtf8(final Uint8List bytes, {final int? maxChars}) {
  final Uint8List slice = maxChars != null && bytes.length > maxChars
      ? Uint8List.sublistView(bytes, 0, maxChars)
      : bytes;
  return utf8.decode(slice, allowMalformed: true);
}
