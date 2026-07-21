import 'package:diohub/workbench/domain/git_remote_parser.dart';
import 'package:diohub/workbench/domain/workbench_models.dart';
import 'package:diohub/workbench/domain/workspace_models.dart';
import 'package:test/test.dart';

import 'fakes/fake_workspace_gateways.dart';

void main() {
  const GitRemoteParser parser = GitRemoteParser();

  test('normalizes HTTPS without retaining embedded credentials', () {
    final NormalizedGitRemote? result = parser.tryParse(
      'https://user:secret@github.com/openai/codex.git',
    );

    expect(
      result?.repository,
      const GitHubRepositoryRef(owner: 'openai', name: 'codex'),
    );
    expect(result?.transport, GitRemoteTransport.https);
    expect(result?.displayUrl, 'https://github.com/openai/codex.git');
    expect(result?.displayUrl, isNot(contains('secret')));
  });

  test('normalizes SCP-style SSH and ssh URI enterprise remotes', () {
    final NormalizedGitRemote? scp = parser.tryParse(
      'git@github.com:octocat/Hello-World.git',
    );
    final NormalizedGitRemote? ssh = parser.tryParse(
      'ssh://git@github.example.com:2222/team/project.git',
    );

    expect(scp?.repository.slug, 'octocat/Hello-World');
    expect(scp?.transport, GitRemoteTransport.scpLike);
    expect(ssh?.repository.host, 'github.example.com');
    expect(ssh?.repository.slug, 'team/project');
    expect(ssh?.displayUrl, 'ssh://github.example.com:2222/team/project.git');
  });

  test('rejects local paths and non-repository web URLs', () {
    expect(parser.tryParse('/home/user/project'), isNull);
    expect(parser.tryParse('file:///home/user/project'), isNull);
    expect(
      parser.tryParse('https://github.com/openai/codex/tree/main'),
      isNull,
    );
  });

  test('keeps origin fork and upstream repository as separate links', () {
    final RepoLink origin = parser.tryCreateRepoLink(
      localRootPath: '/workspace/codex',
      remoteName: 'origin',
      remoteUrl: 'git@github.com:contributor/codex.git',
    )!;
    final RepoLink upstream = parser.tryCreateRepoLink(
      localRootPath: '/workspace/codex',
      remoteName: 'upstream',
      remoteUrl: 'https://github.com/openai/codex.git',
    )!;

    expect(origin.remoteRole, GitRemoteRole.origin);
    expect(origin.repository.owner, 'contributor');
    expect(upstream.remoteRole, GitRemoteRole.upstream);
    expect(upstream.repository.owner, 'openai');
    expect(origin.repository, isNot(upstream.repository));
  });

  test('local snapshot exposes selected worktree and dirty/ahead state', () {
    const Worktree worktree = Worktree(
      path: '/workspace/codex',
      isMain: true,
      isDetached: false,
      headSha: 'abc123',
      branch: 'develop',
      branchLink: BranchLink(
        localBranch: 'develop',
        remoteName: 'origin',
        remoteBranch: 'develop',
        ahead: 2,
        behind: 1,
      ),
      changes: GitChangeSummary(
        staged: 1,
        unstaged: 2,
        untracked: 3,
        conflicted: 0,
      ),
    );
    final LocalRepo repository = LocalRepo(
      rootPath: '/workspace/codex',
      commonGitDirectoryPath: '/workspace/codex/.git',
      isBare: false,
      selectedWorktreePath: '/workspace/codex',
      worktrees: const <Worktree>[worktree],
      repositoryLinks: const <RepoLink>[],
      unmatchedRemoteNames: const <String>[],
    );

    expect(repository.selectedWorktree, same(worktree));
    expect(repository.selectedWorktree?.isDirty, isTrue);
    expect(
      repository.selectedWorktree?.branchLink?.trackingRef,
      'origin/develop',
    );
    expect(repository.selectedWorktree?.branchLink?.ahead, 2);
  });

  test(
    'editor fake receives a semantic target instead of shell text',
    () async {
      final FakeEditorGateway editor = FakeEditorGateway();
      const EditorTarget target = EditorTarget(
        workspacePath: '/workspace/codex',
        relativeFilePath: 'lib/main.dart',
        line: 18,
        column: 4,
        expectedHeadSha: 'abc123',
      );

      await editor.open(target);

      expect(editor.openedTargets.single, same(target));
    },
  );
}
