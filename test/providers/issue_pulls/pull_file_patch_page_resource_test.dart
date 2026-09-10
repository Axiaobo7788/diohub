import 'package:diohub/common/pagination/runtime_forward_page_source.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/providers/issue_pulls/pull_file_patch_page_resource.dart';
import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
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
  test('different file lookups reuse fresh Runtime patch pages', () async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
    final List<int> calls = <int>[];

    RuntimeForwardPageSource<DiffEntry, int> createSource() =>
        RuntimeForwardPageSource<DiffEntry, int>(
          runtime: runtime,
          firstPageKey: 1,
          specFactory:
              ({required final int pageKey, required final int pageSize}) =>
                  pullFilePatchPageSpec(
                    pullRequest: _pullRequest,
                    page: pageKey,
                    pageSize: pageSize,
                    scope: _scope,
                    loadPage:
                        ({
                          required final int page,
                          required final int pageSize,
                        }) async {
                          calls.add(page);
                          return switch (page) {
                            1 => const <DiffEntry>[
                              DiffEntry(filename: 'a.dart'),
                              DiffEntry(filename: 'b.dart'),
                            ],
                            _ => const <DiffEntry>[
                              DiffEntry(filename: 'c.dart'),
                            ],
                          };
                        },
                  ),
          refreshSelector: pullFilePatchQuerySelector(
            pullRequest: _pullRequest,
            scope: _scope,
          ),
        );

    final RuntimeForwardPageSource<DiffEntry, int> first = createSource();
    final pageOne = await first.fetchForward(2);
    final pageTwo = await first.fetchForward(2);
    expect(pageOne.items.map((entry) => entry.filename), <String>[
      'a.dart',
      'b.dart',
    ]);
    expect(pageTwo.items.map((entry) => entry.filename), <String>['c.dart']);
    first.dispose();

    final RuntimeForwardPageSource<DiffEntry, int> returned = createSource();
    addTearDown(() {
      returned.dispose();
      runtime.dispose();
    });
    final cachedFirstPage = await returned.fetchForward(2);

    expect(cachedFirstPage.items.first.filename, 'a.dart');
    expect(calls, <int>[1, 2]);
  });
}
