import 'package:diohub_models/models/server_config.dart';

/// Pure identity interface for anything that can be navigated to — no framework dependencies.
///
/// [EntityRef] subclasses are the primary implementors (for GitHub entities).
/// [HomeDestination] and [UnrecognizedDestination] cover non-entity navigation.
///
/// Routing ([toRoute] / [toRouteStack]) lives in [entity_ref_routes.dart] for [EntityRef]
/// and on the destination classes for [HomeDestination] / [UnrecognizedDestination].
/// Use [NavigableActions] in `routes/navigable_actions.dart` for [navigate], [urlActions], etc.
abstract interface class Navigable {
  /// Web URL for the given server (share, open in browser, URL actions).
  Uri webUrlFor(ServerConfig server);

  /// Legacy getter: web URL using GitHub.com. Prefer [webUrlFor] with active server.
  Uri get webUrl;

  /// Get the API path for this item (without the base URL).
  String get apiPath;

  /// When false, in-app [navigate] should open [webUrl] in browser instead of pushing a route.
  bool get hasNativeRoute => true;
}
