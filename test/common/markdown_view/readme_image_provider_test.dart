import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/common/markdown_view/providers/markdown_image_providers.dart';
import 'package:diohub/common/markdown_view/readme_image_classifier.dart';
import 'package:diohub/common/markdown_view/readme_image_resource.dart';
import 'package:diohub/common/markdown_view/widgets/readme_image_view.dart';
import 'package:diohub/common/resource_runtime/resource_runtime.dart';
import 'package:diohub/l10n/app_localizations.dart';
import 'package:diohub/providers/database_providers.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/view/repository/md3/repository_tab_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../resource_runtime/resource_runtime_test_support.dart';

const String _imageUrl = 'https://camo.githubusercontent.com/test-image';
const ResourceScope _scope = ResourceScope(
  serverId: 'github.com',
  principal: 'account-1',
);

void main() {
  test(
    'network failure becomes one retained optional-content result',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        worker: const InlineResourceWorker(),
      );
      final _QueueImageClassifier classifier = _QueueImageClassifier(<Object>[
        DioException(
          requestOptions: RequestOptions(path: _imageUrl),
          type: DioExceptionType.connectionTimeout,
        ),
      ]);
      final ProviderContainer container = _container(
        runtime: runtime,
        classifier: classifier,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });

      final AsyncNotifierProvider<ReadmeImageResultNotifier, ReadmeImageResult>
      provider = readmeImageResultProvider(_imageUrl);
      final ProviderSubscription<AsyncValue<ReadmeImageResult>> subscription =
          container.listen(provider, (final _, final _) {});
      final ReadmeImageResult first = await container.read(provider.future);
      subscription.close();
      await Future<void>.delayed(Duration.zero);
      final ReadmeImageResult cached = await container.read(provider.future);

      expect(first.kind, ReadmeImageKind.unavailable);
      expect(cached.kind, ReadmeImageKind.unavailable);
      expect(classifier.fetchCalls, 1);
    },
  );

  test(
    'explicit retry invalidates source and rebuilds classification',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        worker: const InlineResourceWorker(),
      );
      final _QueueImageClassifier classifier = _QueueImageClassifier(<Object>[
        DioException(
          requestOptions: RequestOptions(path: _imageUrl),
          type: DioExceptionType.connectionTimeout,
        ),
        ReadmeImageSource(
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
          contentType: 'image/png',
        ),
      ]);
      final ProviderContainer container = _container(
        runtime: runtime,
        classifier: classifier,
      );
      addTearDown(() {
        container.dispose();
        runtime.dispose();
      });
      final AsyncNotifierProvider<ReadmeImageResultNotifier, ReadmeImageResult>
      provider = readmeImageResultProvider(_imageUrl);
      final ProviderSubscription<AsyncValue<ReadmeImageResult>> subscription =
          container.listen(provider, (final _, final _) {});
      addTearDown(subscription.close);
      expect(
        (await container.read(provider.future)).kind,
        ReadmeImageKind.unavailable,
      );

      await container.read(provider.notifier).refreshResource();
      final ReadmeImageResult refreshed = container.read(provider).requireValue;

      expect(refreshed.kind, ReadmeImageKind.raster);
      expect(classifier.fetchCalls, 2);
    },
  );

  test('asset client enforces streamed size and removes credentials', () async {
    final _RecordingAdapter adapter = _RecordingAdapter(
      ResponseBody(
        Stream<Uint8List>.fromIterable(<Uint8List>[
          Uint8List.fromList(<int>[1, 2, 3]),
          Uint8List.fromList(<int>[4, 5, 6]),
        ]),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['image/png'],
        },
      ),
    );
    final Dio dio = Dio(
      BaseOptions(
        headers: <String, dynamic>{
          'authorization': 'Bearer secret',
          'cookie': 'session=secret',
        },
      ),
    )..httpClientAdapter = adapter;
    final ReadmeImageClassifier classifier = ReadmeImageClassifier(
      dio,
      maxBytes: 4,
    );

    await expectLater(
      classifier.fetch(_imageUrl),
      throwsA(isA<ReadmeImageTooLarge>()),
    );

    expect(adapter.request?.headers['authorization'], isNull);
    expect(adapter.request?.headers['cookie'], isNull);
    expect(adapter.request?.headers['proxy-authorization'], isNull);
  });

  test(
    'SVG classification result crosses the production worker isolate',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      final ReadmeImageResourceSpecs specs = readmeImageResourceSpecs(
        url: _imageUrl,
        scope: _scope,
        classifier: _QueueImageClassifier(<Object>[
          ReadmeImageSource(
            bytes: Uint8List.fromList(utf8.encode('<svg></svg>')),
            contentType: 'image/svg+xml',
          ),
        ]),
      );

      final ResourceData<ReadmeImageResult> data = await waitForData(
        runtime.acquire(specs.artifact),
      );

      expect(data.data.kind, ReadmeImageKind.svg);
      expect(data.data.svgString, '<svg></svg>');
    },
  );

  test(
    'raster classification keeps one source byte buffer across the worker',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime();
      addTearDown(runtime.dispose);
      final Uint8List bytes = Uint8List.fromList(<int>[137, 80, 78, 71]);
      final ReadmeImageResourceSpecs specs = readmeImageResourceSpecs(
        url: _imageUrl,
        scope: _scope,
        classifier: _QueueImageClassifier(<Object>[
          ReadmeImageSource(bytes: bytes, contentType: 'image/png'),
        ]),
      );

      final ResourceLease<ReadmeImageSource?> sourceLease = runtime.acquire(
        specs.source,
      );
      final ResourceData<ReadmeImageSource?> sourceData = await waitForData(
        sourceLease,
      );
      final ResourceLease<ReadmeImageResult> artifactLease = runtime.acquire(
        specs.artifact,
      );
      final ResourceData<ReadmeImageResult> artifactData = await waitForData(
        artifactLease,
      );

      expect(artifactData.data.kind, ReadmeImageKind.raster);
      expect(
        identical(sourceData.data!.bytes, artifactData.data.bytes),
        isTrue,
      );
      artifactLease.release();
      sourceLease.release();
    },
  );

  test('default cache retains one legal maximum raster chain', () async {
    expect(
      const ResourceCacheConfig().maxEstimatedWeight,
      greaterThanOrEqualTo(readmeImageMaxRasterDependencyChainWeight),
    );
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
      worker: const InlineResourceWorker(),
    );
    addTearDown(runtime.dispose);
    final Uint8List bytes = Uint8List(kMaxReadmeImageBytes);
    final _QueueImageClassifier classifier = _QueueImageClassifier(<Object>[
      ReadmeImageSource(bytes: bytes, contentType: 'image/png'),
    ]);
    final ReadmeImageResourceSpecs specs = readmeImageResourceSpecs(
      url: _imageUrl,
      scope: _scope,
      classifier: classifier,
    );

    final ResourceLease<ReadmeImageResult> artifactLease = runtime.acquire(
      specs.artifact,
    );
    final ResourceData<ReadmeImageResult> artifactData = await waitForData(
      artifactLease,
    );
    final ResourceLease<ReadmeImageResult> duplicate = runtime.acquire(
      specs.artifact,
    );
    final ResourceData<ReadmeImageResult> duplicateData = await waitForData(
      duplicate,
    );
    final ResourceLease<ReadmeImageSource?> sourceLease = runtime.acquire(
      specs.source,
    );
    final ResourceData<ReadmeImageSource?> sourceData = await waitForData(
      sourceLease,
    );

    expect(classifier.fetchCalls, 1);
    expect(runtime.telemetry.stats.overWeightBudget, isFalse);
    expect(
      runtime.telemetry.stats.estimatedWeight,
      readmeImageMaxRasterDependencyChainWeight,
    );
    expect(identical(sourceData.data!.bytes, artifactData.data.bytes), isTrue);
    expect(
      identical(artifactData.data.bytes, duplicateData.data.bytes),
      isTrue,
    );

    sourceLease.release();
    duplicate.release();
    artifactLease.release();
  });

  test(
    'same account is single-flight while account scopes stay isolated',
    () async {
      final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
        worker: const InlineResourceWorker(),
      );
      addTearDown(runtime.dispose);
      final _QueueImageClassifier classifier = _QueueImageClassifier(<Object>[
        ReadmeImageSource(
          bytes: Uint8List.fromList(<int>[1]),
          contentType: 'image/png',
        ),
        ReadmeImageSource(
          bytes: Uint8List.fromList(<int>[2]),
          contentType: 'image/png',
        ),
      ]);
      final ReadmeImageResourceSpecs firstScope = readmeImageResourceSpecs(
        url: _imageUrl,
        scope: _scope,
        classifier: classifier,
      );
      const ResourceScope secondScope = ResourceScope(
        serverId: 'github.com',
        principal: 'account-2',
      );
      final ReadmeImageResourceSpecs otherScope = readmeImageResourceSpecs(
        url: _imageUrl,
        scope: secondScope,
        classifier: classifier,
      );

      final ResourceLease<ReadmeImageResult> first = runtime.acquire(
        firstScope.artifact,
      );
      final ResourceLease<ReadmeImageResult> duplicate = runtime.acquire(
        firstScope.artifact,
      );
      final ResourceLease<ReadmeImageResult> other = runtime.acquire(
        otherScope.artifact,
      );
      await Future.wait(<Future<ResourceData<ReadmeImageResult>>>[
        waitForData(first),
        waitForData(duplicate),
        waitForData(other),
      ]);

      expect(classifier.fetchCalls, 2);
    },
  );

  test('account change cannot publish an obsolete in-flight image', () async {
    final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
      worker: const InlineResourceWorker(),
    );
    final Completer<ReadmeImageSource> delayed = Completer<ReadmeImageSource>();
    final _QueueImageClassifier classifier = _QueueImageClassifier(<Object>[
      delayed.future,
      ReadmeImageSource(
        bytes: Uint8List.fromList(<int>[2]),
        contentType: 'image/png',
      ),
    ]);
    const ResourceScope secondScope = ResourceScope(
      serverId: 'github.com',
      principal: 'account-2',
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        activeResourceScopeProvider.overrideWithValue(_scope),
        resourceRuntimeProvider.overrideWithValue(runtime),
        readmeImageClassifierProvider.overrideWithValue(classifier),
      ],
    );
    addTearDown(() {
      container.dispose();
      runtime.dispose();
    });
    final AsyncNotifierProvider<ReadmeImageResultNotifier, ReadmeImageResult>
    provider = readmeImageResultProvider(_imageUrl);
    final ProviderSubscription<AsyncValue<ReadmeImageResult>> subscription =
        container.listen(provider, (final _, final _) {});
    addTearDown(subscription.close);
    final Future<ReadmeImageResult> obsolete = container.read(provider.future);
    await _waitUntil(() => classifier.fetchCalls == 1);
    expect(classifier.fetchCalls, 1);

    container.updateOverrides(<Override>[
      activeResourceScopeProvider.overrideWithValue(secondScope),
      resourceRuntimeProvider.overrideWithValue(runtime),
      readmeImageClassifierProvider.overrideWithValue(classifier),
    ]);
    await container.pump();
    final ReadmeImageResult current = await container.read(provider.future);

    delayed.complete(
      ReadmeImageSource(
        bytes: Uint8List.fromList(<int>[1]),
        contentType: 'image/png',
      ),
    );
    await obsolete;
    await container.pump();

    expect(current.bytes, Uint8List.fromList(<int>[2]));
    expect(container.read(provider).requireValue.bytes, current.bytes);
    expect(classifier.fetchCalls, 2);
  });

  testWidgets('raster result renders the already downloaded bytes', (
    final WidgetTester tester,
  ) async {
    final Uint8List bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4'
      'nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
    );

    await _pumpImage(
      tester,
      _QueueImageClassifier(<Object>[
        ReadmeImageSource(bytes: bytes, contentType: 'image/png'),
      ]),
    );
    await tester.pumpAndSettle();

    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).imageProvider, isA<MemoryImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('optional image failure is retryable without failing README', (
    final WidgetTester tester,
  ) async {
    await _pumpImage(
      tester,
      _QueueImageClassifier(<Object>[
        DioException(
          requestOptions: RequestOptions(path: _imageUrl),
          type: DioExceptionType.connectionTimeout,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('readme-image-retry')),
      findsOneWidget,
    );
    expect(find.byType(ReadmeImageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late raster decode stays stable while retained Repository tab changes',
    (final WidgetTester tester) async {
      final Completer<ReadmeImageResult> delayed =
          Completer<ReadmeImageResult>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            settingsCacheProvider.overrideWithValue(
              SettingsCache(<String, String>{}),
            ),
            readmeImageResultProvider.overrideWithBuild(
              (final Ref ref, final ReadmeImageResultNotifier notifier) =>
                  delayed.future,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(useMaterial3: true),
            home: const Scaffold(body: _RetainedReadmeTabHarness()),
          ),
        ),
      );
      await tester.pump();

      final _RetainedReadmeTabHarnessState state = tester.state(
        find.byType(_RetainedReadmeTabHarness),
      );
      state.showActions();
      await tester.pump(const Duration(milliseconds: 20));
      delayed.complete(
        ReadmeImageResult.raster(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4'
            'nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=',
          ),
        ),
      );

      for (int frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
        expect(tester.takeException(), isNull);
      }
      await tester.pumpAndSettle();
      expect(find.text('Actions'), findsOneWidget);
      expect(
        find.byType(Image, skipOffstage: false),
        findsNothing,
        reason: 'A retained hidden tab must not decode a late README image.',
      );

      state.showCode();
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _waitUntil(final bool Function() predicate) async {
  for (int attempt = 0; attempt < 100; attempt++) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Condition was not reached');
}

ProviderContainer _container({
  required final ResourceRuntime runtime,
  required final ReadmeImageClassifier classifier,
}) => ProviderContainer(
  overrides: <Override>[
    activeResourceScopeProvider.overrideWithValue(_scope),
    resourceRuntimeProvider.overrideWithValue(runtime),
    readmeImageClassifierProvider.overrideWithValue(classifier),
  ],
);

Future<void> _pumpImage(
  final WidgetTester tester,
  final ReadmeImageClassifier classifier,
) async {
  final InMemoryResourceRuntime runtime = InMemoryResourceRuntime(
    worker: const InlineResourceWorker(),
  );
  addTearDown(runtime.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        settingsCacheProvider.overrideWithValue(
          SettingsCache(<String, String>{}),
        ),
        activeResourceScopeProvider.overrideWithValue(_scope),
        resourceRuntimeProvider.overrideWithValue(runtime),
        readmeImageClassifierProvider.overrideWithValue(classifier),
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

final class _QueueImageClassifier extends ReadmeImageClassifier {
  _QueueImageClassifier(this.results) : super(Dio());

  final List<Object> results;
  int fetchCalls = 0;

  @override
  Future<ReadmeImageSource> fetch(final String url) async {
    final Object result = results[fetchCalls++];
    if (result is Future<ReadmeImageSource>) {
      return result;
    }
    if (result is ReadmeImageSource) {
      return result;
    }
    if (result is Exception) {
      throw result;
    }
    if (result is Error) {
      throw result;
    }
    throw StateError('Unsupported fake image result: $result');
  }
}

final class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.response);

  final ResponseBody response;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    final RequestOptions options,
    final Stream<Uint8List>? requestStream,
    final Future<void>? cancelFuture,
  ) async {
    request = options;
    return response;
  }

  @override
  void close({final bool force = false}) {}
}

class _RetainedReadmeTabHarness extends StatefulWidget {
  const _RetainedReadmeTabHarness();

  @override
  State<_RetainedReadmeTabHarness> createState() =>
      _RetainedReadmeTabHarnessState();
}

class _RetainedReadmeTabHarnessState extends State<_RetainedReadmeTabHarness>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  int _index = 0;

  void showActions() {
    setState(() => _index = 1);
    unawaited(_controller.forward(from: 0));
  }

  void showCode() {
    setState(() => _index = 0);
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => RepositoryRetainedTabTransition(
    animation: _controller,
    direction: 1,
    child: IndexedStack(
      index: _index,
      sizing: StackFit.expand,
      children: <Widget>[
        TickerMode(
          enabled: _index == 0,
          child: const CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: ReadmeImageView(url: _imageUrl, height: 300),
                ),
              ),
            ],
          ),
        ),
        TickerMode(
          enabled: _index == 1,
          child: const Center(child: Text('Actions')),
        ),
      ],
    ),
  );
}
