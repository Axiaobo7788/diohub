import 'dart:async';
import 'dart:convert' show jsonDecode;

import 'package:auto_route/auto_route.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/app/app_error_observer.dart';
import 'package:diohub/providers/deep_link/sharing_intent_stream_provider.dart';
import 'package:diohub/providers/deep_link/uni_link_stream_provider.dart';
import 'package:diohub/adapters/internet_connectivity.dart'
    show internetConnectivityProvider;
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/common/notifications/notification_service.dart'
    show notificationServiceProvider;
import 'package:diohub/app/app_logger.dart';
import 'package:diohub/app/settings/settings_cache.dart';
import 'package:diohub/app/settings/error_tracking.dart';
import 'package:diohub/providers/database_providers.dart'
    show settingsCacheProvider;
import 'package:diohub/providers/router_provider.dart';
import 'package:diohub/providers/startup/app_startup_provider.dart';
import 'package:diohub/app/drift_log_observer.dart';
import 'package:diohub/app/talker.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:diohub/app/settings/appearance.dart';
import 'package:diohub/app/settings/glass_pill.dart';
import 'package:diohub/app/settings/spacing.dart';
import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/app/theme_config/models/flex_theme_settings_model.dart';
import 'package:diohub/app/theme_config/utils/flex_color_scheme_builder.dart';
import 'package:diohub/providers/logging/log_providers.dart';
import 'package:diohub/providers/watchers/watcher_manager_provider.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/settings/appearance_provider.dart';
import 'package:diohub/providers/settings/flex_theme_provider.dart';
import 'package:diohub/providers/settings/glass_pill_provider.dart';
import 'package:diohub/providers/settings/spacing_provider.dart';
import 'package:diohub/providers/settings/theme_mode_provider.dart';
import 'package:diohub/routes/router.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub_database/database/database.dart';
import 'package:diohub/utils/device_display_mode.dart';
import 'package:diohub/utils/material_you_support.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:diohub/app/sentry_config.dart';
import 'package:diohub/app/sentry_talker_observer.dart';
import 'package:diohub/flavors.dart';
import 'package:diohub_premium_api/diohub_premium_api.dart';

const String appFlavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');

/// Heuristic: treat as render/layout/sliver error so we escalate instead of absorbing.
bool _isRenderOrLayoutError(Object error) {
  final s = error.toString().toLowerCase();
  return s.contains('render') ||
      s.contains('layout') ||
      s.contains('sliver') ||
      s.contains('viewport');
}

