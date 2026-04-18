import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notifications_filters_provider.freezed.dart';

/// Immutable state for notifications filters.
@freezed
abstract class NotificationsFiltersState with _$NotificationsFiltersState {
  const NotificationsFiltersState._();

  const factory NotificationsFiltersState({
    @Default(true) bool showAll,
    @Default([]) List<String> showOnlyReasons,
  }) = _NotificationsFiltersState;

  bool get onlyUnread => !showAll;
}

/// Notifier for notifications filter state.
class NotificationsFiltersNotifier extends Notifier<NotificationsFiltersState> {
  @override
  NotificationsFiltersState build() => const NotificationsFiltersState();

  void setOnlyUnread(final bool onlyUnread) {
    state = state.copyWith(showAll: !onlyUnread);
  }

  void setShowOnlyReasons(final List<String> reasons) {
    state = state.copyWith(showOnlyReasons: reasons);
  }

  void toggleShowOnlyReason(final String reason) {
    final List<String> current = state.showOnlyReasons;
    final List<String> next = current.contains(reason)
        ? current.where((final String r) => r != reason).toList()
        : <String>[...current, reason];
    setShowOnlyReasons(next);
  }
}

final NotifierProvider<NotificationsFiltersNotifier, NotificationsFiltersState>
    notificationsFiltersProvider =
    NotifierProvider<NotificationsFiltersNotifier, NotificationsFiltersState>(
  NotificationsFiltersNotifier.new,
);

/// Reason id, label, and icon for filter multi-select and badge.
class NotificationFilterReasonItem {
  const NotificationFilterReasonItem({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id;
  final String label;
  final IconData icon;
}

/// Ordered list of notification reasons for the "Show only" filter.
List<NotificationFilterReasonItem> get notificationFilterReasonItems =>
    const <NotificationFilterReasonItem>[
      NotificationFilterReasonItem(
        id: 'assign',
        label: 'Assigned',
        icon: MdiIcons.bullseye,
      ),
      NotificationFilterReasonItem(
        id: 'author',
        label: 'Author',
        icon: MdiIcons.pen,
      ),
      NotificationFilterReasonItem(
        id: 'comment',
        label: 'Comment',
        icon: MdiIcons.comment,
      ),
      NotificationFilterReasonItem(
        id: 'invitation',
        label: 'Invitation',
        icon: Octicons.mail,
      ),
      NotificationFilterReasonItem(
        id: 'manual',
        label: 'Following',
        icon: MdiIcons.information,
      ),
      NotificationFilterReasonItem(
        id: 'mention',
        label: 'Mentioned',
        icon: MdiIcons.at,
      ),
      NotificationFilterReasonItem(
        id: 'review_requested',
        label: 'Review Requested',
        icon: Icons.search_rounded,
      ),
      NotificationFilterReasonItem(
        id: 'security_alert',
        label: 'Security Alert',
        icon: MdiIcons.security,
      ),
      NotificationFilterReasonItem(
        id: 'state_change',
        label: 'Actions',
        icon: Octicons.git_pull_request,
      ),
      NotificationFilterReasonItem(
        id: 'subscribed',
        label: 'Subscribed',
        icon: MdiIcons.information,
      ),
      NotificationFilterReasonItem(
        id: 'team_mention',
        label: 'Team Mention',
        icon: MdiIcons.message,
      ),
    ];
