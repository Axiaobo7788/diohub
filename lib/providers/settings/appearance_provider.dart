import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';

/// Riverpod provider for appearance and performance settings.
///
/// State is [AppearanceSettings].
final appearanceProvider = createPersistedProvider(appearanceDescriptor);

