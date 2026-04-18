import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/providers/settings/error_tracking_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Privacy & Diagnostics section: granular opt-out controls for error tracking.
class PrivacyDiagnosticsSection extends ConsumerWidget {
  const PrivacyDiagnosticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(errorTrackingProvider);
    final notifier = ref.read(errorTrackingProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsGroup(
          children: [
            SettingsToggle(
              title: 'Crash reports',
              subtitle:
                  'Send anonymous crash reports with stack traces. No personal data included.',
              value: settings.crashReports,
              onChanged: (bool v) =>
                  notifier.update((s) => s.copyWith(crashReports: v)),
              icon: Icons.bug_report_outlined,
            ),
            SettingsToggle(
              title: 'HTTP diagnostics',
              subtitle:
                  'Include API error patterns and timing. Repository names are anonymized.',
              value: settings.httpMetadata,
              onChanged: (bool v) =>
                  notifier.update((s) => s.copyWith(httpMetadata: v)),
              icon: Icons.http_outlined,
            ),
            SettingsToggle(
              title: 'Navigation tracking',
              subtitle: 'Include which screens were visited before a crash.',
              value: settings.navigationTracking,
              onChanged: (bool v) =>
                  notifier.update((s) => s.copyWith(navigationTracking: v)),
              icon: Icons.explore_outlined,
            ),
            SettingsToggle(
              title: 'Performance monitoring',
              subtitle: 'Measure app speed and responsiveness.',
              value: settings.performanceTracing,
              onChanged: (bool v) =>
                  notifier.update((s) => s.copyWith(performanceTracing: v)),
              icon: Icons.speed_outlined,
            ),
            SettingsToggle(
              title: 'Session replay',
              subtitle:
                  'Record screen on crashes. All text and images are masked.',
              value: settings.sessionReplay,
              onChanged: (bool v) =>
                  notifier.update((s) => s.copyWith(sessionReplay: v)),
              icon: Icons.video_camera_back_outlined,
            ),
          ],
        ),
        Padding(
          padding: context.spacing.cardContentPadding,
          child: Text(
            'Changes take effect on next app launch',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
      ],
    );
  }
}
