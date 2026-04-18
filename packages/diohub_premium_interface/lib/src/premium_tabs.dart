import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub_models/models/entity_ref.dart';

typedef PremiumTabBuilder =
    Widget Function(BuildContext context, WidgetRef ref);

class PremiumTabDefinition {
  const PremiumTabDefinition({
    required this.label,
    required this.icon,
    required this.body,
    this.deeplinkPath,
    this.keepAlive = false,
  });

  final String label;
  final IconData icon;
  final Widget body;
  final String? deeplinkPath;
  final bool keepAlive;
}

abstract class PremiumTabs {
  const PremiumTabs();

  List<PremiumTabDefinition> repoContentTabs(
    BuildContext context,
    WidgetRef ref, {
    required RepoRef repoRef,
    required dynamic repo,
  }) => const [];

  List<PremiumTabDefinition> repoManagementTabs(
    BuildContext context,
    WidgetRef ref, {
    required RepoRef repoRef,
    required dynamic repo,
  }) => const [];

  List<PremiumTabDefinition> pullRequestTabs(
    BuildContext context,
    WidgetRef ref, {
    required dynamic pullRef,
    required dynamic data,
  }) => const [];

  Widget? downloadBadge(
    BuildContext context,
    WidgetRef ref, {
    required dynamic repoRef,
  }) => null;

  /// Returns a builder for the review thread reply screen, given a [pullRef],
  /// [threadId], and optional [filePath]. Returns `null` in the OSS build,
  /// which disables the tap target on thread cards.
  Widget Function(PullRequestRef pullRef, String threadId, String? filePath)?
  reviewThreadScreenBuilder(BuildContext context, WidgetRef ref) => null;
}

class DefaultPremiumTabs extends PremiumTabs {
  const DefaultPremiumTabs();
}

final premiumTabsProvider = Provider<PremiumTabs>((ref) {
  return const DefaultPremiumTabs();
});
