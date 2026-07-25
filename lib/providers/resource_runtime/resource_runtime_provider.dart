import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/account/account_provider.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/authentication/account_session.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

ResourceScope resourceScopeForAccount(final AccountModel account) =>
    ResourceScope(serverId: account.serverConfig.id, principal: account.nodeId);

const ResourceScope publicGitHubResourceScope = ResourceScope(
  serverId: 'github.com',
  principal: 'public',
);

/// Current stable resource scope. It is null while account state is unresolved
/// or failed, so authenticated loaders cannot accidentally use a public key.
final activeResourceScopeProvider = Provider<ResourceScope?>((final Ref ref) {
  final accountState = ref.watch(accountProvider);
  if (!accountState.hasValue || accountState.hasError) return null;
  final AccountModel? account = accountState.value?.activeAccountModel;
  return account == null
      ? publicGitHubResourceScope
      : resourceScopeForAccount(account);
});

/// Process-local L1 runtime. Account transitions evict the previous stable
/// scope; transport-cache clearing remains owned by AccountNotifier.
final resourceRuntimeProvider = Provider<ResourceRuntime>((final Ref ref) {
  final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
  ResourceScope? currentScope;

  ref
    ..listen<AsyncValue<AccountSession?>>(accountProvider, (
      final AsyncValue<AccountSession?>? _,
      final AsyncValue<AccountSession?> next,
    ) {
      if (!next.hasValue || next.hasError) return;
      final AccountModel? account = next.value?.activeAccountModel;
      final ResourceScope nextScope = account == null
          ? publicGitHubResourceScope
          : resourceScopeForAccount(account);
      final ResourceScope? previousScope = currentScope;
      currentScope = nextScope;
      if (previousScope != null && previousScope != nextScope) {
        runtime.evictScope(previousScope);
      }
    }, fireImmediately: true)
    ..onDispose(runtime.dispose);

  return runtime;
});

/// Server identity used when a confirmed public session needs an explicit
/// scope other than GitHub.com in a future GHES guest flow.
ResourceScope publicResourceScopeFor(final ServerConfig serverConfig) =>
    ResourceScope(serverId: serverConfig.id, principal: 'public');
