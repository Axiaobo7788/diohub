import 'package:diohub/app/settings/settings_descriptor.dart';

/// Error tracking and diagnostics preferences.
/// Controls what data is sent to Sentry for crash reporting and monitoring.
class ErrorTrackingSettings {
  const ErrorTrackingSettings({
    this.crashReports = true,
    this.httpMetadata = true,
    this.navigationTracking = true,
    this.performanceTracing = true,
    this.sessionReplay = false,
  });

  /// Named constructor for enterprise/GHES accounts: minimal tracking (only crashes).
  const ErrorTrackingSettings.enterprise()
      : crashReports = true,
        httpMetadata = false,
        navigationTracking = false,
        performanceTracing = false,
        sessionReplay = false;

  factory ErrorTrackingSettings.fromJson(final Map<String, dynamic> json) =>
      ErrorTrackingSettings(
        crashReports: json['crashReports'] as bool? ?? true,
        httpMetadata: json['httpMetadata'] as bool? ?? true,
        navigationTracking: json['navigationTracking'] as bool? ?? true,
        performanceTracing: json['performanceTracing'] as bool? ?? true,
        sessionReplay: json['sessionReplay'] as bool? ?? false,
      );

  /// Send anonymous crash reports with stack traces.
  /// Master switch: when off, Sentry is fully disabled.
  final bool crashReports;

  /// Include HTTP error patterns and timing.
  /// Repository names are anonymized.
  final bool httpMetadata;

  /// Include which screens were visited before a crash.
  final bool navigationTracking;

  /// Measure app speed and responsiveness.
  final bool performanceTracing;

  /// Record screen on crashes (all text/images masked).
  final bool sessionReplay;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'crashReports': crashReports,
        'httpMetadata': httpMetadata,
        'navigationTracking': navigationTracking,
        'performanceTracing': performanceTracing,
        'sessionReplay': sessionReplay,
      };

  ErrorTrackingSettings copyWith({
    final bool? crashReports,
    final bool? httpMetadata,
    final bool? navigationTracking,
    final bool? performanceTracing,
    final bool? sessionReplay,
  }) =>
      ErrorTrackingSettings(
        crashReports: crashReports ?? this.crashReports,
        httpMetadata: httpMetadata ?? this.httpMetadata,
        navigationTracking: navigationTracking ?? this.navigationTracking,
        performanceTracing: performanceTracing ?? this.performanceTracing,
        sessionReplay: sessionReplay ?? this.sessionReplay,
      );
}

Map<String, dynamic> _errorTrackingToJson(final ErrorTrackingSettings v) =>
    v.toJson();

const SettingsDescriptor<ErrorTrackingSettings> errorTrackingDescriptor =
    SettingsDescriptor<ErrorTrackingSettings>(
  key: 'app_error_tracking',
  defaultValue: ErrorTrackingSettings(),
  fromJson: ErrorTrackingSettings.fromJson,
  toJson: _errorTrackingToJson,
);
