import 'package:diohub/app/settings/tab_behavior.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final NotifierProvider<TabBehaviorNotifier, TabBehaviorSettings>
    tabBehaviorProvider =
    NotifierProvider<TabBehaviorNotifier, TabBehaviorSettings>(
  TabBehaviorNotifier.new,
);

class TabBehaviorNotifier extends Notifier<TabBehaviorSettings>
    with PersistedNotifier<TabBehaviorSettings> {
  @override
  SettingsDescriptor<TabBehaviorSettings> get descriptor =>
      tabBehaviorDescriptor;

  Future<void> togglePin(final ScreenTabType screen, final String tabId) async {
    final Set<String> current =
        Set<String>.from(state.pinnedTabs[screen] ?? <String>{});
    if (current.contains(tabId)) {
      current.remove(tabId);
    } else {
      current.add(tabId);
    }
    final Map<ScreenTabType, Set<String>> next =
        Map<ScreenTabType, Set<String>>.from(state.pinnedTabs)
          ..[screen] = current;
    await update((final TabBehaviorSettings s) => s.copyWith(pinnedTabs: next));
  }

  Future<void> updateCollapsedVisible(
    final ScreenTabType screen,
    final String tabId,
    final bool visible,
  ) async {
    final Set<String> current = Set<String>.from(
      state.collapsedVisibleOverrides[screen] ?? <String>{},
    );
    if (visible) {
      current.add(tabId);
    } else {
      current.remove(tabId);
    }
    final Map<ScreenTabType, Set<String>> next =
        Map<ScreenTabType, Set<String>>.from(state.collapsedVisibleOverrides)
          ..[screen] = current;
    await update((final TabBehaviorSettings s) =>
        s.copyWith(collapsedVisibleOverrides: next));
  }

  Future<void> resetScreen(final ScreenTabType screen) async {
    final Map<ScreenTabType, Set<String>> pinned =
        Map<ScreenTabType, Set<String>>.from(state.pinnedTabs)..remove(screen);
    final Map<ScreenTabType, Set<String>> collapsed =
        Map<ScreenTabType, Set<String>>.from(state.collapsedVisibleOverrides)
          ..remove(screen);
    await update((final TabBehaviorSettings s) => s.copyWith(
          pinnedTabs: pinned,
          collapsedVisibleOverrides: collapsed,
        ));
  }
}
