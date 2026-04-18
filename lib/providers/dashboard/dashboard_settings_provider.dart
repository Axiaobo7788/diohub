import 'package:diohub/app/settings/dashboard_settings.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardSettingsProvider =
    NotifierProvider<DashboardSettingsNotifier, DashboardSettings>(
  DashboardSettingsNotifier.new,
);

class DashboardSettingsNotifier extends Notifier<DashboardSettings>
    with PersistedNotifier<DashboardSettings> {
  @override
  SettingsDescriptor<DashboardSettings> get descriptor => dashboardDescriptor;

  Future<void> toggleSection(DashboardSectionId id) async {
    await update((current) {
      final currentConfig = current.configFor(id);
      final newConfig = currentConfig.copyWith(visible: !currentConfig.visible);
      return current.copyWith(
        sections: {...current.sections, id: newConfig},
      );
    });
  }

  Future<void> setSectionLimit(DashboardSectionId id, int limit) async {
    await update((current) {
      final currentConfig = current.configFor(id);
      final newConfig = currentConfig.copyWith(limit: limit);
      return current.copyWith(
        sections: {...current.sections, id: newConfig},
      );
    });
  }

  Future<void> reorder(List<DashboardSectionId> newOrder) async {
    await update((current) => current.copyWith(sectionOrder: newOrder));
  }

  Future<void> resetToDefaults() => reset();
}
