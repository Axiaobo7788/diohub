import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/common/bottom_sheet/confirm_action_sheet.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/settings/accessibility_provider.dart';
import 'package:diohub/providers/settings/card_display_provider.dart';
import 'package:diohub/providers/settings/diff_settings_provider.dart';
import 'package:diohub/providers/settings/events_provider.dart';
import 'package:diohub/providers/settings/layout_provider.dart';
import 'package:diohub/providers/settings/links_provider.dart';
import 'package:diohub/providers/settings/repository_provider.dart';
import 'package:diohub/providers/settings/tab_behavior_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flows_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reset Preferences section: reset preferences, clear image cache, clear API cache.
class ResetPreferencesSection extends ConsumerWidget {
  const ResetPreferencesSection({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AppSpacing spacing = context.spacing;

    return Padding(
      padding: spacing.sectionTitlePaddingLarge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: () => _showResetDialog(context, ref),
            icon: const Icon(Icons.restore),
            label: const Text('Reset preferences'),
          ),
          SizedBox(height: spacing.itemSpacing),
          OutlinedButton.icon(
            onPressed: () => _clearImageCache(context, ref),
            icon: const Icon(Icons.image_not_supported_outlined),
            label: const Text('Clear image cache'),
          ),
          SizedBox(height: spacing.itemSpacing),
          OutlinedButton.icon(
            onPressed: () => _clearAPICache(context, ref),
            icon: const Icon(Icons.cloud_off_outlined),
            label: const Text('Clear API cache'),
          ),
          if (kDebugMode || kProfileMode) ...<Widget>[
            SizedBox(height: spacing.itemSpacing),
            OutlinedButton.icon(
              onPressed: () => _resetStartupFlowHistory(context, ref),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset startup flow history'),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _resetStartupFlowHistory(
    final BuildContext context,
    final WidgetRef ref,
  ) async {
    await ref.read(startupFlowsProvider.notifier).reset();
    if (context.mounted) {
      ref
          .read(notificationServiceProvider)
          .success('Startup flow history cleared');
    }
  }

  static void _clearImageCache(
      final BuildContext context, final WidgetRef ref) {
    PaintingBinding.instance.imageCache.clear();
    if (context.mounted) {
      ref.read(notificationServiceProvider).success('Image cache cleared');
    }
  }

  static Future<void> _clearAPICache(
      final BuildContext context, final WidgetRef ref) async {
    await BaseAPIHandler.clearCache();
    if (context.mounted) {
      ref.read(notificationServiceProvider).success('API cache cleared');
    }
  }

  Future<void> _showResetDialog(
      final BuildContext context, final WidgetRef ref) async {
    final bool? confirmed = await showConfirmAction(
      context,
      title: 'Reset preferences?',
      explanation:
          'This will reset layout, card display, diff, behavior, defaults, and tab pins.',
      confirmLabel: 'Reset',
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(layoutProvider.notifier).reset();
    await ref.read(cardDisplayProvider.notifier).reset();
    await ref.read(diffSettingsProvider.notifier).reset();
    await ref.read(eventsProvider.notifier).reset();
    await ref.read(accessibilityProvider.notifier).reset();
    await ref.read(linksProvider.notifier).reset();
    await ref.read(repositoryProvider.notifier).reset();
    await ref.read(tabBehaviorProvider.notifier).reset();

    if (!context.mounted) return;
    ref.read(notificationServiceProvider).success(
          'Preferences reset to defaults',
        );
  }
}
