import 'dart:async';
import 'dart:developer' as developer;
import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/app/settings/font.dart';
import 'package:diohub/app/settings/theme_mode.dart';
import 'package:diohub/app/theme_settings/api/flex_theme_settings_service.dart';
import 'package:diohub/utils/material_you_support.dart';
import 'package:diohub/app/theme_settings/models/flex_theme_settings_model.dart';
import 'package:diohub/blocs/account_bloc/account_bloc.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/providers/search_data_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/routes/router.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/services/authentication/scope_check_service.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/utils/device_display_mode.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<void> debugURLLauncher() async {
  await Future<void>.delayed(const Duration(seconds: 2));
  String? url;
  // https://github.com/flutter/flutter/issues/120732
  // https://github.com/flutter/flutter/issues/128696
  // url = 'https://github.com/firebase/flutterfire/issues/1041';
  if (kDebugMode) {
    await deepLinkNavigate(
      Uri.parse(url ?? ''),
    );
  }
}

void main() async {
  // debugPaintSizeEnabled = true;

  ChuckerFlutter.showNotification = false;
  // ChuckerFlutter.showOnRelease = true;
  WidgetsFlutterBinding.ensureInitialized();
  // Error popup stream initialised.
  // ResponseHandler.getErrorStream();
  // Success popup stream initialised.
  // ResponseHandler.getSuccessStream();
  // Connectivity check stream initialised.
  // await InternetConnectivity.networkStatusService();

  await Future.wait(<Future<void>>[
    BaseAPIHandler.setupDioAPICache(),
    setUpSharedPrefs(),
    setHighRefreshRate(),
  ]);

  if (kDebugMode) {
    unawaited(
      developer.Service.getInfo().then(
        (final ServiceProtocolInfo value) {
          debugPrint('DEVTOOLS serverUri: ${value.serverUri}');
        },
      ),
    );
  }

  // final initLink = await initUniLink();
  uniLinkStream();
  // Auth check now happens in AuthenticationBloc on initialization
  // runApp(NewWidget());
  runApp(
    const MyApp(
        // initDeepLink: initLink,
        ),
  );

  await debugURLLauncher();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // final String? initDeepLink;

  @override
  Widget build(final BuildContext context) {
    final AuthRepository authRepository = AuthRepository();
    final AccountBloc accountBloc = AccountBloc(authRepository)
      ..add(LoadAccounts());
    final AuthenticationBloc authenticationBloc =
        AuthenticationBloc(accountBloc: accountBloc);

    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        // Initialise Account Bloc first
        BlocProvider<AccountBloc>(
          create: (final _) {
            return accountBloc;
          },
          lazy: false,
        ),
        // Initialise Authentication Bloc - it will check auth state automatically
        BlocProvider<AuthenticationBloc>(
          create: (final BuildContext context) => authenticationBloc,
          lazy: false,
        ),
      ],
      child: Builder(
        builder: (final BuildContext context) => MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<CurrentUserProvider>(
              lazy: false,
              create: (final _) => CurrentUserProvider(
                authenticationBloc:
                    BlocProvider.of<AuthenticationBloc>(context),
                accountBloc: BlocProvider.of<AccountBloc>(context),
              ),
            ),
            ChangeNotifierProvider<FlexThemeSettingsService>(
              lazy: false,
              create: (final _) => FlexThemeSettingsService(),
            ),
            ChangeNotifierProvider<SearchDataProvider>(
              create: (final _) => SearchDataProvider(),
            ),
            ChangeNotifierProvider<FontSettings>(
              create: (final _) => FontSettings(),
            ),
            ChangeNotifierProvider<ThemeModeSettings>(
              create: (final _) => ThemeModeSettings(),
            ),
            // ChangeNotifierProvider<PaletteSettings>(
            //   create: (final _) => PaletteSettings(),
            // ),
          ],
          builder: (final BuildContext context, final Widget? child) =>
              const Portal(
            child: RootApp(),
          ),
        ),
      ),
    );
  }
}

/// Custom scroll behavior that uses BouncingScrollPhysics app-wide
class _BouncingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(final BuildContext context) =>
      const BouncingScrollPhysics();
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  // final String? initDeepLink;

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  @override
  void initState() {
    setUpRouter(context);
    super.initState();
    // Check scope after a short delay to ensure context is ready
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      ScopeCheckService.checkAndPromptScopeReauth(context);
    });
  }

  @override
  Widget build(final BuildContext context) => DynamicColorBuilder(
        builder:
            (final ColorScheme? lightDynamic, final ColorScheme? darkDynamic) {
          final supportsMaterialYou =
              MaterialYouSupport.isSupported(lightDynamic, darkDynamic);

          return riverpod.ProviderScope(
            child: Consumer<ThemeModeSettings>(
              builder: (context, themeModeSettings, child) =>
                  Consumer<FlexThemeSettingsService>(
                builder: (context, themeSettings, child) {
                  // Only use dynamic colors if Material You is enabled AND device supports it
                  final useDynamicColors =
                      themeModeSettings.materialYouEnabled &&
                          supportsMaterialYou;

                  return MaterialApp.router(
                    theme: getTheme(
                      context,
                      brightness: Brightness.light,
                      colorScheme: useDynamicColors ? lightDynamic : null,
                    ),
                    darkTheme: getTheme(
                      context,
                      brightness: Brightness.dark,
                      colorScheme: useDynamicColors ? darkDynamic : null,
                    ),
                    themeMode: themeModeSettings.themeMode,
                    scrollBehavior: _BouncingScrollBehavior(),
                    localizationsDelegates: const <LocalizationsDelegate>[
                      DefaultMaterialLocalizations.delegate,
                      DefaultCupertinoLocalizations.delegate,
                      DefaultWidgetsLocalizations.delegate,
                    ],
                    routerDelegate: customRouter.delegate(
                      deepLinkBuilder: (final PlatformDeepLink deepLink) =>
                          DeepLink(<PageRouteInfo>[
                        LandingLoadingRoute(
                          initLink: deepLink.configuration.uri,
                        ),
                      ]),
                      navigatorObservers: () => <NavigatorObserver>[
                        ChuckerFlutter.navigatorObserver,
                        AuthStateObserver(context),
                      ],
                      rebuildStackOnDeepLink: true,
                    ),
                    routeInformationParser: customRouter.defaultRouteParser(),
                  );
                },
              ),
            ),
          );
        },
      );
}

