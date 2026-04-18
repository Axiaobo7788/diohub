import 'package:diohub/common/misc/image_color_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for ImageColorSchemeCache (singleton replacement).
final imageColorSchemeCacheProvider = Provider<ImageColorSchemeCache>((ref) {
  return ImageColorSchemeCache();
});
