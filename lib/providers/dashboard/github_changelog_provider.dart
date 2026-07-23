import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/models/github_changelog_item.dart';
import 'package:diohub/services/dashboard/github_changelog_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<GitHubChangelogService> githubChangelogServiceProvider =
    Provider<GitHubChangelogService>((final Ref ref) {
      final GitHubChangelogService service = GitHubChangelogService();
      ref.onDispose(service.close);
      return service;
    });

/// Latest public GitHub product updates.
///
/// Loading and failures intentionally remain represented by [AsyncValue] so
/// the dashboard can render honest loading, retry, and last-known UI states.
final FutureProvider<List<GitHubChangelogItem>> githubChangelogProvider =
    FutureProvider.autoDispose<List<GitHubChangelogItem>>(
      (final Ref ref) async {
        keepAliveFor(ref);
        return ref.watch(githubChangelogServiceProvider).fetchLatest();
      },
      // The dashboard owns its retry UI. Automatic retries would otherwise
      // keep an offline panel cycling through loading states for many seconds.
      retry: (final int retryCount, final Object error) => null,
    );
