import 'package:diohub/app/settings/layout.dart';
import 'package:diohub/app/settings/spacing.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for spacing/layout settings.
///
/// State is [SpacingSettings]; theme build uses [SpacingSettings.toAppSpacing].
final NotifierProvider<SpacingNotifier, SpacingSettings> spacingProvider =
    NotifierProvider<SpacingNotifier, SpacingSettings>(
  SpacingNotifier.new,
);

class SpacingNotifier extends Notifier<SpacingSettings>
    with PersistedNotifier<SpacingSettings> {
  @override
  SettingsDescriptor<SpacingSettings> get descriptor => spacingDescriptor;

  /// Apply a density preset (compact / default / spacious) and persist.
  Future<void> applyPreset(final LayoutDensity density) async {
    await update((final SpacingSettings _) => switch (density) {
          LayoutDensity.compact => SpacingSettings.compact(),
          LayoutDensity.default_ => const SpacingSettings(),
          LayoutDensity.spacious => SpacingSettings.spacious(),
        });
  }
}
