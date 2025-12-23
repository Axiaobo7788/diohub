import 'package:diohub/common/utils/contribution_utils.dart';
import 'package:diohub/services/users/user_activity_service.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_event.dart';
import 'package:diohub/view/profile/about/widgets/activity_timeline_item.dart';
import 'package:flutter/material.dart';

/// Bottom sheet displaying activity for a specific day
class DayActivityBottomSheet extends StatelessWidget {
  const DayActivityBottomSheet({
    required this.login,
    required this.from,
    required this.to,
    super.key,
  });

  final String login;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final future = UserActivityService.getUserActivityTimeline(
      login: login,
      from: from,
      to: to,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return FutureBuilder<UserActivityTimelineData>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _buildHeader(context, theme),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  _buildHeader(context, theme),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load activity',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data;
            final events = data?.events
                    .where((e) => e.event != null)
                    .map((e) => e.event!)
                    .toList() ??
                <ActivityTimelineEvent>[];

            if (events.isEmpty) {
              return Column(
                children: [
                  _buildHeader(context, theme),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No activity for this day',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildHeader(context, theme),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ActivityTimelineItem(
                        event: event,
                        userLogin: login,
                        userAvatarUrl: null,
                        isFirst: index == 0,
                        isLast: index == events.length - 1,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Activity on ${formatDateOnly(from)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
