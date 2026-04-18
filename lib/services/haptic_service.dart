import 'package:diohub/app/settings/accessibility.dart';
import 'package:flutter/cupertino.dart' show BuildContext;
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show BuildContext;

/// Central haptic feedback that respects a haptic level (e.g. from accessibility settings).
/// When [HapticFeedbackLevel.off], no feedback. When [HapticFeedbackLevel.reduced],
/// uses [HapticFeedback.selectionClick]. When [HapticFeedbackLevel.on], uses the
/// requested impact.
///
/// Obtain via [hapticServiceProvider] from package:diohub/providers/haptic_service_provider.dart;
/// use from widgets with [Ref] or [ProviderScope.containerOf](context).read(hapticServiceProvider) when only
/// [BuildContext] is available.
class HapticService {
  HapticService(this._getLevel);

  final HapticFeedbackLevel Function() _getLevel;

  HapticFeedbackLevel get _level => _getLevel();

  Future<void> lightImpact() async {
    if (_level == HapticFeedbackLevel.off) return;
    if (_level == HapticFeedbackLevel.reduced) {
      HapticFeedback.selectionClick();
      return;
    }
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    if (_level == HapticFeedbackLevel.off) return;
    if (_level == HapticFeedbackLevel.reduced) {
      HapticFeedback.selectionClick();
      return;
    }
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    if (_level == HapticFeedbackLevel.off) return;
    if (_level == HapticFeedbackLevel.reduced) {
      HapticFeedback.selectionClick();
      return;
    }
    await HapticFeedback.heavyImpact();
  }

  void selectionClick() {
    if (_level == HapticFeedbackLevel.off) return;
    HapticFeedback.selectionClick();
  }

  /// For chip dismiss / clear actions. Uses medium impact and respects settings.
  /// Prefer this over raw [HapticFeedback.vibrate].
  Future<void> chipDismiss() => mediumImpact();
}