void main() async {
  // debugPaintSizeEnabled = true;

  F.appFlavor = Flavor.values.firstWhere(
    (final Flavor element) => element.name == appFlavor,
  );

  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers -- catch anything that escapes all other handlers.
  FlutterError.onError = (final FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
      tag: 'FlutterError',
    );
    FlutterError.presentError(details);
    if (_isRenderOrLayoutError(details.exception)) {
      Zone.current.handleUncaughtError(
        details.exception,
        details.stack ?? StackTrace.current,
      );
    }
  };

  // When a widget throws during build, Flutter replaces it with ErrorWidget (a box).
  // Inside a Viewport we must return a Sliver or we get "expected RenderSliver but received RenderErrorBox".
  // Self-contained: no Theme, no provider, no context extensions (avoids infinite recursion when error is outside MaterialApp).
  ErrorWidget.builder = (final FlutterErrorDetails details) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (final BuildContext context) {
          final inViewport =
              context.findAncestorRenderObjectOfType<RenderViewport>() != null;
          final errorContent = Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: RichText(
                text: TextSpan(
                  text: details.exception.toString(),
                  style: const TextStyle(
                    color: Color(0xFFFF0000),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
          if (inViewport) return SliverToBoxAdapter(child: errorContent);
          return errorContent;
        },
      ),
    );
  };

  PlatformDispatcher.instance.onError =
      (final Object error, final StackTrace stack) {
        if (_isRenderOrLayoutError(error)) {
          return false; // Do not absorb; let error propagate.
        }
        AppLogger.error(
          'Unhandled platform error',
          error: error,
          stackTrace: stack,
          tag: 'PlatformError',
        );
        return true;
      };

  // Start heavy init; must complete before ProviderContainer so settings cache can be loaded.
  final Future<void> initFuture = Future.wait(<Future<void>>[
    BaseAPIHandler.setupDioAPICache(),
    AppDatabase.initialize(),
  ]);
  initFuture.then((final void _) {
    if (kDebugMode || const bool.fromEnvironment('ENABLE_LOG_DB')) {
      appTalker.configure(
        observer: DriftLogObserver(AppDatabase.instance.logDao),
      );
    }
  });
  unawaited(setHighRefreshRate());

  // DevTools info retrieval disabled

  await initFuture;

  final Map<String, String> rawSettings = await AppDatabase.instance.settingsDao
      .getAll();
  final settingsCache = SettingsCache(rawSettings);

  // Determine error tracking settings with enterprise-aware default
  ErrorTrackingSettings errorTracking;
  if (settingsCache.containsKey(errorTrackingDescriptor.key)) {
    // User has explicitly set preferences
    errorTracking = settingsCache.read(errorTrackingDescriptor);
  } else {
    // No persisted value: check if active account is enterprise
    final activeAccountKey = await AppDatabase.instance.appMetaDao
        .getActiveAccountKey();
    if (activeAccountKey != null) {
      final accounts = await AppDatabase.instance.accountsDao.getAll();
      final activeAccount = accounts.cast<AccountEntry?>().firstWhere(
        (final a) => a?.key == activeAccountKey,
        orElse: () => null,
      );
      if (activeAccount != null) {
        try {
          final serverConfigJson =
              jsonDecode(activeAccount.serverConfigJson)
                  as Map<String, dynamic>;
          final isGitHubDotCom = serverConfigJson['id'] == 'github.com';
          errorTracking = isGitHubDotCom
              ? errorTrackingDescriptor.defaultValue
              : const ErrorTrackingSettings.enterprise();
        } catch (e) {
          AppLogger.warning(
            'Server config parse failed',
            error: e,
            tag: 'main',
          );
          // Parse error: fall back to default
          errorTracking = errorTrackingDescriptor.defaultValue;
        }
      } else {
        errorTracking = errorTrackingDescriptor.defaultValue;
      }
    } else {
      errorTracking = errorTrackingDescriptor.defaultValue;
    }
  }

  // Store for use in RootApp navigatorObservers
  _errorTrackingSettings = errorTracking;

  // Configure BaseAPIHandler for Sentry HTTP tracking
  BaseAPIHandler.enableSentryHttpTracking = errorTracking.httpMetadata;

  final ProviderContainer container = ProviderContainer(
    overrides: [
      settingsCacheProvider.overrideWithValue(settingsCache),
      ...premiumOverrides(),
    ],
    observers: [
      AppErrorObserver(),
      if (kDebugMode && _enableProviderLogging)
        TalkerRiverpodObserver(
          talker: appTalker,
          settings: const TalkerRiverpodLoggerSettings(
            printProviderAdded: false,
            printProviderUpdated: false,
            printProviderDisposed: false,
          ),
        ),
    ],
  );
  // Start connectivity monitoring (instance provided and disposed via Riverpod).
  container.read(internetConnectivityProvider);

  await container.read(premiumLifecycleProvider).initialize(container);

  await initSentry(
    appRunner: () => runApp(
      SentryWidget(
        child: UncontrolledProviderScope(
          container: container,
          child: const Portal(child: RootApp()),
        ),
      ),
    ),
    tracking: errorTracking,
  );

  // Attach Sentry observer to Talker if crash reporting is enabled
  if (errorTracking.crashReports) {
    appTalker.configure(observer: SentryTalkerObserver());
  }

  // Post-frame: Handle cold-start deep link (non-blocking)
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    String? initLink;
    try {
      initLink = await initUniLink();
      if (initLink != null && initLink.isNotEmpty) {
        container.read(pendingDeepLinkProvider.notifier).state = Uri.parse(
          initLink,
        );
      }
    } on PlatformException catch (e) {
      AppLogger.warning('Cold-start deep link failed', error: e, tag: 'main');
    }
  });

  await getInitialSharedMedia(container);
}

/// Set to true to enable Riverpod provider logging in debug (e.g. flutter run --dart-define=ENABLE_PROVIDER_LOGS=true).
const bool _enableProviderLogging = bool.fromEnvironment(
  'ENABLE_PROVIDER_LOGS',
  defaultValue: false,
);

/// Error tracking settings determined at startup (before ProviderContainer).
/// Changes take effect on next app launch.
late final ErrorTrackingSettings _errorTrackingSettings;

/// Custom scroll behavior that uses BouncingScrollPhysics app-wide
class _BouncingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(final BuildContext context) =>
      const BouncingScrollPhysics();
}

