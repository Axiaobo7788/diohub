import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The [ServerConfig] for the currently active account.
///
/// All URL construction in the app reads from this provider.
/// When the active account switches, this rebuilds automatically,
/// causing all dependent widgets and services to use the new server's URLs.
final Provider<ServerConfig> activeServerConfigProvider =
    Provider<ServerConfig>(
  (final Ref ref) {
    final session = ref.watch(accountProvider).value;
    final model = session?.activeAccountModel;
    if (model != null) {
      return model.serverConfig;
    }
    return ServerConfig.gitHubDotCom;
  },
);

/// Extension on [WidgetRef] for convenient access to [ServerConfig] and URL builders.
extension ServerConfigRefX on WidgetRef {
  /// The active account's server configuration. Reactive — rebuilds on account switch.
  ServerConfig get activeServerConfig => watch(activeServerConfigProvider);

  /// Build a web URL for an entity on the active server.
  Uri webUrlFor(final EntityRef entityRef) =>
      entityRef.webUrlFor(activeServerConfig);

  /// Build a raw web URL path on the active server.
  Uri webUrl(final String path) => activeServerConfig.webUrl(path);
}
