import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/repository/repository_providers.dart';
import 'package:diohub/view/repository/compare_view_screen.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/repository/compare_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const RepoRef _repoRef = RepoRef(owner: 'octocat', name: 'hello-world');
const CompareResult _result = CompareResult(
  status: 'ahead',
  aheadBy: 1,
  behindBy: 0,
  totalCommits: 1,
  commits: <CompareCommitSummary>[],
  files: <CompareFile>[
    CompareFile(
      filename: 'lib/new_file.dart',
      status: 'added',
      additions: 3,
      deletions: 1,
      changes: 4,
    ),
  ],
);

void main() {
  for (final Brightness brightness in Brightness.values) {
    testWidgets(
      'compare file status is readable and semantic in ${brightness.name}',
      (final WidgetTester tester) async {
        final ColorScheme colorScheme = ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: brightness,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              settingsCacheProvider.overrideWithValue(
                SettingsCache(<String, String>{}),
              ),
              compareResultProvider.overrideWith(
                (final Ref ref, final args) async => _result,
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(useMaterial3: true, colorScheme: colorScheme),
              home: const CompareViewScreen(
                repoRef: _repoRef,
                base: 'main',
                head: 'feature',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Files'));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Added'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (final Widget widget) =>
                widget is Semantics &&
                widget.properties.label == 'Added' &&
                widget.properties.image == true,
          ),
          findsOneWidget,
        );
        final Text changes = tester.widget<Text>(find.text('+3 -1'));
        expect(changes.style?.color, colorScheme.onSurface);
        final Text filename = tester.widget<Text>(
          find.text('lib/new_file.dart'),
        );
        expect(filename.style?.fontSize, 13);
        expect(filename.style?.height, closeTo(20 / 13, 0.0001));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('compare file status label follows the selected locale', (
    final WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          settingsCacheProvider.overrideWithValue(
            SettingsCache(<String, String>{}),
          ),
          compareResultProvider.overrideWith(
            (final Ref ref, final args) async => _result,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CompareViewScreen(
            repoRef: _repoRef,
            base: 'main',
            head: 'feature',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('文件'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('已添加'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final ({Size size, TextScaler textScaler}) scenario
      in <({Size size, TextScaler textScaler})>[
        (size: const Size(360, 800), textScaler: const TextScaler.linear(2)),
        (size: const Size(800, 900), textScaler: const TextScaler.linear(1.3)),
        (size: const Size(1440, 900), textScaler: TextScaler.noScaling),
      ]) {
    testWidgets(
      'compare layout stays overflow-free at ${scenario.size.width}px',
      (final WidgetTester tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = scenario.size;
        addTearDown(() {
          tester.view
            ..resetDevicePixelRatio()
            ..resetPhysicalSize();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              settingsCacheProvider.overrideWithValue(
                SettingsCache(<String, String>{}),
              ),
              compareResultProvider.overrideWith(
                (final Ref ref, final args) async => _result,
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (final BuildContext context, final Widget? child) =>
                  MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: scenario.textScaler),
                    child: child!,
                  ),
              home: const CompareViewScreen(
                repoRef: _repoRef,
                base: 'main',
                head: 'feature',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Compare'), findsOneWidget);
        expect(find.text('Commits'), findsOneWidget);
        expect(find.text('Files'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
