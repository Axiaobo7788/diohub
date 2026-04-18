import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub_models/models/entity_ref.dart';

abstract class PremiumCapabilities {
  const PremiumCapabilities();

  List<dynamic> issueCapabilities({
    required BuildContext context,
    required WidgetRef ref,
    required IssueRef issueRef,
    required dynamic data,
  }) => const [];

  List<dynamic> pullCapabilities({
    required BuildContext context,
    required WidgetRef ref,
    required PullRequestRef pullRef,
    required dynamic data,
  }) => const [];

  List<dynamic> repoCapabilities({
    required BuildContext context,
    required WidgetRef ref,
    required RepoRef repoRef,
    required dynamic data,
  }) => const [];
}

class DefaultPremiumCapabilities extends PremiumCapabilities {
  const DefaultPremiumCapabilities();
}

final premiumCapabilitiesProvider = Provider<PremiumCapabilities>((ref) {
  return const DefaultPremiumCapabilities();
});
