import 'package:diohub/app/settings/settings_descriptor.dart';
import 'package:diohub/common/riverpod/persisted_notifier.dart';

/// Persisted onboarding state. One-time first-launch flow.
class OnboardingData {
  const OnboardingData({this.completed = false});

  factory OnboardingData.fromJson(final Map<String, dynamic> json) =>
      OnboardingData(
        completed: json['completed'] as bool? ?? false,
      );

  final bool completed;

  Map<String, dynamic> toJson() => <String, dynamic>{'completed': completed};

  OnboardingData copyWith({final bool? completed}) =>
      OnboardingData(completed: completed ?? this.completed);
}

Map<String, dynamic> _onboardingToJson(final OnboardingData v) => v.toJson();

const SettingsDescriptor<OnboardingData> onboardingDescriptor =
    SettingsDescriptor<OnboardingData>(
  key: 'app_onboarding_completed',
  defaultValue: OnboardingData(),
  fromJson: OnboardingData.fromJson,
  toJson: _onboardingToJson,
);

final onboardingProvider = createPersistedProvider(onboardingDescriptor);

