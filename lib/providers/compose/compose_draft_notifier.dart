import 'dart:async';

import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_database/database/enums/enums.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'compose_draft_notifier.freezed.dart';

@Freezed(equal: false)
abstract class DraftKey with _$DraftKey {
  const DraftKey._();

  const factory DraftKey({
    required String entityPath,
    required String scope,
    required String entityType,
    String? parentPath,
    String? nodeId,
  }) = _DraftKey;

  static DraftKey pill(String persistenceKey) => DraftKey(
        entityPath: persistenceKey,
        scope: 'pill',
        entityType: 'pill',
        parentPath: null,
        nodeId: 'pill:$persistenceKey',
      );

  static DraftKey? fromConfig(ComposeConfig config) {
    if (!config.hasDraft) return null;
    final subject = config.draftSubject!;
    final scope = config.draftScope!;
    return DraftKey(
      entityPath: subject.apiPath,
      scope: scope.dbValue,
      entityType: subject.dbType,
      parentPath: subject.parentPath,
      nodeId: subject.nodeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftKey &&
          entityPath == other.entityPath &&
          scope == other.scope;

  @override
  int get hashCode => Object.hash(entityPath, scope);
}

/// Abstraction for draft persistence.
abstract interface class ComposeDraftStorage {
  Future<String?> getDraft(DraftKey key);
  Future<void> saveDraft(DraftKey key, String body);
  Future<void> deleteDraft(DraftKey key);
}

class DraftsDaoComposeDraftStorage implements ComposeDraftStorage {
  DraftsDaoComposeDraftStorage(
    this._dao,
    this._entityCacheDao,
  );
  final DraftsDao _dao;
  final EntityCacheDao _entityCacheDao;

  static DraftScope _scope(String scope) =>
      DraftScope.fromDb(scope) ?? DraftScope.pill;

  Future<String?> _nodeIdFor(DraftKey key) async {
    if (key.nodeId != null && key.nodeId!.isNotEmpty) return key.nodeId;
    if (key.scope == 'pill') return 'pill:${key.entityPath}';
    return _entityCacheDao.getNodeIdForPath(key.entityPath);
  }

  @override
  Future<String?> getDraft(DraftKey key) async {
    final nodeId = await _nodeIdFor(key);
    if (nodeId == null || nodeId.isEmpty) return null;
    return _dao.getDraft(nodeId, _scope(key.scope));
  }

  @override
  Future<void> saveDraft(DraftKey key, String body) async {
    final nodeId = await _nodeIdFor(key);
    if (nodeId == null || nodeId.isEmpty) return;
    final s = _scope(key.scope);
    if (body.isEmpty) {
      await _dao.deleteDraft(nodeId, s);
    } else {
      await _dao.saveDraft(nodeId: nodeId, scope: s, body: body);
    }
  }

  @override
  Future<void> deleteDraft(DraftKey key) async {
    final nodeId = await _nodeIdFor(key);
    if (nodeId == null || nodeId.isEmpty) return;
    await _dao.deleteDraft(nodeId, _scope(key.scope));
  }
}

final composeDraftStorageProvider = Provider<ComposeDraftStorage>((ref) {
  return DraftsDaoComposeDraftStorage(
    ref.watch(draftsDaoProvider),
    ref.watch(entityCacheDaoProvider),
  );
});

class ComposeDraftNotifier extends AsyncNotifier<String> {
  ComposeDraftNotifier(this.arg);
  final DraftKey arg;

  Timer? _debounceTimer;

  ComposeDraftStorage get _storage => ref.read(composeDraftStorageProvider);

  @override
  Future<String> build() async {
    ref.onDispose(() => _debounceTimer?.cancel());
    final body = await _storage.getDraft(arg);
    return body ?? '';
  }

  void updateBody(String body) {
    state = AsyncValue.data(body);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await _persist(body);
    });
  }

  Future<void> save(String body) async {
    state = AsyncValue.data(body);
    _debounceTimer?.cancel();
    await _persist(body);
  }

  Future<void> clear() async {
    state = const AsyncValue.data('');
    _debounceTimer?.cancel();
    await _storage.deleteDraft(arg);
  }

  Future<void> _persist(String body) async {
    if (body.isEmpty) {
      await _storage.deleteDraft(arg);
    } else {
      await _storage.saveDraft(arg, body);
    }
  }
}

final composeDraftProvider = AsyncNotifierProvider.autoDispose
    .family<ComposeDraftNotifier, String, DraftKey>(ComposeDraftNotifier.new);

final composeDraftExistsProvider = Provider.family<bool, String>((ref, key) {
  final body =
      ref.watch(composeDraftProvider(DraftKey.pill(key))).asData?.value ?? '';
  return body.trim().isNotEmpty;
});
