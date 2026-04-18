import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Determines how a flow is presented.
enum FlowTier {
  /// Non-dismissible modal. Auto-presents. Blocks all other flows.
  /// Only scope reauth should use this.
  critical,

  /// Dismissible banner/card on home. User taps to engage.
  prompted,

  /// Transient toast notification. Auto-dismisses.
  informational,
}

/// Contract for a one-time (or conditional) startup flow.
///
/// Implementations are registered in [startupFlowRegistry]. UI watches
/// [pendingStartupFlowsProvider] and shows critical modal / prompted banners.
abstract class StartupFlow {
  /// Unique identifier. Persisted in [StartupFlowsData].
  String get id;

  /// Evaluation order. Lower = checked first.
  int get priority;

  /// Presentation tier.
  FlowTier get tier;

  /// Whether this flow should activate right now.
  ///
  /// Pure read — no side effects. Checks persisted state, app version,
  /// scope grants, etc.
  Future<bool> shouldShow(ProviderContainer container);

  /// For [FlowTier.prompted]: build the banner widget shown on home.
  ///
  /// [onDismiss] should be called when the user dismisses the banner.
  /// [onAction] should be called when the user taps the primary CTA.
  /// Returns `null` for non-banner tiers.
  Widget? buildBanner(
    BuildContext context, {
    required VoidCallback onDismiss,
    required VoidCallback onAction,
  });

  /// For [FlowTier.critical]: build the full-screen modal. UI shows it and
  /// calls [onComplete] when the user finishes (e.g. dialog closed).
  /// Returns `null` for non-critical tiers.
  Widget? buildModal(
    BuildContext context, {
    required VoidCallback onComplete,
  }) =>
      null;

  /// Mark this flow as handled in persistence.
  Future<void> markHandled(ProviderContainer container);
}
