import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/widgets/multi_select_option_list_widget.dart';
import 'package:diohub/providers/notifications/notifications_filters_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a bottom sheet to configure inbox filters (only unread, show only reasons).
/// Used by the Inbox position context action and can be called from shell/config.
void showFilterInboxSheet(BuildContext context, WidgetRef ref) {
  AppSheet.simple<void>(
    context,
    header: AppSheetHeader.text('Inbox filters'),
    bodyBuilder: (BuildContext sheetContext, StateSetter setState) {
      return Consumer(
        builder: (BuildContext sheetContext, WidgetRef ref, _) {
          final NotificationsFiltersState filtersState =
              ref.watch(notificationsFiltersProvider);
          final NotificationsFiltersNotifier notifier =
              ref.read(notificationsFiltersProvider.notifier);
          final List<MultiSelectItem> reasonItems =
              notificationFilterReasonItems
                  .map(
                    (NotificationFilterReasonItem e) => MultiSelectItem(
                      id: e.id,
                      label: e.label,
                      icon: e.icon,
                    ),
                  )
                  .toList();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SwitchListTile.adaptive(
                  value: filtersState.onlyUnread,
                  activeColor: Theme.of(sheetContext).colorScheme.primary,
                  title: Text(
                    'Only unread notifications',
                    style: Theme.of(sheetContext).textTheme.bodyLarge,
                  ),
                  onChanged: notifier.setOnlyUnread,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    'Show only',
                    style:
                        Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(sheetContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                  ),
                ),
                MultiSelectOptionListWidget(
                  items: reasonItems,
                  selectedIds: filtersState.showOnlyReasons.toSet(),
                  onSelectionChanged: (Set<String> ids) =>
                      notifier.setShowOnlyReasons(ids.toList()),
                  onCollapse: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
