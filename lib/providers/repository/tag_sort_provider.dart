/// Tag list sort order and refresh trigger for the Repo Tags position.
library;

import 'package:diohub_graphql/schema_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Sort order for the tags list.
enum TagSortOrder {
  byDate,
  byName,
}

class _TagSortOrderNotifier extends Notifier<TagSortOrder> {
  _TagSortOrderNotifier(this._arg);
  final RepoRef _arg;
  @override
  TagSortOrder build() => TagSortOrder.byDate;
}

/// Current sort order for the tags list.
final tagSortOrderProvider =
    NotifierProvider.family<_TagSortOrderNotifier, TagSortOrder, RepoRef>(
  _TagSortOrderNotifier.new,
);

/// Increment to trigger the Tags position list to refresh when sort changes.
final ProviderFamily<ValueNotifier<int>, RepoRef> tagsRefreshTriggerProvider =
    Provider.family<ValueNotifier<int>, RepoRef>((ref, repoRef) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);
  return notifier;
});

/// Builds [RefOrder] for the given [TagSortOrder].
RefOrder refOrderForTagSort(TagSortOrder order) {
  return order == TagSortOrder.byName
      ? RefOrder(
          direction: OrderDirection.ASC,
          field: RefOrderField.ALPHABETICAL,
        )
      : RefOrder(
          direction: OrderDirection.DESC,
          field: RefOrderField.TAG_COMMIT_DATE,
        );
}
