/// FutureProvider for a single code scanning alert detail. Auto-disposes when sheet closes.
library;

import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code_scanning_alert_item.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/repositories/repo_stats_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot fetch of a code scanning alert by repo and alert number.
/// Use in sheet body with [AsyncValue.when] instead of [FutureBuilder].
final codeScanningAlertDetailProvider = FutureProvider.autoDispose
    .family<CodeScanningAlertItem, ({RepoRef repo, int alertNumber})>(
  (final Ref ref, final ({RepoRef repo, int alertNumber}) args) =>
      RepoStatsService(ref.read(apiClientProvider), args.repo)
          .getCodeScanningAlert(args.alertNumber),
);
