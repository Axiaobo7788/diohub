import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/app/theme_config/flex_theme_settings_persistence.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';

/// Riverpod provider for FlexColorScheme theme configuration.
///
/// State is [FlexThemeSettingsModel].
final flexThemeProvider = createPersistedProvider(flexThemeDescriptor);
