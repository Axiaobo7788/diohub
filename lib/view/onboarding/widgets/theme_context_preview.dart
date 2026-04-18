import 'package:diohub/view/onboarding/widgets/onboarding_home_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contextual preview for theme section: toolbar pill + placeholder repo card.
/// Live-updates when theme mode, scheme, or true black change (via context theme).
/// Shared by settings theme section and onboarding step 1.
class ThemeContextPreview extends ConsumerWidget {
  const ThemeContextPreview({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) =>
      const OnboardingHomePreview(
        toolbarBuilder: CollapsedPillPreview(),
      );
}
