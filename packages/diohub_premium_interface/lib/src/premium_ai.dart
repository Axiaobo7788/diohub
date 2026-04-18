import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class PremiumAi {
  const PremiumAi();

  Widget? buildAiSummaryChip(
    BuildContext context,
    WidgetRef ref, {
    required String content,
    String label = 'Summarise',
    String? taskType,
    bool involvesCode = false,
  }) => null;

  Widget? buildComposeAiActions(
    BuildContext context,
    WidgetRef ref, {
    required TextEditingController controller,
    required void Function(String action) onActionSelected,
  }) => null;
}

class DefaultPremiumAi extends PremiumAi {
  const DefaultPremiumAi();
}

final premiumAiProvider = Provider<PremiumAi>((ref) {
  return const DefaultPremiumAi();
});
