import 'package:diohub/providers/haptic_service_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact chip showing a color scheme (gradient strip + label). Reusable in onboarding and Settings.
class SchemeChip extends StatelessWidget {
  const SchemeChip({
    required this.scheme,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.blendLevel = 10,
    this.label,
  });

  final FlexScheme scheme;
  final bool isSelected;
  final VoidCallback onTap;
  final int blendLevel;
  final String? label;

  static String getFlexSchemeLabel(final FlexScheme scheme) => scheme.name
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (final Match match) => ' ${match.group(1)}',
      )
      .trim();

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final FlexColorScheme previewScheme = FlexColorScheme.light(
      scheme: scheme,
      blendLevel: blendLevel,
    );
    final ColorScheme previewColors = previewScheme.toScheme;
    final String displayLabel = label ?? getFlexSchemeLabel(scheme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ProviderScope.containerOf(context)
              .read(hapticServiceProvider)
              .selectionClick();
          onTap();
        },
        borderRadius: context.radius(RadiusSize.medium),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: context.radius(RadiusSize.medium),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.6)
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      previewColors.primary,
                      previewColors.primaryContainer,
                      previewColors.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const <double>[0, 0.5, 1],
                  ),
                  borderRadius: context.radius(RadiusSize.small),
                ),
                child: isSelected
                    ? Stack(
                        alignment: Alignment.topRight,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.check_rounded,
                              color: colorScheme.primary,
                              size: 14,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
              context.spacing.compactGap,
              Text(
                displayLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
