import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/markdown_view/providers/markdown_image_providers.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:diohub/common/markdown_view/widgets/readme_image_view.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const String _imageUrl = 'https://camo.githubusercontent.com/test-image';

void main() {
  test('network failure becomes cached optional-content state', () async {
    final _CountingImageClassifier classifier = _CountingImageClassifier(
      error: DioException(
        requestOptions: RequestOptions(path: _imageUrl),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        readmeImageClassifierProvider.overrideWithValue(classifier),
      ],
    );
    addTearDown(container.dispose);

    final ProviderSubscription<AsyncValue<ReadmeImageResult>> subscription =
        container.listen<AsyncValue<ReadmeImageResult>>(
          readmeImageResultProvider(_imageUrl),
          (final _, final _) {},
          fireImmediately: true,
        );
    final ReadmeImageResult first = await container.read(
      readmeImageResultProvider(_imageUrl).future,
    );
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    final ReadmeImageResult cached = await container.read(
      readmeImageResultProvider(_imageUrl).future,
    );

    expect(first.kind, ReadmeImageKind.unavailable);
    expect(cached.kind, ReadmeImageKind.unavailable);
    expect(classifier.loadCalls, 1);
    expect(
      container.read(readmeImageResultProvider(_imageUrl)),
      isA<AsyncData<ReadmeImageResult>>(),
    );
  });

  testWidgets('raster result renders the already downloaded bytes', (
    final WidgetTester tester,
  ) async {
    final ReadmeImageResult result = ReadmeImageResult.raster(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4'
        'nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
      ),
    );

    await _pumpImage(tester, result);
    await tester.pumpAndSettle();

    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).imageProvider, isA<MemoryImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('optional image failure is retryable without failing README', (
    final WidgetTester tester,
  ) async {
    await _pumpImage(tester, ReadmeImageResult.unavailable());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('readme-image-retry')),
      findsOneWidget,
    );
    expect(find.byType(ReadmeImageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpImage(
  final WidgetTester tester,
  final ReadmeImageResult result,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        settingsCacheProvider.overrideWithValue(
          SettingsCache(<String, String>{}),
        ),
        readmeImageResultProvider(
          _imageUrl,
        ).overrideWith((final Ref ref) async => result),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(body: ReadmeImageView(url: _imageUrl)),
      ),
    ),
  );
}

final class _CountingImageClassifier extends ReadmeImageClassifier {
  _CountingImageClassifier({required this.error}) : super(Dio());

  final Exception error;
  int loadCalls = 0;

  @override
  Future<ReadmeImageResult> load(final String url) async {
    loadCalls++;
    throw error;
  }
}
