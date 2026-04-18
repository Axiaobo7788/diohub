import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/tree_typedefs.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Key for [blameProvider].
typedef BlameKey = ({RepoRef repoRef, String branch, String filePath});

final blameProvider =
    FutureProvider.autoDispose.family<List<BlameRange>, BlameKey>(
  (ref, key) => key.repoRef.gitDb(ref.read(apiClientProvider)).getBlame(key.branch, key.filePath),
);
