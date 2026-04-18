import 'package:diohub/app/settings/layout.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:diohub/providers/settings/spacing_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<LayoutNotifier, LayoutSettings> layoutProvider =
    NotifierProvider<LayoutNotifier, LayoutSettings>(LayoutNotifier.new);

class LayoutNotifier extends Notifier<LayoutSettings>
    with PersistedNotifier<LayoutSettings> {
  @override
  SettingsDescriptor<LayoutSettings> get descriptor => layoutDescriptor;

  Future<void> updateDensity(final LayoutDensity value) async {
    await update((final LayoutSettings s) => s.copyWith(density: value));
    await ref.read(spacingProvider.notifier).applyPreset(value);
  }

  Future<void> updateStickyHeaders(final bool value) async {
    await update((final LayoutSettings s) => s.copyWith(stickyHeaders: value));
  }

  @override
  Future<void> reset() async {
    await super.reset();
    await ref.read(spacingProvider.notifier).applyPreset(state.density);
  }
}
