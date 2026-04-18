import 'package:diohub/common/pagination/item_patch.dart';
import 'package:diohub/common/pagination/patch_overlay_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Patch overlay for issue/PR timeline comments.
/// Scope key: "owner/repo/number". Auto-disposes when no longer watched.
final timelinePatchesProvider = NotifierProvider.autoDispose
    .family<PatchOverlayNotifier, Map<String, ItemPatch>, String>(
  PatchOverlayNotifier.new,
);

/// Patch overlay for discussion top-level comments.
/// Scope key: discussion node ID. Auto-disposes when no longer watched.
final discussionPatchesProvider = NotifierProvider.autoDispose
    .family<PatchOverlayNotifier, Map<String, ItemPatch>, String>(
  PatchOverlayNotifier.new,
);

/// Patch overlay for discussion reply threads.
/// Scope key: "commentNodeId/replies". Auto-disposes when no longer watched.
final discussionReplyPatchesProvider = NotifierProvider.autoDispose
    .family<PatchOverlayNotifier, Map<String, ItemPatch>, String>(
  PatchOverlayNotifier.new,
);
