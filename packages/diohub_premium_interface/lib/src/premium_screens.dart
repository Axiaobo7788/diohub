import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/commits/diff_side.dart';

abstract class PremiumScreens {
  const PremiumScreens();

  Widget? buildMergeSheet(BuildContext context, WidgetRef ref) => null;

  Widget? buildAccountSwitcher(BuildContext context, WidgetRef ref) => null;

  Widget? downloadDockPill(BuildContext context, WidgetRef ref) => null;

  Widget? downloadStateIndicator(
    BuildContext context,
    WidgetRef ref, {
    required dynamic target,
  }) => null;

  Widget? downloadSettingsSection(BuildContext context, WidgetRef ref) => null;

  Widget? downloadBannerSliver(BuildContext context, WidgetRef ref) => null;

  Widget? buildRevertSheet({
    required BuildContext context,
    required WidgetRef ref,
    required String pullRequestId,
    required PullRequestRef pullRef,
    required String defaultTitle,
  }) => null;

  Widget? buildInlineCommentSheet({
    required BuildContext context,
    required WidgetRef ref,
    required PullRequestRef pullRef,
    required String pullRequestId,
    required String path,
    required int line,
    required DiffSide side,
  }) => null;

  /// Returns a callback that shows the dashboard customize sheet.
  /// Returns null in the OSS build — the customize action is not available.
  Future<void> Function(BuildContext context, WidgetRef ref)?
  showDashboardCustomizeSheet() => null;
}

class DefaultPremiumScreens extends PremiumScreens {
  const DefaultPremiumScreens();
}

final premiumScreensProvider = Provider<PremiumScreens>((ref) {
  return const DefaultPremiumScreens();
});
