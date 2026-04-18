import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/entity_snapshot.dart';
import 'package:diohub/providers/entity_store_notifier.dart'
    show entityStoreMutatorProvider;
import 'package:diohub/providers/entity_store_providers.dart'
    show isBookmarkedProvider, bookmarkStoreProvider;

/// Returns a [BasicDockPill] for bookmark/unbookmark that watches [isBookmarkedProvider]
/// and toggles via [entityStoreMutatorProvider].
BasicDockPill bookmarkDockPill({
  required WidgetRef ref,
  required EntityRef entityRef,
  EntitySnapshot? snapshot,
  RepoRef? contextRepo,
}) {
  final isBookmarked =
      ref.watch(isBookmarkedProvider(entityRef.nodeId ?? '')).asData?.value ??
      false;
  return BasicDockPill(
    iconData: isBookmarked ? Icons.bookmark_rounded : Octicons.bookmark,
    label: isBookmarked ? 'Unbookmark' : 'Bookmark',
    onTapAction: (WidgetRef r) async {
      await r
          .read(entityStoreMutatorProvider)
          .toggleBookmark(
            entityRef,
            context:
                contextRepo ??
                (entityRef is RepoScopedRef ? entityRef.repo : null),
            snapshot: snapshot,
          );
      if (r.context.mounted) {
        r.invalidate(bookmarkStoreProvider);
      }
    },
  );
}
