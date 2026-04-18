import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/providers/settings/onboarding_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flows_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flow.dart';
import 'package:diohub/view/home/widgets/startup_flow_banners.dart';
import 'package:diohub/view/onboarding/onboarding_overlay.dart';

/// Prompted flow: dismissible banner that opens the onboarding overlay.
class OnboardingFlow extends StartupFlow {
  @override
  String get id => 'onboarding';

  @override
  int get priority => 10;

  @override
  FlowTier get tier => FlowTier.prompted;

  @override
  Future<bool> shouldShow(final ProviderContainer container) async {
    if (container.read(onboardingProvider).completed) return false;
    if (container.read(startupFlowsProvider).dismissedFlows.contains('onboarding')) {
      return false;
    }
    return true;
  }

  @override
  Widget? buildBanner(
    final BuildContext context, {
    required final VoidCallback onDismiss,
    required final VoidCallback onAction,
  }) {
    return StartupFlowBannerCard(
      icon: Icons.auto_awesome,
      title: 'Customize your experience',
      subtitle: 'Set up themes, appearance, and more',
      actionLabel: "Let's go",
      dismissLabel: 'Later',
      onAction: onAction,
      onDismiss: onDismiss,
    );
  }

  @override
  Future<void> markHandled(final ProviderContainer container) async {
    await container.read(startupFlowsProvider.notifier).dismissFlow('onboarding');
  }
}
