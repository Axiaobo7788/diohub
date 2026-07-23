import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/code/app_code_editor.dart';
import 'package:diohub/common/markdown_view/extensions/markdown_extensions.dart';
import 'package:diohub/common/misc/code_block_view.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/server_config_provider.dart';
import 'package:diohub/view/repository/readme/repository_readme.dart';
import 'package:diohub_models/models/server_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_tools/sliver_tools.dart';

String _headingHeavyReadme() {
  final StringBuffer html = StringBuffer('''
<article class="markdown-body">
  <div class="markdown-heading"><h1>DioHub</h1></div>
  <p>A native GitHub client.</p>
''');
  // The real DioHub README currently has 36 headings. Match that scale and
  // hierarchy so the test guards the repository layout that triggered the
  // RenderSliverStickyHeader geometry cascade.
  for (int section = 0; section < 7; section++) {
    html.write('<div class="markdown-heading"><h2>Section $section</h2></div>');
    for (int topic = 0; topic < 4; topic++) {
      html
        ..write(
          '<div class="markdown-heading"><h3>Topic $section.$topic</h3></div>',
        )
        ..write(
          '<p>Browse repositories, branches, commits, files, issues, and '
          'pull requests from the same application.</p>',
        )
        ..write(
          '<div class="highlight highlight-source-dart"><pre> '
          'final section$section$topic = List.generate(40, (index) =&gt; index); '
          '</pre></div>',
        );
    }
  }
  html.write('</article>');
  return html.toString();
}

void main() {
  final String renderedReadme = _headingHeavyReadme();

  testWidgets('lays out a heading-heavy repository README while scrolling', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 600);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            settingsCacheProvider.overrideWithValue(
              SettingsCache(<String, String>{}),
            ),
            activeServerConfigProvider.overrideWithValue(
              ServerConfig.gitHubDotCom,
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  RepositoryReadmeSliver(
                    readmeAsync: AsyncData<String?>(renderedReadme),
                    branch: 'develop',
                    repoFullName: 'Axiaobo7788/diohub',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverStickyHeader), findsNothing);
      expect(find.byType(MultiSliver), findsNothing);
      expect(find.byType(SliverList), findsOneWidget);
      expect(find.byType(AppCodeEditor), findsNothing);
      expect(find.byType(CodeBlockView), findsWidgets);
      expect(
        find.byType(CodeBlockView).evaluate().length,
        lessThan(28),
        reason: 'README sections outside the cache extent must stay unbuilt',
      );
      expect(tester.takeException(), isNull);

      tester
          .state<RepositoryReadmeState>(find.byType(RepositoryReadmeSliver))
          .scrollToAnchor('topic-63');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      for (int index = 0; index < 5; index++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('static markdown code lays out inside an unbounded sliver', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(360, 640);
    addTearDown(() {
      tester.view
        ..resetDevicePixelRatio()
        ..resetPhysicalSize();
    });

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            settingsCacheProvider.overrideWithValue(
              SettingsCache(<String, String>{}),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: CodeView(
                      'final values = <int>[1, 2, 3, 4, 5, 6, 7, 8];',
                      language: 'dart',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CodeBlockView), findsOneWidget);
      expect(find.byType(AppCodeEditor), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
