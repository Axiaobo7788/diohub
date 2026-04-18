enum AppLayer {
  view,
  providers,
  services,
  repositories,
  models,
  common,
  database,
  graphql,
  style,
  utils,
  routes,
  adapters,
  app,
  debug,
  unknown,
}

/// Resolves the architectural layer from a file path.
/// Expects paths like `package:diohub/view/home/home.dart`
/// or absolute paths containing `lib/view/...`.
AppLayer resolveLayer(String filePath) {
  final libIndex = filePath.indexOf('lib/');
  if (libIndex == -1) return AppLayer.unknown;
  final relative = filePath.substring(libIndex + 4);

  if (relative.startsWith('view/')) return AppLayer.view;
  if (relative.startsWith('providers/')) return AppLayer.providers;
  if (relative.startsWith('services/')) return AppLayer.services;
  if (relative.startsWith('repositories/')) return AppLayer.repositories;
  if (relative.startsWith('models/')) return AppLayer.models;
  if (relative.startsWith('common/')) return AppLayer.common;
  if (relative.startsWith('database/')) return AppLayer.database;
  if (relative.startsWith('graphql/')) return AppLayer.graphql;
  if (relative.startsWith('style/')) return AppLayer.style;
  if (relative.startsWith('utils/')) return AppLayer.utils;
  if (relative.startsWith('routes/')) return AppLayer.routes;
  if (relative.startsWith('adapters/')) return AppLayer.adapters;
  if (relative.startsWith('app/')) return AppLayer.app;
  if (relative.startsWith('debug/')) return AppLayer.debug;
  return AppLayer.unknown;
}

/// Resolves the layer from a `package:diohub/...` import URI.
AppLayer resolveImportLayer(String importUri) {
  if (!importUri.startsWith('package:diohub/')) return AppLayer.unknown;
  final relative = importUri.substring('package:diohub/'.length);
  return resolveLayer('lib/$relative');
}
