import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/file_content.dart';
import 'package:diohub/common/riverpod/keep_alive_helper.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

/// Key for [fileContentProvider].
typedef FileContentKey = ({RepoRef repo, String branch, String path});

final fileContentProvider =
    FutureProvider.autoDispose.family<FileContent, FileContentKey>(
  (ref, key) async {
    keepAliveFor(ref);
    return key.repo.gitDb(ref.read(apiClientProvider)).fetchFileContent(
      '${key.branch}:${key.path}',
    );
  },
);
