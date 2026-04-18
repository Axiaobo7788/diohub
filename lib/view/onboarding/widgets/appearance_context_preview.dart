import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/view/onboarding/widgets/onboarding_home_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contextual preview for appearance section: gradient + toolbar pill with current surface style.
/// Live-updates when surface style (glass/blur/solid) changes.
/// Shared by settings appearance section and onboarding step 2.
class AppearanceContextPreview extends ConsumerWidget {
  const AppearanceContextPreview({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppearanceSettings appearance = ref.watch(appearanceProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorScheme.primaryContainer.withValues(alpha: 0.4),
            colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
        ),
      ),
      padding: EdgeInsets.all(context.spacing.itemSpacing),
      child: OnboardingHomePreview(
        toolbarBuilder: CollapsedPillPreview(
          surfaceRendering: appearance.surfaceRendering,
        ),
      ),
    );
  }
}
