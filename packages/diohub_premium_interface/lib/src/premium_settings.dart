import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumSettingsEntry {
  const PremiumSettingsEntry({required this.group, required this.widget});

  final String group;
  final Widget widget;
}

abstract class PremiumSettings {
  const PremiumSettings();

  List<Widget> settingsSections(BuildContext context, WidgetRef ref) =>
      const [];

  List<PremiumSettingsEntry> entitySettings(
    BuildContext context,
    WidgetRef ref,
    String entityType,
  ) => const [];
}

class DefaultPremiumSettings extends PremiumSettings {
  const DefaultPremiumSettings();
}

final premiumSettingsProvider = Provider<PremiumSettings>((ref) {
  return const DefaultPremiumSettings();
});
