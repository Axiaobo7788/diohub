import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repository/compare_result.dart' show CompareCommitSummary;
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key for [pushCompareProvider].
typedef PushCompareKey = ({RepoRef repo, String? base, String head});

final pushCompareProvider = FutureProvider.autoDispose
    .family<List<CompareCommitSummary>, PushCompareKey>((ref, key) async {
  if (key.base == null) return <CompareCommitSummary>[];
  return key.repo.services(ref.read(apiClientProvider)).getCompareCommits(
    base: key.base!,
    head: key.head,
  );
});