class RootApp extends ConsumerStatefulWidget {
  const RootApp({super.key});

  @override
  ConsumerState<RootApp> createState() => _RootAppState();
}

class _RootAppState extends ConsumerState<RootApp> with WidgetsBindingObserver {
  late final AppRouter _router;
  late final AppNavigationObserver _navObserver;
  bool _initialized = false;

  ThemeData? _cachedLightTheme;
  ThemeData? _cachedDarkTheme;
  ThemeMode? _lastThemeMode;
  bool? _lastMaterialYouEnabled;
  FlexThemeSettingsModel? _lastFlexSettings;
  String? _lastFontFamily;
  SpacingSettings? _lastSpacingSettings;
  GlassPillSettings? _lastGlassPillSettings;
  bool? _lastUseDynamicColors;
  ColorScheme? _lastLightDynamic;
  ColorScheme? _lastDarkDynamic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final container = ProviderScope.containerOf(context);
      _router = AppRouter();
      _navObserver = AppNavigationObserver(container);
      ref.read(logPruneSchedulerProvider);
    }
  }

  @override
  void dispose() {
    _navObserver.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    try {
      final service = ref.read(watcherServiceProvider);
      switch (state) {
        case AppLifecycleState.resumed:
          service.resume();
        case AppLifecycleState.paused:
          // Only pause on actual backgrounding, not on inactive (which fires
          // frequently on iOS for system overlays, permission dialogs, etc.)
          service.pause();
        default:
          break;
      }
    } catch (e, st) {
      AppLogger.warning(
        'Lifecycle watcher failed (provider may be unavailable)',
        error: e,
        stackTrace: st,
        tag: 'main',
      );
    }
  }

  @override
  Widget build(final BuildContext context) => DynamicColorBuilder(
    builder: (final ColorScheme? lightDynamic, final ColorScheme? darkDynamic) {
      final bool supportsMaterialYou = MaterialYouSupport.isSupported(
        lightDynamic,
        darkDynamic,
      );

      // Only rebuild when root-theme-affecting fields change.
      final ThemeMode themeMode = ref.watch(
        themeModeProvider.select((final ThemeSettings s) => s.themeMode),
      );
      final bool materialYouEnabled = ref.watch(
        themeModeProvider.select(
          (final ThemeSettings s) => s.materialYouEnabled,
        ),
      );
      final FlexThemeSettingsModel flexSettings = ref.watch(flexThemeProvider);
      final String fontFamily = ref.watch(flexThemeProvider).fontFamily ?? '';
      final SpacingSettings spacingSettings = ref.watch(spacingProvider);
      final GlassPillSettings glassPillSettings = ref.watch(glassPillProvider);

      final bool useDynamicColors = materialYouEnabled && supportsMaterialYou;

      final bool needsThemeRebuild =
          themeMode != _lastThemeMode ||
          materialYouEnabled != _lastMaterialYouEnabled ||
          flexSettings != _lastFlexSettings ||
          fontFamily != _lastFontFamily ||
          spacingSettings != _lastSpacingSettings ||
          glassPillSettings != _lastGlassPillSettings ||
          useDynamicColors != _lastUseDynamicColors ||
          lightDynamic != _lastLightDynamic ||
          darkDynamic != _lastDarkDynamic;

      if (needsThemeRebuild) {
        _lastThemeMode = themeMode;
        _lastMaterialYouEnabled = materialYouEnabled;
        _lastFlexSettings = flexSettings;
        _lastFontFamily = fontFamily;
        _lastSpacingSettings = spacingSettings;
        _lastGlassPillSettings = glassPillSettings;
        _lastUseDynamicColors = useDynamicColors;
        _lastLightDynamic = lightDynamic;
        _lastDarkDynamic = darkDynamic;
        _cachedLightTheme = getTheme(
          context,
          brightness: Brightness.light,
          colorScheme: useDynamicColors ? lightDynamic : null,
          materialYouEnabled: materialYouEnabled,
          flexSettings: flexSettings,
          fontFamily: fontFamily,
          spacingSettings: spacingSettings,
          glassPillSettings: glassPillSettings,
        );
        _cachedDarkTheme = getTheme(
          context,
          brightness: Brightness.dark,
          colorScheme: useDynamicColors ? darkDynamic : null,
          materialYouEnabled: materialYouEnabled,
          flexSettings: flexSettings,
          fontFamily: fontFamily,
          spacingSettings: spacingSettings,
          glassPillSettings: glassPillSettings,
        );
      }

      final AppearanceSettings appearance = ref.watch(appearanceProvider);
      final bool disableAnimations = appearance.disableAnimations;

      return MaterialApp.router(
        builder: (final BuildContext context, final Widget? child) {
          return Consumer(
            builder: (final BuildContext ctx, final WidgetRef ref, final _) {
              ref.listen(uniLinkStreamProvider, (
                final _,
                final AsyncValue<Uri?> next,
              ) {
                next.whenData((final Uri? uri) {
                  if (uri == null) return;
                  final startup = ref.read(appStartupProvider);
                  final bool isReady =
                      startup.hasValue && startup.requireValue is StartupReady;
                  if (isReady && ctx.mounted) {
                    deepLinkNavigate(uri, ctx);
                  } else {
                    ref.read(pendingDeepLinkProvider.notifier).state = uri;
                  }
                });
              });
              ref.listen(sharingIntentStreamProvider, (
                final _,
                final AsyncValue<Uri?> next,
              ) {
                next.whenData((final Uri? uri) {
                  if (uri == null) return;
                  final startup = ref.read(appStartupProvider);
                  final bool isReady =
                      startup.hasValue && startup.requireValue is StartupReady;
                  if (isReady && ctx.mounted) {
                    deepLinkNavigate(uri, ctx);
                  } else {
                    ref.read(pendingDeepLinkProvider.notifier).state = uri;
                  }
                });
              });
              // Initialize download manager via premium lifecycle
              final premiumLifecycle = ref.read(premiumLifecycleProvider);
              premiumLifecycle.initializeDownloadManager(ref);

              return premiumLifecycle.cloudSyncObserverWrapper(
                Stack(
                  textDirection: TextDirection.ltr,
                  children: <Widget>[
                    MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(disableAnimations: disableAnimations),
                      child: ToastificationWrapper(child: child!),
                    ),
                  ],
                ),
              );
            },
          );
        },
        theme: _cachedLightTheme!,
        darkTheme: _cachedDarkTheme!,
        themeMode: themeMode,
        scrollBehavior: _BouncingScrollBehavior(),
        localizationsDelegates: const <LocalizationsDelegate>[
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        routerDelegate: _router.delegate(
          deepLinkBuilder: (final PlatformDeepLink _) =>
              DeepLink(<PageRouteInfo>[LandingLoadingRoute()]),
          navigatorObservers: () => <NavigatorObserver>[
            _navObserver,
            if (_errorTrackingSettings.navigationTracking)
              SentryNavigatorObserver(),
          ],
          rebuildStackOnDeepLink: true,
        ),
        routeInformationParser: _router.defaultRouteParser(),
      );
    },
  );
}

