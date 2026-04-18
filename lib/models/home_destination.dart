import 'package:auto_route/auto_route.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub_models/models/home_filter.dart';

/// App home screen — not a GitHub entity, just an in-app destination.
///
/// Created by the deep link parser for bare `github.com` or home-path URLs
/// (`/issues`, `/pulls`, `/notifications`, etc.).
class HomeDestination implements Navigable {
  const HomeDestination({this.initialTabPath, this.filter});

  final String? initialTabPath;
  final HomeFilter? filter;

  @override
  PageRouteInfo toRoute() =>
      HomeRoute(initialTabPath: initialTabPath, filter: filter);

  @override
  List<PageRouteInfo> toRouteStack() => [toRoute()];

  @override
  Uri webUrlFor(ServerConfig server) {
    final String path = initialTabPath != null ? '/$initialTabPath' : '/';
    final String filterPath = filter != null ? '/${filter!.value}' : '';
    return server.webUrl('$path$filterPath');
  }

  @override
  Uri get webUrl => webUrlFor(ServerConfig.gitHubDotCom);

  @override
  String get apiPath => '';

  @override
  bool get hasNativeRoute => true;
}
