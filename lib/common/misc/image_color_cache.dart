import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Cache for seed colors extracted from profile images.
///
/// Keys are composed of the image URL and brightness to avoid
/// re-extracting when navigating back to the same profile.
class ImageColorSchemeCache {
  ImageColorSchemeCache();

  final Map<String, Color> _cache = <String, Color>{};

  String _key(final String url, final Brightness brightness) =>
      '$url|${brightness.name}';

  /// Returns a previously cached seed color, or `null`.
  Color? get(final String url, final Brightness brightness) =>
      _cache[_key(url, brightness)];

  /// Stores a seed color in the cache.
  void put(final String url, final Brightness brightness,
          final Color seedColor) =>
      _cache[_key(url, brightness)] = seedColor;

  /// Returns the cached seed color or extracts one from [url].
  ///
  /// Uses [ColorScheme.fromImageProvider] with a [CachedNetworkImageProvider]
  /// and stores the resulting `primary` color as the seed.
  Future<Color> getOrExtract(
      final String url, final Brightness brightness) async {
    final Color? cached = get(url, brightness);
    if (cached != null) return cached;

    final ColorScheme scheme = await ColorScheme.fromImageProvider(
      provider: CachedNetworkImageProvider(url),
      brightness: brightness,
    );

    final Color seed = scheme.primary;
    put(url, brightness, seed);
    return seed;
  }
}
