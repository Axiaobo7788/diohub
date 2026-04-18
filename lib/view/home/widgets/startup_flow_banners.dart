import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/animations/motion.dart';
import 'package:diohub/providers/shorebird/shorebird_update_provider.dart';
import 'package:diohub/providers/shorebird/shorebird_update_state.dart';
import 'package:diohub/providers/startup/app_startup_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/app/startup_flows/flows/shorebird_patch_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:diohub/providers/startup_flows/pending_startup_flows_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flow.dart';
import 'package:diohub/view/app/startup_flows/flows/link_handling_setup_flow.dart';
import 'package:diohub/view/app/startup_flows/flows/onboarding_flow.dart';
import 'package:diohub/view/app/startup_flows/flows/scope_reauth_flow.dart';
import 'package:diohub/view/app/startup_flows/flows/whats_new_flow.dart';
import 'package:diohub/view/onboarding/onboarding_overlay.dart';

/// Reusable banner card for prompted startup flows.
///
/// Uses surfaceContainerHigh-style background, rounded corners, leading icon,
/// trailing dismiss button, and primary action button.
class StartupFlowBannerCard extends StatelessWidget {
  const StartupFlowBannerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
    this.dismissLabel = 'Later',
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String dismissLabel;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppSpacing spacing = context.spacing;

    return AnimatedSwitcher(
      duration: kStateDuration,
      switchInCurve: kStateCurve,
      switchOutCurve: kStateCurve,
      child: Card(
        key: ValueKey<String>(title),
        margin: EdgeInsets.fromLTRB(
          spacing.screenPadding.left,
          spacing.itemSpacing,
          spacing.screenPadding.right,
          spacing.itemSpacing,
        ),
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: spacing.cardContentPadding,
          child: Row(
            children: <Widget>[
              Icon(icon, color: scheme.primary, size: 28),
              SizedBox(width: spacing.itemSpacing),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacing.tightSpacing),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.itemSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: onDismiss,
                          child: Text(dismissLabel),
                        ),
                        SizedBox(width: spacing.tightSpacing),
                        FilledButton(
                          onPressed: onAction,
                          child: Text(actionLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
                tooltip: 'Dismiss',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of prompted startup flow banners shown above home content.
/// [promptedFlows] from [pendingStartupFlowsProvider]; dismiss/action
/// call [markHandled] and invalidate the provider.
class StartupFlowBanners extends ConsumerWidget {
  const StartupFlowBanners({
    required this.promptedFlows,
    super.key,
  });

  final List<StartupFlow> promptedFlows;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final StartupFlow flow in promptedFlows) ...<Widget>[
          _buildBanner(context, ref, flow),
        ],
      ],
    );
  }

  Widget _buildBanner(
    final BuildContext context,
    final WidgetRef ref,
    final StartupFlow flow,
  ) {
    final Widget? widget = flow.buildBanner(
      context,
      onDismiss: () {
        unawaited(_handleDismiss(context, ref, flow));
      },
      onAction: () {
        unawaited(_handleAction(context, ref, flow));
      },
    );
    if (widget == null) return const SizedBox.shrink();
    return widget;
  }

  Future<void> _handleDismiss(
    final BuildContext context,
    final WidgetRef ref,
    final StartupFlow flow,
  ) async {
    await flow.markHandled(ref.container);
    if (context.mounted) {
      ref.invalidate(pendingStartupFlowsProvider);
    }
  }

  Future<void> _handleAction(
    final BuildContext context,
    final WidgetRef ref,
    final StartupFlow flow,
  ) async {
    if (flow is OnboardingFlow) {
      if (context.mounted) showOnboardingOverlay(context);
    } else if (flow is WhatsNewFlow) {
      if (context.mounted) {
        context.router.push(const ChangelogRoute());
      }
    } else if (flow is LinkHandlingSetupFlow) {
      if (context.mounted) {
        await LinkHandlingSetupFlow.showSetupSheet(context);
      }
    } else if (flow is ScopeReauthFlow) {
      if (context.mounted) {
        await ScopeReauthFlow.handleUpdateAction(context);
      }
    } else if (flow is ShorebirdPatchFlow) {
      ref.read(shorebirdUpdateProvider).whenData(
        (ShorebirdPatchState currentState) async {
          if (currentState is PatchReadyToInstall) {
            // Restart the app by invalidating the startup provider
            ref.invalidate(appStartupProvider);
          } else if (currentState is PatchAvailable) {
            await ref
                .read(shorebirdUpdateProvider.notifier)
                .downloadAndInstall();
          } else if (currentState is PatchFailed) {
            await ref.read(shorebirdUpdateProvider.notifier).recheck();
          }
        },
      );
    }
    await flow.markHandled(ref.container);
    if (context.mounted) {
      ref.invalidate(pendingStartupFlowsProvider);
    }
  }
}
