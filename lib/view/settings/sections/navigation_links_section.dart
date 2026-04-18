import 'package:diohub/app/settings/accessibility.dart';
import 'package:diohub/common/misc/settings_dropdown.dart';
import 'package:diohub/common/misc/settings_group.dart';
import 'package:diohub/common/misc/settings_toggle.dart';
import 'package:diohub/providers/settings/accessibility_provider.dart';
import 'package:diohub/providers/settings/links_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/haptic_feedback.dart';
import 'package:diohub/view/app/startup_flows/flows/link_handling_setup_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation & Links section: haptic feedback, open GitHub in app, confirm before browser.
class NavigationLinksSection extends ConsumerWidget {
  const NavigationLinksSection({super.key});

  static List<SettingsDropdownOption<HapticFeedbackLevel>> get _hapticOptions =>
      <SettingsDropdownOption<HapticFeedbackLevel>>[
        const SettingsDropdownOption<HapticFeedbackLevel>(
          value: HapticFeedbackLevel.on,
          label: 'On',
        ),
        const SettingsDropdownOption<HapticFeedbackLevel>(
          value: HapticFeedbackLevel.reduced,
          label: 'Reduced',
        ),
        const SettingsDropdownOption<HapticFeedbackLevel>(
          value: HapticFeedbackLevel.off,
          label: 'Off',
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(accessibilityProvider);
    final links = ref.watch(linksProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return SettingsGroup(
      children: [
        SettingsDropdown<HapticFeedbackLevel>(
          title: 'Haptic feedback',
          value: accessibility.hapticFeedback,
          options: _hapticOptions,
          onChanged: (HapticFeedbackLevel v) {
            ref
                .read(accessibilityProvider.notifier)
                .update((s) => s.copyWith(hapticFeedback: v));
            maybeHapticLight(v);
          },
          icon: Icons.vibration,
        ),
        SettingsToggle(
          title: 'Open GitHub links in app',
          value: links.openGitHubInApp,
          onChanged: (bool v) => ref
              .read(linksProvider.notifier)
              .update((s) => s.copyWith(openGitHubInApp: v)),
          icon: Icons.open_in_browser,
          subtitle: 'Navigate within DioHub instead of opening browser',
        ),
        SettingsToggle(
          title: 'Confirm before opening browser',
          value: links.confirmBeforeBrowser,
          onChanged: (bool v) => ref
              .read(linksProvider.notifier)
              .update((s) => s.copyWith(confirmBeforeBrowser: v)),
          icon: Icons.warning_amber,
          subtitle: 'Show dialog before launching external URLs',
        ),
        Padding(
          padding: spacing.cardContentPadding,
          child: InkWell(
            onTap: () => LinkHandlingSetupFlow.showSetupSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: spacing.compactSpacing,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.open_in_new,
                    size: 22,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: spacing.compactSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Set up external link handling',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: spacing.tightSpacing),
                        Text(
                          'Open GitHub links directly in DioHub',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
