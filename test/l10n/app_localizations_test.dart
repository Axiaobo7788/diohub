import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/utils/events/event_texts.dart';
import 'package:diohub_models/models/events/events_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('generated localizations expose English and Simplified Chinese', (
    final WidgetTester tester,
  ) async {
    await _pumpLocalizedText(tester, const Locale('en'));
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('This directory is empty'), findsOneWidget);
    expect(
      find.text(
        "GitHub's unsigned API limit has been reached. "
        'Sign in for a higher limit or try again later.',
      ),
      findsOneWidget,
    );

    await _pumpLocalizedText(
      tester,
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('当前目录为空'), findsOneWidget);
    expect(
      find.text('已达到 GitHub 未登录 API 的请求限额。请登录以提高限额，或稍后重试。'),
      findsOneWidget,
    );
  });

  test('application locales expose only English and Simplified Chinese', () {
    expect(supportedApplicationLocales, <Locale>[
      const Locale('en'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    ]);
  });

  test(
    'Traditional Chinese does not silently resolve to Simplified Chinese',
    () {
      expect(
        resolveApplicationLocale(const <Locale>[
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ], supportedApplicationLocales),
        const Locale('en'),
      );
      expect(
        resolveApplicationLocale(const <Locale>[
          Locale('zh'),
        ], supportedApplicationLocales),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      );
    },
  );

  test('event text bridge uses generated locale messages', () {
    final AppLocalizations zh = lookupAppLocalizations(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    );

    expect(
      EventTexts.localizedPush(l10n: zh, commits: 3, branches: 1),
      '推送了 3 个提交',
    );
    expect(
      EventTexts.localizedStateChange(
        l10n: zh,
        verb: PayloadAction.merged,
        noun: 'pull request',
        count: 2,
      ),
      '合并了 2 个拉取请求',
    );
  });
}

Future<void> _pumpLocalizedText(
  final WidgetTester tester,
  final Locale locale,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedApplicationLocales,
      localeListResolutionCallback: resolveApplicationLocale,
      home: Builder(
        builder: (final BuildContext context) => Scaffold(
          body: Column(
            children: <Widget>[
              Text(context.l10n.languageSystem),
              Text(context.l10n.repoDirectoryEmpty),
              Text(context.l10n.publicGitHubRateLimitReached),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