ThemeData getTheme(
  final BuildContext context, {
  required final Brightness brightness,
  required final ColorScheme? colorScheme,
  required final bool materialYouEnabled,
  required final FlexThemeSettingsModel flexSettings,
  required final String fontFamily,
  required final SpacingSettings spacingSettings,
  required final GlassPillSettings glassPillSettings,
}) {
  // Surface style with radii scaled by glass pill radius scale
  final SurfaceStyle surfaceStyle = SurfaceStyle(
    radii: glassPillSettings.scaleRadii(const SurfaceStyle().radii),
  );

  // App spacing from settings: extensions and theme slots (e.g. divider indent/endIndent)
  final AppSpacing appSpacing = spacingSettings.toAppSpacing();

  // Check Material You setting - if enabled and colorScheme is provided, ignore scheme/variant
  final bool usePureDynamicColors = materialYouEnabled && colorScheme != null;

  // Resolve scheme/variant for current brightness (null when Material You so builder uses dynamic colors only)
  final FlexScheme? resolvedScheme = usePureDynamicColors
      ? null
      : (brightness == Brightness.light
            ? (flexSettings.lightScheme ??
                  flexSettings.scheme ??
                  FlexScheme.blueM3)
            : (flexSettings.darkScheme ??
                  flexSettings.scheme ??
                  FlexScheme.blueM3));
  final FlexSchemeVariant? resolvedVariant = usePureDynamicColors
      ? null
      : flexSettings.variant;

  // When Material You is on, clear scheme/variant so builder uses only dynamic colorScheme.
  // When fontFamily is empty, clear Flex font so theme uses system default.
  final FlexThemeSettingsModel settingsForBuilder = usePureDynamicColors
      ? flexSettings.copyWith(
          clearScheme: true,
          clearVariant: true,
          clearFontFamily: fontFamily.isEmpty,
          fontFamily: fontFamily.isEmpty ? null : fontFamily,
        )
      : flexSettings.copyWith(
          scheme: resolvedScheme,
          variant: resolvedVariant,
          clearFontFamily: fontFamily.isEmpty,
          fontFamily: fontFamily.isEmpty ? null : fontFamily,
        );

  // Default sub-themes configuration (same as before for consistent behavior)
  final FlexSubThemesData defaultSubThemesData = brightness == Brightness.light
      ? const FlexSubThemesData(
          inputDecoratorIsFilled: true,
          alignedDropdown: true,
          tooltipRadius: 4,
          tooltipSchemeColor: SchemeColor.inverseSurface,
          tooltipOpacity: 0.9,
          snackBarElevation: 6,
          snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
          navigationRailUseIndicator: true,
        )
      : const FlexSubThemesData(
          blendOnColors: true,
          inputDecoratorIsFilled: true,
          alignedDropdown: true,
          tooltipRadius: 4,
          tooltipSchemeColor: SchemeColor.inverseSurface,
          tooltipOpacity: 0.9,
          snackBarElevation: 6,
          snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
          navigationRailUseIndicator: true,
        );

  final FlexColorScheme flexScheme = brightness == Brightness.light
      ? FlexColorSchemeBuilder.buildLight(
          settings: settingsForBuilder,
          dynamicColorScheme: usePureDynamicColors ? colorScheme : null,
          subThemesData: defaultSubThemesData,
          keyColors: const FlexKeyColors(),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          cupertinoOverrideTheme: const CupertinoThemeData(
            applyThemeToAll: true,
          ),
        )
      : FlexColorSchemeBuilder.buildDark(
          settings: settingsForBuilder,
          dynamicColorScheme: usePureDynamicColors ? colorScheme : null,
          subThemesData: defaultSubThemesData,
          keyColors: const FlexKeyColors(),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          cupertinoOverrideTheme: const CupertinoThemeData(
            applyThemeToAll: true,
          ),
        );

  // When a Google Font is selected, load and apply it via text theme so the font
  // is fetched at runtime (requires network; macOS needs client entitlement).
  // Pass baseTheme.textTheme so light/dark colors are preserved (see google_fonts docs).
  final ThemeData baseTheme = flexScheme.toTheme;
  final TextTheme? textThemeForGoogleFont =
      fontFamily.isNotEmpty && GoogleFonts.asMap().containsKey(fontFamily)
      ? GoogleFonts.getTextTheme(fontFamily, baseTheme.textTheme)
      : null;

  // return ThemeData(
  // brightness: Brightness.dark,
  return baseTheme.copyWith(
    textTheme: textThemeForGoogleFont,
    scaffoldBackgroundColor: baseTheme.colorScheme.surface,
    tabBarTheme: const TabBarThemeData(
      dividerColor: Colors.transparent,
      dividerHeight: 0,
    ),
    // Card shapes (data-driven from surfaceStyle to avoid circular dependency)
    cardTheme: CardThemeData(
      shape: surfaceShapeFromSettings(surfaceStyle, RadiusSize.medium),
    ),
    // Dialog shapes
    dialogTheme: DialogThemeData(
      shape: surfaceShapeFromSettings(surfaceStyle, RadiusSize.large),
    ),
    // Bottom sheet with top corners only
    bottomSheetTheme: BottomSheetThemeData(
      surfaceTintColor: Colors.transparent,
      shape: surfaceShapeFromSettings(
        surfaceStyle,
        RadiusSize.large,
        corners: CornerGroups.top,
      ),
    ),
    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      enabledBorder: inputBorderFromSettings(
        surfaceStyle,
        RadiusSize.medium,
        side: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: inputBorderFromSettings(surfaceStyle, RadiusSize.medium),
      border: inputBorderFromSettings(surfaceStyle, RadiusSize.medium),
    ),
    // Divider horizontal insets from app spacing so plain Divider() follows screen padding
    dividerTheme: DividerThemeData(
      indent: appSpacing.screenPadding.left,
      endIndent: appSpacing.screenPadding.right,
    ),
    extensions: <ThemeExtension<dynamic>>[
      surfaceStyle,
      glassPillSettings.toGlassPillTheme(),
      appSpacing,
    ],
  );
}
