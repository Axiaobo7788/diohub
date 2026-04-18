import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub_graphql/queries/viewer/viewer_typedefs.dart';
import 'package:diohub/providers/rate_limit_provider.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows current GraphQL API rate limit in a bottom sheet.
class RateLimitSheet {
  RateLimitSheet._();

  static void show(final BuildContext context, final WidgetRef ref) {
    ref.invalidate(rateLimitProvider);
    AppSheet.simple<void>(
      context,
      header: AppSheetHeader(title: Text('API Rate Limit')),
      bodyBuilder: (final BuildContext context, final StateSetter setState) {
        return Consumer(
          builder: (final BuildContext context, final WidgetRef ref, final _) {
            final async = ref.watch(rateLimitProvider);
            return async.when(
              data: (final RateLimitData? data) {
                final rl = data?.rateLimit;
                if (rl == null) {
                  return Padding(
                    padding: context.spacing.cardContentPadding,
                    child: Text(
                      'Rate limit not available.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                final spacing = context.spacing;
                final theme = Theme.of(context);
                return Padding(
                  padding: spacing.cardContentPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _Row(
                        label: 'Used',
                        value: '${rl.used}',
                        theme: theme,
                      ),
                      _Row(
                        label: 'Remaining',
                        value: '${rl.remaining}',
                        theme: theme,
                      ),
                      _Row(
                        label: 'Limit',
                        value: '${rl.limit}',
                        theme: theme,
                      ),
                      _Row(
                        label: 'Reset at',
                        value: _formatResetAt(rl.resetAt),
                        theme: theme,
                      ),
                      _Row(
                        label: 'Last query cost',
                        value: '${rl.cost}',
                        theme: theme,
                      ),
                      _Row(
                        label: 'Node count',
                        value: '${rl.nodeCount}',
                        theme: theme,
                      ),
                    ],
                  ),
                );
              },
              loading: () => Padding(
                padding: context.spacing.spaciousPadding,
                child: const Center(child: LoadingIndicator(size: 32)),
              ),
              error: (final Object err, final _) => Padding(
                padding: context.spacing.cardContentPadding,
                child: Text(
                  'Failed to load rate limit: $err',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatResetAt(final DateTime resetAt) {
    final now = DateTime.now();
    if (resetAt.isAfter(now)) {
      final diff = resetAt.difference(now);
      final mins = diff.inMinutes;
      if (mins < 60) return 'in ${mins} min';
      return 'in ${(mins / 60).toStringAsFixed(1)} h';
    }
    return resetAt.toIso8601String();
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
