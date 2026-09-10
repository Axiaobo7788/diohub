import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/issue_pulls/pull_file_patch_page_resource.dart';
import 'package:diohub/providers/issue_pulls/pull_files_providers.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);
const PullRequestRef _pullRequest = PullRequestRef(
  repo: RepoRef(owner: 'octo', name: 'repo'),
  number: 42,
);

void main() {
  test('matching the first page does not request a second page', () async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final List<int> calls = <int>[];
    final ProviderContainer container = _container(
      runtime: runtime,
      loadPage: ({required final int page, required final int pageSize}) async {
        calls.add(page);
        return List<DiffEntry>.generate(
          pageSize,
          (final int index) => DiffEntry(
            filename: index == 3 ? 'target.dart' : 'file-$index.dart',
          ),
        );
      },
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });

    final DiffEntry? result = await container.read(
      pullFilePatchProvider((pr: _pullRequest, path: 'target.dart')).future,
    );

    expect(result?.filename, 'target.dart');
    expect(calls, <int>[1]);
  });

  test('different lookups on one page reuse the Runtime page', () async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final List<int> calls = <int>[];
    final ProviderContainer container = _container(
      runtime: runtime,
      loadPage: ({required final int page, required final int pageSize}) async {
        calls.add(page);
        return const <DiffEntry>[
          DiffEntry(filename: 'a.dart'),
          DiffEntry(filename: 'b.dart'),
        ];
      },
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });

    final DiffEntry? first = await container.read(
      pullFilePatchProvider((pr: _pullRequest, path: 'a.dart')).future,
    );
    final DiffEntry? second = await container.read(
      pullFilePatchProvider((pr: _pullRequest, path: 'b.dart')).future,
    );

    expect(first?.filename, 'a.dart');
    expect(second?.filename, 'b.dart');
    expect(calls, <int>[1]);
  });
}

ProviderContainer _container({
  required final InMemoryResourceRuntime runtime,
  required final Future<List<DiffEntry>> Function({
    required int page,
    required int pageSize,
  })
  loadPage,
}) => ProviderContainer(
  overrides: <Override>[
    activeResourceScopeProvider.overrideWithValue(_scope),
    resourceRuntimeProvider.overrideWithValue(runtime),
    pullFilePatchPageSpecFactoryProvider.overrideWithValue(
      _specFactoryFor(loadPage),
    ),
  ],
);

PullFilePatchPageSpecFactory _specFactoryFor(
  final Future<List<DiffEntry>> Function({
    required int page,
    required int pageSize,
  })
  loadPage,
) =>
    ({
      required final PullRequestRef pullRequest,
      required final int page,
      required final int pageSize,
      required final ResourceScope scope,
    }) => pullFilePatchPageSpec(
      pullRequest: pullRequest,
      page: page,
      pageSize: pageSize,
      scope: scope,
      loadPage: loadPage,
    );
