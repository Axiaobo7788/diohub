import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/app/settings/settings_descriptors.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';

/// Riverpod provider for glass pill theme settings.
///
/// State is [GlassPillSettings]; theme build uses
/// [GlassPillSettings.toGlassPillTheme] and [GlassPillSettings.scaleRadii].
final glassPillProvider = createPersistedProvider<GlassPillSettings>(glassPillDescriptor);