ThemeData getTheme(
  final BuildContext context, {
  required final Brightness brightness,
  required final ColorScheme? colorScheme,
}) {
  const SurfaceStyleTheme surfaceStyle = SurfaceStyleTheme();
  final String fontFamily = Provider.of<FontSettings>(context).currentSetting;

  // Get theme settings from service
  final FlexThemeSettingsService? themeSettingsService =
      Provider.of<FlexThemeSettingsService?>(context);
  final themeSettings =
      themeSettingsService?.value ?? FlexThemeSettingsModel.defaults;

  // Check Material You setting - if enabled and colorScheme is provided, ignore scheme/variant
  final ThemeModeSettings? themeModeSettings =
      Provider.of<ThemeModeSettings?>(context);
  final bool isMaterialYouEnabled =
      themeModeSettings?.materialYouEnabled ?? false;
  final bool usePureDynamicColors = isMaterialYouEnabled && colorScheme != null;

  // Get scheme from settings or default to blueM3
  // Only use scheme/variant when Material You is disabled or no dynamic colors
  // When Material You is enabled, set scheme/variant to null to avoid FlexScheme preset influence
  final FlexScheme? scheme = usePureDynamicColors
      ? null // Don't use scheme when Material You is enabled
      : (brightness == Brightness.light
          ? (themeSettings.lightScheme ??
              themeSettings.scheme ??
              FlexScheme.blueM3)
          : (themeSettings.darkScheme ??
              themeSettings.scheme ??
              FlexScheme.blueM3));
  final FlexSchemeVariant? variant = usePureDynamicColors
      ? null // Don't use variant when Material You is enabled
      : themeSettings.variant;
  final int blendLevel = themeSettings.blendLevel ?? 10;

  // Default sub-themes configuration
  // Note: We don't set cardRadius, dialogRadius, bottomSheetRadius, or inputDecoratorRadius
  // because these are customized via copyWith using SurfaceShapeResolver.
  // FlexColorScheme may apply its own defaults for these, but copyWith (applied after toTheme)
  // will override them, so our custom shapes will take precedence.
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
      ? FlexColorScheme.light(
          scheme: scheme, // Will be null when Material You enabled
          colorScheme: colorScheme,
          variant: variant, // Will be null when Material You enabled
          blendLevel: blendLevel,
          fontFamily: fontFamily,
          subThemesData: defaultSubThemesData,
          keyColors: const FlexKeyColors(),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          cupertinoOverrideTheme:
              const CupertinoThemeData(applyThemeToAll: true),
        )
      : FlexColorScheme.dark(
          scheme: scheme, // Will be null when Material You enabled
          colorScheme: colorScheme,
          variant: variant, // Will be null when Material You enabled
          blendLevel: blendLevel,
          // darkIsTrueBlack: themeSettings.darkIsTrueBlack ?? false,
          fontFamily: fontFamily,
          subThemesData: defaultSubThemesData,
          keyColors: const FlexKeyColors(),
          visualDensity: FlexColorScheme.comfortablePlatformDensity,
          cupertinoOverrideTheme:
              const CupertinoThemeData(applyThemeToAll: true),
        );

  // return ThemeData(
  // brightness: Brightness.dark,
  return flexScheme.toTheme.copyWith(
    // Card shapes
    cardTheme: CardThemeData(
      shape: SurfaceShapeResolver.medium(context),
    ),
    // Dialog shapes
    dialogTheme: DialogThemeData(
      shape: SurfaceShapeResolver.large(context),
    ),
    // Bottom sheet with top corners only
    bottomSheetTheme: BottomSheetThemeData(
      surfaceTintColor: Colors.transparent,
      shape: SurfaceShapeResolver.large(
        context,
        corners: const [CornerSide.top],
      ),
    ),
    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      enabledBorder: SurfaceShapeResolver.inputBorder(
        context,
        size: BorderRadiusSize.medium,
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: SurfaceShapeResolver.inputBorder(
        context,
        size: BorderRadiusSize.medium,
      ),
      border: SurfaceShapeResolver.inputBorder(
        context,
        size: BorderRadiusSize.medium,
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      surfaceStyle,
    ],
  );
}
