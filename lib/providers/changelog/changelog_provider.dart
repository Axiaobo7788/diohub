import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/services/changelog/changelog_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:diohub/services/changelog/changelog_service.dart';

final Provider<ChangelogService> changelogServiceProvider =
    Provider<ChangelogService>(
  (ref) => ChangelogService(ref.read(apiClientProvider)),
);
