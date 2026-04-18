import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/providers/startup_flows/startup_flows_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flow.dart';
import 'package:diohub/view/home/widgets/startup_flow_banners.dart';
import 'package:diohub/view/settings/widgets/link_handling_setup_sheet.dart';

/// Prompted flow: dismissible banner to guide users through setting up GitHub link handling.
class LinkHandlingSetupFlow extends StartupFlow {
  @override
  String get id => 'link_handling_setup';

  @override
  int get priority => 30;

  @override
  FlowTier get tier => FlowTier.prompted;

  @override
  Future<bool> shouldShow(final ProviderContainer container) async {
    final StartupFlowsData data = container.read(startupFlowsProvider);
    if (data.completedFlows.contains(id)) return false;
    if (data.dismissedFlows.contains(id)) return false;
    return true;
  }

  @override
  Widget? buildBanner(
    final BuildContext context, {
    required final VoidCallback onDismiss,
    required final VoidCallback onAction,
  }) {
    return StartupFlowBannerCard(
      icon: Icons.link,
      title: 'Open GitHub links in DioHub',
      subtitle: 'Set up your device to route GitHub links here',
      actionLabel: 'Set up',
      dismissLabel: 'Later',
      onAction: onAction,
      onDismiss: onDismiss,
    );
  }

  @override
  Future<void> markHandled(final ProviderContainer container) async {
    await container.read(startupFlowsProvider.notifier).dismissFlow(id);
  }

  /// Call from UI (e.g. banner action or settings row) to show the setup sheet.
  static Future<void> showSetupSheet(final BuildContext context) async {
    await LinkHandlingSetupSheet.show(context);
  }
}
