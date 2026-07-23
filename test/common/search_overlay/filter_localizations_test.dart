import 'package:diohub/common/search_overlay/filter_localizations.dart';
import 'package:diohub/common/search_overlay/filter_section_def.dart';
import 'package:diohub/common/search_overlay/search_filter_sheet.dart';
import 'package:diohub/common/search_overlay/search_type.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/search/search_scope.dart';
import 'package:diohub/providers/search/search_state_notifier.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RepoRef repo = RepoRef(owner: 'octocat', name: 'hello-world');

  test('repository issue and pull-request status options stay distinct', () {
    const SearchScope issues = SearchScope.repoIssues(repo: repo);
    const SearchScope pulls = SearchScope.repoPulls(repo: repo);

    final StaticFilterSection issueStatus =
        issues
                .promotedSections(SearchType.issuesPulls)
                .firstWhere(
                  (FilterSectionDef section) => section.id == 'status',
                )
            as StaticFilterSection;
    final StaticFilterSection pullStatus =
        pulls
                .promotedSections(SearchType.issuesPulls)
                .firstWhere(
                  (FilterSectionDef section) => section.id == 'status',
                )
            as StaticFilterSection;

    expect(issueStatus.options.keys, <String>['open', 'closed']);
    expect(pullStatus.options.keys, <String>['open', 'closed', 'merged']);
  });

  testWidgets(
    'repository filter metadata is localized without translating user values',
    (WidgetTester tester) async {
      const List<FilterSectionDef> sections = <FilterSectionDef>[
        StaticFilterSection(
          id: 'status',
          displayName: 'Status',
          icon: Icons.filter_alt,
          options: <String, String>{},
        ),
        UserSearchFilterSection(
          id: 'assignee',
          displayName: 'Assignee',
          icon: Icons.person,
        ),
        TextFilterSection(id: 'label', displayName: 'Label', icon: Icons.label),
        TextFilterSection(
          id: 'milestone',
          displayName: 'Milestone',
          icon: Icons.flag,
        ),
        UserSearchFilterSection(
          id: 'author',
          displayName: 'Author',
          icon: Icons.person,
        ),
        TextFilterSection(
          id: 'base',
          displayName: 'Base branch',
          icon: Icons.fork_left,
        ),
        TextFilterSection(
          id: 'head',
          displayName: 'Head branch',
          icon: Icons.fork_right,
        ),
        DateFilterSection(
          id: 'created',
          displayName: 'Created',
          icon: Icons.calendar_today,
        ),
        DateFilterSection(
          id: 'updated',
          displayName: 'Updated',
          icon: Icons.calendar_today,
        ),
        NumberFilterSection(
          id: 'comments',
          displayName: 'Comments',
          icon: Icons.comment,
        ),
        NumberFilterSection(
          id: 'reactions',
          displayName: 'Reactions',
          icon: Icons.emoji_emotions,
        ),
        NumberFilterSection(
          id: 'interactions',
          displayName: 'Interactions',
          icon: Icons.touch_app,
        ),
        StaticFilterSection(
          id: 'draft',
          displayName: 'Draft',
          icon: Icons.edit,
          options: <String, String>{},
        ),
        StaticFilterSection(
          id: 'review',
          displayName: 'Review status',
          icon: Icons.rate_review,
          options: <String, String>{},
        ),
        UserSearchFilterSection(
          id: 'reviewed-by',
          displayName: 'Reviewed by',
          icon: Icons.person,
        ),
        UserSearchFilterSection(
          id: 'review-requested',
          displayName: 'Review requested',
          icon: Icons.person,
        ),
        UserSearchFilterSection(
          id: 'team-requested',
          displayName: 'Team requested',
          icon: Icons.groups,
        ),
        StaticFilterSection(
          id: 'linked',
          displayName: 'Linked',
          icon: Icons.link,
          options: <String, String>{},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedApplicationLocales,
          home: Builder(
            builder: (BuildContext context) => SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  for (final FilterSectionDef section in sections)
                    Text(localizedFilterSectionName(context, section)),
                  Text(localizedFilterSearchHint(context, sections[2])),
                  Text(localizedFilterSearchHint(context, sections[1])),
                  Text(
                    localizedFilterOptionLabel(
                      context,
                      sections.first,
                      'open',
                      'Open',
                    ),
                  ),
                  Text(
                    localizedFilterOptionLabel(
                      context,
                      sections[13],
                      'approved',
                      'Approved',
                    ),
                  ),
                  Text(
                    localizedFilterOptionLabel(
                      context,
                      const StaticFilterSection(
                        id: 'custom',
                        displayName: 'Custom',
                        icon: Icons.tune,
                        options: <String, String>{},
                      ),
                      'release/v1',
                      'release/v1',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      for (final String text in <String>[
        '状态',
        '受理人',
        '标签',
        '里程碑',
        '作者',
        '基准分支',
        '源分支',
        '创建时间',
        '更新时间',
        '评论',
        '反应',
        '互动',
        '草稿',
        '审查状态',
        '审查人',
        '已请求审查',
        '已请求团队审查',
        '关联议题',
        '搜索标签……',
        '搜索受理人……',
        '开启',
        '已批准',
        'release/v1',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
    },
  );

  testWidgets('custom clear-all callback overrides the legacy clear action', (
    WidgetTester tester,
  ) async {
    const SearchScope scope = SearchScope.repoIssues(repo: repo);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        currentUserProvider.overrideWithBuild((_, __) async => null),
      ],
    );
    addTearDown(container.dispose);
    int clearCalls = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedApplicationLocales,
          home: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    ref
                        .read(searchStateNotifierProvider(scope).notifier)
                        .setRawFreeText('keep me');
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext sheetContext) => Consumer(
                        builder:
                            (
                              BuildContext context,
                              WidgetRef ref,
                              Widget? child,
                            ) => SearchFilterSheet.buildHeader(
                              context,
                              scope,
                              ref,
                              onClearAll: () => clearCalls += 1,
                            ),
                      ),
                    );
                  },
                  child: const Text('Open filters'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(clearCalls, 1);
    expect(
      container.read(searchStateNotifierProvider(scope)).freeText,
      'keep me',
    );
    expect(find.text('Clear all'), findsNothing);
  });

  testWidgets('clear-all keeps the legacy notifier reset without a callback', (
    WidgetTester tester,
  ) async {
    const SearchScope scope = SearchScope.repoIssues(repo: repo);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        currentUserProvider.overrideWithBuild((_, __) async => null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedApplicationLocales,
          home: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    ref
                        .read(searchStateNotifierProvider(scope).notifier)
                        .setRawFreeText('clear me');
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext sheetContext) => Consumer(
                        builder:
                            (
                              BuildContext context,
                              WidgetRef ref,
                              Widget? child,
                            ) => SearchFilterSheet.buildHeader(
                              context,
                              scope,
                              ref,
                            ),
                      ),
                    );
                  },
                  child: const Text('Open filters'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();

    expect(
      container.read(searchStateNotifierProvider(scope)).freeText,
      isEmpty,
    );
  });
}
