import 'package:diohub/view/issues_pulls/widgets/suggested_reviewers_section.dart';
import 'package:diohub/view/issues_pulls/widgets/timeline_chips.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'suggested reviewer is one selected 48px keyboard-activatable target',
    (final WidgetTester tester) async {
      int toggleCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: SuggestedReviewersSection(
              suggested: const <SuggestedReviewerData>[
                SuggestedReviewerData(
                  id: 'reviewer-1',
                  login: 'octocat',
                  avatarUrl: '',
                  name: 'Octocat',
                ),
              ],
              selectedNodeIds: const <String>{'reviewer-1'},
              onToggle: (final String _) => toggleCalls += 1,
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder target = find.byKey(
        const ValueKey<String>('suggested-reviewer-reviewer-1'),
      );
      expect(target, findsOneWidget);
      expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
      expect(
        find.byWidgetPredicate(
          (final Widget widget) =>
              widget is Semantics &&
              widget.properties.label == 'Octocat' &&
              widget.properties.selected == true,
        ),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(toggleCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('interactive commit chip keeps both actions in a 48px target', (
    final WidgetTester tester,
  ) async {
    const String oid = '0123456789abcdef';
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveCommitChip(
                abbreviatedOid: '0123456',
                fullOid: oid,
                repoRef: RepoRef(owner: 'octocat', name: 'hello-world'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder target = find.byKey(
      const ValueKey<String>('interactive-commit-chip-$oid'),
    );
    expect(target, findsOneWidget);
    expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    final InkWell inkWell = tester.widget<InkWell>(target);
    expect(inkWell.canRequestFocus, isTrue);
    expect(inkWell.onTap, isNotNull);
    expect(inkWell.onLongPress, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final Brightness brightness in Brightness.values) {
    testWidgets('timeline status text uses onSurface in ${brightness.name}', (
      final WidgetTester tester,
    ) async {
      final ColorScheme colorScheme = ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, colorScheme: colorScheme),
          home: const Scaffold(
            body: Column(
              children: <Widget>[
                AdditionsDeletionsText(additions: 3, deletions: 1),
                ClosesTargetBadge(),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder changes = find.byWidgetPredicate(
        (final Widget widget) =>
            widget is Text && widget.textSpan?.toPlainText() == '+3 / -1',
      );
      expect(changes, findsOneWidget);
      expect(
        tester.widget<Text>(changes).textSpan?.style?.color,
        colorScheme.onSurface,
      );
      expect(
        tester.widget<Text>(find.text('Closes this')).style?.color,
        colorScheme.onSurface,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
