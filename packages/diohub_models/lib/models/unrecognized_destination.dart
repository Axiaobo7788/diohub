import 'package:auto_route/auto_route.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub_models/models/server_config.dart';

/// A GitHub URL that the parser couldn't map to a known entity or destination.
///
/// Callers should open [webUrl] in a browser instead of calling [toRoute].
class UnrecognizedDestination implements Navigable {
  const UnrecognizedDestination({required this.uri});
  final Uri uri;

  @override
  PageRouteInfo toRoute() =>
      throw UnsupportedError('UnrecognizedDestination cannot be routed');

  @override
  List<PageRouteInfo> toRouteStack() => [toRoute()];

  @override
  Uri webUrlFor(ServerConfig server) => uri;

  @override
  Uri get webUrl => uri;

  @override
  String get apiPath => '';

  @override
  bool get hasNativeRoute => false;
}
