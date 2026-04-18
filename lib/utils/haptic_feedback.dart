import 'package:diohub/app/settings/accessibility.dart';
import 'package:flutter/services.dart';

/// Applies haptic feedback respecting [HapticFeedbackLevel].
/// When [HapticFeedbackLevel.off], no feedback. When [HapticFeedbackLevel.reduced],
/// uses [HapticFeedback.selectionClick]. When [HapticFeedbackLevel.on], uses the
/// requested impact.
///
/// Callers pass the value from settings, e.g.
/// `maybeHapticLight(ref.read(accessibilityProvider).hapticFeedback)`.
Future<void> maybeHapticLight(final HapticFeedbackLevel level) async {
  if (level == HapticFeedbackLevel.off) return;
  if (level == HapticFeedbackLevel.reduced) {
    HapticFeedback.selectionClick();
    return;
  }
  await HapticFeedback.lightImpact();
}

Future<void> maybeHapticMedium(final HapticFeedbackLevel level) async {
  if (level == HapticFeedbackLevel.off) return;
  if (level == HapticFeedbackLevel.reduced) {
    HapticFeedback.selectionClick();
    return;
  }
  await HapticFeedback.mediumImpact();
}

Future<void> maybeHapticHeavy(final HapticFeedbackLevel level) async {
  if (level == HapticFeedbackLevel.off) return;
  if (level == HapticFeedbackLevel.reduced) {
    HapticFeedback.selectionClick();
    return;
  }
  await HapticFeedback.heavyImpact();
}

void maybeHapticSelection(final HapticFeedbackLevel level) {
  if (level == HapticFeedbackLevel.off) return;
  HapticFeedback.selectionClick();
}
