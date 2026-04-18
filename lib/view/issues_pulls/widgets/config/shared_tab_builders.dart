import 'package:diohub/common/context_dock/context_dock.dart';
import 'package:diohub/common/nav_center/models/ambient_indicator.dart';
import 'package:diohub/common/nav_center/models/nav_center_models.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_controls.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/providers/dock/inline_search_query_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Shared discussion/content tab: slivers + optional compose bar + trailing/ambient.
TabConfig buildDiscussionTab({
  required String label,
  required List<Widget> Function(BuildContext, WidgetRef) sliverBuilder,
  required Future<void> Function() refreshFuture,
  ComposeBarConfig? composeBar,
  List<DockPill> Function(BuildContext, WidgetRef)? dockActions,
  int? commentsCount,
  AmbientIndicator? ambientIndicator,
  List<DockPill> Function(BuildContext, WidgetRef)? inlineControls,
}) {
  return TabConfig(
    label: label,
    icon: Octicons.comment_discussion,
    category: TabCategory.content,
    keepAlive: true,
    body: TabBodyPage(
      body: SliverBuilderBody(
        sliverBuilder: sliverBuilder,
        refreshFuture: refreshFuture,
        composeBar: composeBar,
      ),
    ),
    trailing: commentsCount != null && commentsCount > 0
        ? CountTrailing(() => commentsCount)
        : null,
    ambientIndicator: ambientIndicator,
    inlineControls: inlineControls ?? (_, __) => [],
    dockActions: dockActions ?? (_, __) => [],
  );
}

/// Shared participants tab: position buildSlivers + search pill keyed by entity.
/// [participantsQueryKey] is used for [inlineSearchQueryNotifierProvider] (e.g. 'issue/owner/name/123/participants').
TabConfig buildParticipantsTab({
  required String participantsQueryKey,
  required Future<void> Function() refreshFuture,
  required List<Widget> Function(BuildContext, WidgetRef) buildSlivers,
  required int participantsCount,
  required List<String> participantAvatarUrls,
  required WidgetRef widgetRef,
}) {
  final queryKey = participantsQueryKey;
  return TabConfig(
    label: 'Participants',
    icon: Octicons.people,
    category: TabCategory.social,
    keepAlive: true,
    body: TabBodyPage(
      body: SliverBuilderBody(
        sliverBuilder: buildSlivers,
        refreshFuture: refreshFuture,
      ),
    ),
    trailing:
        participantsCount > 0 ? CountTrailing(() => participantsCount) : null,
    ambientIndicator: participantAvatarUrls.isNotEmpty
        ? AvatarStackAmbient(avatarUrls: participantAvatarUrls)
        : null,
    controls: TabControls.clientList(
      searchQuery: widgetRef.read(inlineSearchQueryNotifierProvider(queryKey)),
    ),
  );
}
