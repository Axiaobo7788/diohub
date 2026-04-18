import 'package:diohub/providers/router_provider.dart';
import 'package:diohub/providers/startup_flows/startup_flow.dart';
import 'package:diohub/providers/startup_flows/startup_flow_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of evaluating pending startup flows. UI watches this and shows
/// critical modal and prompted banners; no orchestrator or semaphore.
class PendingFlows {
  const PendingFlows({
    this.critical = const [],
    this.prompted = const [],
  });

  const PendingFlows.empty()
      : critical = const [],
        prompted = const [];

  final List<StartupFlow> critical;
  final List<StartupFlow> prompted;
}

/// Stateless provider: returns which flows should be shown. HomeScreen
/// watches and renders critical modal + prompted banners. No execute(),
/// no Completer wait — providers return data, UI renders.
final pendingStartupFlowsProvider =
    FutureProvider.autoDispose<PendingFlows>((ref) async {
  if (ref.read(pendingDeepLinkProvider) != null) {
    return const PendingFlows.empty();
  }
  final List<StartupFlow> flows = List<StartupFlow>.from(startupFlowRegistry)
    ..sort((final StartupFlow a, final StartupFlow b) =>
        a.priority.compareTo(b.priority));
  final List<StartupFlow> critical = <StartupFlow>[];
  final List<StartupFlow> prompted = <StartupFlow>[];
  for (final StartupFlow flow in flows) {
    if (!await flow.shouldShow(ref.container)) continue;
    switch (flow.tier) {
      case FlowTier.critical:
        critical.add(flow);
      case FlowTier.prompted:
        if (prompted.length < 2) prompted.add(flow);
      case FlowTier.informational:
        await flow.markHandled(ref.container);
    }
  }
  return PendingFlows(critical: critical, prompted: prompted);
});
