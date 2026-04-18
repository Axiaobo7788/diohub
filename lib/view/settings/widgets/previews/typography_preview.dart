import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/providers/settings/flex_theme_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Typography preview: title/body/sample + code line scaled by code font scale.
class TypographyPreview extends ConsumerWidget {
  const TypographyPreview({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final String fontFamily = ref.watch(flexThemeProvider).fontFamily ?? '';
    final double codeFontScale = ref.watch(diffSettingsProvider).codeFontScale;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    final TextStyle titleStyle = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily.isNotEmpty ? fontFamily : null,
    );
    final TextStyle bodyStyle = theme.textTheme.bodyMedium!.copyWith(
      fontFamily: fontFamily.isNotEmpty ? fontFamily : null,
    );
    final TextStyle smallStyle = theme.textTheme.bodySmall!.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontFamily: fontFamily.isNotEmpty ? fontFamily : null,
    );
    final double codeSize =
        (theme.textTheme.bodySmall?.fontSize ?? 12) * codeFontScale;
    final TextStyle codeStyle = theme.textTheme.bodySmall!.copyWith(
      fontFamily: 'monospace',
      fontSize: codeSize,
      color: colorScheme.onSurface,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('The quick brown fox', style: titleStyle),
        SizedBox(height: spacing.tightSpacing),
        Text('jumps over the lazy dog', style: bodyStyle),
        SizedBox(height: spacing.tightSpacing),
        Text('0123456789 !@#\$%', style: smallStyle),
        SizedBox(height: spacing.itemSpacing),
        Text('var x = 42;', style: codeStyle),
      ],
    );
  }
}
