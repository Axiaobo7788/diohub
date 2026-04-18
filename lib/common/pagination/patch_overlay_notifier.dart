import 'package:diohub/common/pagination/item_patch.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic patch overlay keyed by scope string.
///
/// Scope examples:
/// - Issue timeline: `"owner/repo/123"`
/// - Discussion comments: `"discussion/MDQ6SXNzdWUx"`
/// - Discussion reply thread: `"discussion/MDQ6SXNzdWUx/replies/MDEyOk"`
///
/// The controller reads this as a [ValueNotifier] and applies patches
/// over the raw paginated items at render time via [displayItems].
///
/// Usage:
/// ```dart
/// // Apply optimistic edit
/// ref.read(timelinePatchesProvider(scopeKey).notifier).apply(
///   PatchTransformed(commentId, (s) => s.withBody(newBody)),
/// );
///
/// // Rollback on failure
/// ref.read(timelinePatchesProvider(scopeKey).notifier).remove(commentId);
/// ```
class PatchOverlayNotifier extends Notifier<Map<String, ItemPatch>> {
  /// [scope] is the family key; kept for API compatibility with NotifierProvider.family.
  PatchOverlayNotifier(String scope) {}

  @override
  Map<String, ItemPatch> build() => const {};

  /// Apply a patch. If a patch already exists for this item, it's replaced.
  void apply(ItemPatch patch) {
    state = {...state, patch.itemId: patch};
  }

  /// Remove a patch (rollback). The item reverts to its raw paginated state.
  void remove(String itemId) {
    state = Map<String, ItemPatch>.from(state)..remove(itemId);
  }

  /// Clear all patches (e.g. on pull-to-refresh, since fresh data
  /// already reflects server state).
  void clear() => state = const {};
}
