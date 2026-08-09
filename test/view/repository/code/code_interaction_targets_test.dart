import 'package:diohub/view/repository/code/widgets/breadcrumb_bar.dart';
import 'package:diohub/view/repository/code/widgets/directory_entry_tile.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repositories/code/code_tree_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('production breadcrumb links keep a 48px hit target', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: BreadcrumbBar(
            repoName: 'hello-world',
            currentPath: 'lib/src',
            onRootTap: () {},
            onSegmentTap: (final int _) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder targets = find.byType(InkWell);
    expect(targets, findsNWidgets(2));
    for (final Element element in targets.evaluate()) {
      expect(
        (element.renderObject! as RenderBox).size.height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy fallback directory row keeps a 48px hit target', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: DirectoryEntryTile(
              entry: const CodeTreeNode(
                name: 'lib',
                path: 'lib',
                oid: 'tree-oid',
                kind: CodeEntryKind.directory,
                mode: 16384,
                size: 0,
              ),
              repoRef: const RepoRef(owner: 'octocat', name: 'hello-world'),
              branch: 'main',
              showLastCommit: false,
              showMetadata: false,
              onDirectoryTap: (final CodeTreeNode _) {},
              onFileTap: (final CodeTreeNode _) {},
              onSubmoduleTap: (final CodeTreeNode _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder target = find.byType(InkWell);
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });
}
