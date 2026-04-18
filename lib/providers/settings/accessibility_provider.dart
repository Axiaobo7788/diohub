import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/app/settings/settings_descriptors.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';

final accessibilityProvider = createPersistedProvider<AccessibilitySettings>(accessibilityDescriptor);

