import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:diohub/providers/startup_flows/startup_flows_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flow.dart';
import 'package:diohub/view/home/widgets/startup_flow_banners.dart';

/// Prompted flow: dismissible banner after app update, links to what's-new content.
class WhatsNewFlow extends StartupFlow {
  @override
  String get id => 'whats_new';

  @override
  int get priority => 20;

  @override
  FlowTier get tier => FlowTier.prompted;

  @override
  Future<bool> shouldShow(final ProviderContainer container) async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String currentVersion = info.version;
    final StartupFlowsData data = container.read(startupFlowsProvider);

    if (data.lastSeenVersion == null) {
      await container
          .read(startupFlowsProvider.notifier)
          .setLastSeenVersion(currentVersion);
      return false;
    }
    if (data.lastSeenVersion == currentVersion) return false;
    if (data.dismissedFlows.contains('whats_new')) return false;
    return true;
  }

  @override
  Widget? buildBanner(
    final BuildContext context, {
    required final VoidCallback onDismiss,
    required final VoidCallback onAction,
  }) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (
        final BuildContext context,
        final AsyncSnapshot<PackageInfo> snapshot,
      ) {
        final String version = snapshot.data?.version ?? '';
        return StartupFlowBannerCard(
          icon: Icons.celebration,
          title: 'Updated to v$version',
          subtitle: "See what's new in this release",
          actionLabel: 'View',
          dismissLabel: 'Dismiss',
          onAction: onAction,
          onDismiss: onDismiss,
        );
      },
    );
  }

  @override
  Future<void> markHandled(final ProviderContainer container) async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    await container
        .read(startupFlowsProvider.notifier)
        .setLastSeenVersion(info.version);
    await container.read(startupFlowsProvider.notifier).dismissFlow('whats_new');
  }
}
