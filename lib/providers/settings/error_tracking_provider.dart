import 'package:diohub/app/settings/error_tracking.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Error tracking and diagnostics settings provider with enterprise-aware defaults.
///
/// For github.com accounts: all tracking enabled (except session replay).
/// For GHES/enterprise accounts: only crash reports enabled.
final errorTrackingProvider =
    NotifierProvider<ErrorTrackingNotifier, ErrorTrackingSettings>(
  ErrorTrackingNotifier.new,
);

class ErrorTrackingNotifier extends Notifier<ErrorTrackingSettings>
    with PersistedNotifier<ErrorTrackingSettings> {
  @override
  SettingsDescriptor<ErrorTrackingSettings> get descriptor =>
      errorTrackingDescriptor;

  @override
  ErrorTrackingSettings build() {
    final cache = ref.read(settingsCacheProvider);
    
    // Check if user has explicitly set preferences
    if (cache.containsKey(descriptor.key)) {
      return cache.read(descriptor);
    }

    // Otherwise, check if active account is enterprise and use appropriate default
    final accountState = ref.read(accountProvider);
    if (accountState.hasValue) {
      final session = accountState.value;
      if (session != null) {
        final serverConfig = session.activeAccountModel?.serverConfig;
        // If enterprise (not github.com), use minimal tracking
        if (serverConfig != null && !serverConfig.isDefault) {
          return const ErrorTrackingSettings.enterprise();
        }
      }
    }

    // Default: github.com preset (all on except replay)
    return descriptor.defaultValue;
  }
}
