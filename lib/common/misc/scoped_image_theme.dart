import 'package:diohub/app/app_logger.dart';
import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/common/misc/image_color_cache.dart';
import 'package:diohub/providers/services_provider.dart';
import 'package:diohub/providers/settings/theme_mode_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps its [child] in a [Theme] whose [ColorScheme] is subtly tinted
/// by the dominant color extracted from [imageUrl].
///
/// Reads [themeModeProvider] to honour the user's enable/disable toggle
/// and intensity preference. When disabled, passes [child] through with
/// the base theme so the widget tree depth stays stable (preventing
/// child State destruction from tree structure changes).
class ScopedImageTheme extends ConsumerStatefulWidget {
  const ScopedImageTheme({
    required this.imageUrl,
    required this.child,
    super.key,
  });

  /// The network image URL to extract a seed color from. May be `null`.
  final String? imageUrl;

  /// The subtree that will receive the tinted theme.
  final Widget child;

  @override
  ConsumerState<ScopedImageTheme> createState() => _ScopedImageThemeState();
}

class _ScopedImageThemeState extends ConsumerState<ScopedImageTheme> {
  Color? _seedColor;

  @override
  void initState() {
    super.initState();
    // _extractSeed() is intentionally NOT called here because it uses
    // Theme.of(context) which depends on an InheritedWidget.
    // didChangeDependencies() is called right after initState and handles it.
  }

  @override
  void didUpdateWidget(final ScopedImageTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractSeedIfEnabled();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-extract when brightness changes (light / dark).
    _extractSeedIfEnabled();
  }

  /// Only kicks off extraction when the feature is enabled.
  void _extractSeedIfEnabled() {
    if (!ref.read(themeModeProvider).scopedProfileThemeEnabled) return;
    _extractSeed();
  }

  Future<void> _extractSeed() async {
    final String? url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[ScopedImageTheme] _extractSeed: url is null/empty, skipping',
        );
      }
      return;
    }

    final Brightness brightness = Theme.of(context).brightness;
    if (kDebugMode) {
      debugPrint(
        '[ScopedImageTheme] _extractSeed: extracting from $url (brightness=$brightness)',
      );
    }

    try {
      final cache = ref.read(imageColorSchemeCacheProvider);
      final Color seed = await cache.getOrExtract(url, brightness);
      if (kDebugMode) {
        debugPrint(
          '[ScopedImageTheme] _extractSeed: got seed=$seed, mounted=$mounted, changed=${seed != _seedColor}',
        );
      }
      if (mounted && seed != _seedColor) {
        setState(() => _seedColor = seed);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[ScopedImageTheme] _extractSeed: FAILED with $e');
      }
      AppLogger.warning(
        'ScopedImageTheme: failed to extract seed color from $url',
        error: e,
        stackTrace: stackTrace,
        tag: 'ScopedImageTheme',
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    final bool enabled = ref.watch(
      themeModeProvider
          .select((final ThemeSettings s) => s.scopedProfileThemeEnabled),
    );

    // When disabled, pass through the child directly — no extraction,
    // no AnimatedTheme overhead.
    if (!enabled) return widget.child;

    // If just re-enabled and we haven't extracted yet, kick it off.
    if (_seedColor == null) _extractSeed();

    final double intensity = ref.watch(
      themeModeProvider
          .select((final ThemeSettings s) => s.scopedThemeIntensity),
    );

    final ThemeData base = Theme.of(context);

    // If seed hasn't been extracted yet, trigger it and use the base theme
    // meanwhile. AnimatedTheme keeps the tree depth stable so child State
    // is preserved when _seedColor transitions from null to a value.
    if (_seedColor == null) {
      return AnimatedTheme(
        data: base,
        duration: const Duration(milliseconds: 600),
        child: widget.child,
      );
    }

    // Blend the base primary toward the image seed.
    final Color blendedSeed =
        Color.lerp(base.colorScheme.primary, _seedColor, intensity)!;

    // Regenerate a full harmonious scheme from the blended seed.
    final ColorScheme scopedScheme = ColorScheme.fromSeed(
      seedColor: blendedSeed,
      brightness: base.brightness,
    );

    // copyWith preserves ThemeExtensions (SurfaceStyle, GlassPillTheme, etc.)
    return AnimatedTheme(
      data: base.copyWith(colorScheme: scopedScheme),
      duration: const Duration(milliseconds: 600),
      child: widget.child,
    );
  }
}
