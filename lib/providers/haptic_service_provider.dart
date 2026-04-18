import 'package:diohub/app/settings/accessibility.dart';
import 'package:diohub/providers/settings/accessibility_provider.dart';
import 'package:diohub/services/haptic_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:diohub/services/haptic_service.dart' show HapticService;

final Provider<HapticService> hapticServiceProvider =
    Provider<HapticService>((ref) => HapticService(
          () => ref.read(accessibilityProvider).hapticFeedback,
        ));
