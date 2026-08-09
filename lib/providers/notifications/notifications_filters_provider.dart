import 'package:diohub/providers/entity_store_providers.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub_models/models/events/notifications_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

enum NotificationSortOrder { newest, oldest }

@immutable
class NotificationsProjectionState {
  const NotificationsProjectionState({
    this.query = '',
    this.repository,
    this.sortOrder = NotificationSortOrder.newest,
  });

  final String query;
  final String? repository;
  final NotificationSortOrder sortOrder;

  NotificationsProjectionState copyWith({
    final String? query,
    final String? repository,
    final bool clearRepository = false,
    final NotificationSortOrder? sortOrder,
  }) => NotificationsProjectionState(
    query: query ?? this.query,
    repository: clearRepository ? null : repository ?? this.repository,
    sortOrder: sortOrder ?? this.sortOrder,
  );
}

class NotificationsProjectionNotifier
    extends Notifier<NotificationsProjectionState> {
  @override
  NotificationsProjectionState build() => const NotificationsProjectionState();

  void setQuery(final String query) {
    state = state.copyWith(query: query);
  }

  void setRepository(final String? repository) {
    state = repository == null
        ? state.copyWith(clearRepository: true)
        : state.copyWith(repository: repository);
  }

  void setSortOrder(final NotificationSortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }
}

final NotifierProvider<
  NotificationsProjectionNotifier,
  NotificationsProjectionState
>
notificationsProjectionProvider =
    NotifierProvider<
      NotificationsProjectionNotifier,
      NotificationsProjectionState
    >(NotificationsProjectionNotifier.new);

typedef NotificationSavedFilter = ({
  String label,
  String query,
  String storedQuery,
});

const String notificationSavedSearchType = 'notifications';
const String notificationSavedSearchPrefix = 'notifications::';

final Provider<AsyncValue<List<NotificationSavedFilter>>>
notificationSavedFiltersProvider =
    Provider<AsyncValue<List<NotificationSavedFilter>>>((final Ref ref) {
      return ref.watch(allSavedSearchesProvider).whenData((
        final List<SavedSearchEntry> entries,
      ) {
        return entries
            .where(
              (final SavedSearchEntry entry) =>
                  entry.searchType == notificationSavedSearchType &&
                  entry.query.startsWith(notificationSavedSearchPrefix),
            )
            .map((final SavedSearchEntry entry) {
              final String query = entry.query.substring(
                notificationSavedSearchPrefix.length,
              );
              return (
                label: entry.label?.trim().isNotEmpty ?? false
                    ? entry.label!.trim()
                    : query,
                query: query,
                storedQuery: entry.query,
              );
            })
            .toList(growable: false);
      });
    });

List<Thread> projectNotifications({
  required final Iterable<Thread> items,
  required final bool showAll,
  required final Set<String> reasons,
  required final NotificationsProjectionState projection,
  required final bool groupByRepository,
}) {
  final List<Thread> visible = items
      .where((final Thread item) {
        if (!showAll && !item.unread) {
          return false;
        }
        if (reasons.isNotEmpty &&
            !reasons.any(
              (final String reason) =>
                  _matchesReasonFilter(item.reason, reason),
            )) {
          return false;
        }
        final String? repository = projection.repository;
        if (repository != null &&
            item.repository.fullName.toLowerCase() !=
                repository.toLowerCase()) {
          return false;
        }
        return _matchesNotificationQuery(item, projection.query);
      })
      .toList(growable: true);

  visible.sort((final Thread left, final Thread right) {
    if (groupByRepository) {
      final int repositoryOrder = left.repository.fullName
          .toLowerCase()
          .compareTo(right.repository.fullName.toLowerCase());
      if (repositoryOrder != 0) {
        return repositoryOrder;
      }
    }
    final int timeOrder = _notificationTimestamp(
      left,
    ).compareTo(_notificationTimestamp(right));
    return projection.sortOrder == NotificationSortOrder.oldest
        ? timeOrder
        : -timeOrder;
  });
  return List<Thread>.unmodifiable(visible);
}

bool _matchesNotificationQuery(final Thread item, final String rawQuery) {
  final String query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return true;
  }
  final List<String> terms = query
      .split(RegExp(r'\s+'))
      .where((final String term) => term.isNotEmpty)
      .toList(growable: false);
  for (final String term in terms) {
    final int separator = term.indexOf(':');
    if (separator > 0) {
      final String qualifier = term.substring(0, separator);
      final String value = term.substring(separator + 1);
      if (!_matchesQualifier(item, qualifier, value)) {
        return false;
      }
      continue;
    }
    final String haystack =
        '${item.repository.fullName} ${item.subject.title} ${item.reason}'
            .toLowerCase();
    if (!haystack.contains(term)) {
      return false;
    }
  }
  return true;
}

bool _matchesReasonFilter(
  final String notificationReason,
  final String filterReason,
) {
  if (notificationReason == filterReason) {
    return true;
  }
  return filterReason == 'participating' &&
      const <String>{
        'author',
        'comment',
        'subscribed',
      }.contains(notificationReason);
}

bool _matchesQualifier(
  final Thread item,
  final String qualifier,
  final String value,
) {
  return switch (qualifier) {
    'repo' => item.repository.fullName.toLowerCase() == value,
    'reason' => item.reason.replaceAll('_', '-') == value.replaceAll('_', '-'),
    'is' => switch (value) {
      'read' => !item.unread,
      'unread' => item.unread,
      'issue' => item.subject.type == NotificationSubjectType.issue,
      'pull-request' ||
      'pr' => item.subject.type == NotificationSubjectType.pullRequest,
      'release' => item.subject.type == NotificationSubjectType.release,
      'discussion' => item.subject.type == NotificationSubjectType.discussion,
      'commit' => item.subject.type == NotificationSubjectType.commit,
      'check-suite' => item.subject.type == NotificationSubjectType.checkSuite,
      _ => false,
    },
    _ => false,
  };
}

DateTime _notificationTimestamp(final Thread item) =>
    item.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

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
        id: 'participating',
        label: 'Participating',
        icon: MdiIcons.commentOutline,
      ),
      NotificationFilterReasonItem(
        id: 'mention',
        label: 'Mentioned',
        icon: MdiIcons.at,
      ),
      NotificationFilterReasonItem(
        id: 'team_mention',
        label: 'Team Mention',
        icon: MdiIcons.message,
      ),
      NotificationFilterReasonItem(
        id: 'review_requested',
        label: 'Review Requested',
        icon: Icons.search_rounded,
      ),
    ];
