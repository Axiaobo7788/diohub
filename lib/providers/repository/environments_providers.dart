import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/environment.dart';
import 'package:diohub/services/base/service_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/providers/database_providers.dart';

final repositoryEnvironmentsProvider =
    FutureProvider.autoDispose.family<EnvironmentsResponse, RepoRef>(
  (ref, repoRef) => repoRef.deployments(ref.read(apiClientProvider)).listEnvironments(),
);

Future<void> deleteEnvironment(
    WidgetRef ref, RepoRef repoRef, String name) async {
  await repoRef.deployments(ref.read(apiClientProvider)).deleteEnvironment(
    environmentName: name,
  );
  ref.invalidate(repositoryEnvironmentsProvider(repoRef));
}
