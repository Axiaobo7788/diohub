import 'package:diohub/common/misc/async_error_widgets.dart';
import 'package:diohub/common/misc/loading_indicator.dart';
import 'package:diohub/common/nav_center/models/tab_body.dart';
import 'package:diohub/common/nav_center/models/tab_config.dart';
import 'package:diohub/common/nav_center/shell/tab_body_page.dart';
import 'package:diohub/providers/logging/log_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/view/logs/log_detail_sheet.dart';
import 'package:diohub/common/widgets/log_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared "Logs" position for entity detail screens.
/// Replaces copy-pasted implementations in issue, pull, repo, and commit configs.
TabConfig buildEntityLogsPosition({
  required String entityPath,
  required String emptyMessage,
}) =>
    TabConfig(
      deeplinkPath: 'entity-logs',
      label: 'Logs',
      icon: Icons.bug_report_rounded,
      category: TabCategory.other,
      keepAlive: false,
      body: TabBodyPage(
        body: SliverBuilderBody(
          sliverBuilder: (ctx, r) {
            final logsAsync = r.watch(entityLogsProvider(entityPath));
            final spacing = ctx.spacing;
            return [
              logsAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          emptyMessage,
                          style: Theme.of(ctx).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: spacing.listInset,
                    sliver: SliverList.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: spacing.itemSpacing),
                          child: LogEntryCard(
                            entry: entry,
                            onTap: () => LogDetailSheet.show(ctx, entry),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: const CenteredSpinner(),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: spacing.pagePadding,
                    child: CenteredError(e.toString()),
                  ),
                ),
              ),
            ];
          },
        ),
      ),
    );
