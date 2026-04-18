/// A single patch operation on a paginated item. Applied at render time
/// by the controller's [displayItems] getter without mutating stored state.
sealed class ItemPatch {
  const ItemPatch(this.itemId);
  final String itemId;
}

class PatchReplaced<T> extends ItemPatch {
  const PatchReplaced(super.itemId, this.replacement);
  final T replacement;
}

class PatchDeleted extends ItemPatch {
  const PatchDeleted(super.itemId);
}

class PatchTransformed<T> extends ItemPatch {
  const PatchTransformed(super.itemId, this.transform);
  final T Function(T current) transform;
}

class PatchMinimized extends ItemPatch {
  const PatchMinimized(super.itemId, this.reason);
  final String reason;
}

class PatchUnminimized extends ItemPatch {
  const PatchUnminimized(super.itemId);
}

class PatchInserted<T> extends ItemPatch {
  const PatchInserted(super.itemId, this.item, {this.index});
  final T item;
  final int? index;
}

class PatchCommentEdit extends ItemPatch {
  const PatchCommentEdit(
    super.itemId, {
    required this.body,
    required this.bodyHTML,
    this.lastEditedAt,
  });
  final String body;
  final String bodyHTML;
  final DateTime? lastEditedAt;
}
