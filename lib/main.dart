import 'package:auto_route/auto_route.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:diohub/adapters/deep_linking_handler.dart';
import 'package:diohub/adapters/internet_connectivity.dart';
import 'package:diohub/app/api_handler/dio.dart';
import 'package:diohub/app/api_handler/response_handler.dart';
import 'package:diohub/app/global.dart';
import 'package:diohub/app/settings/font.dart';
import 'package:diohub/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:diohub/providers/search_data_provider.dart';
import 'package:diohub/providers/users/current_user_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/services/authentication/auth_service.dart';
import 'package:diohub/style/surface_style_theme.dart';
import 'package:diohub/common/misc/surface_shape_resolver.dart';
import 'package:diohub/utils/device_display_mode.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  ChuckerFlutter.showNotification = false;
  // ChuckerFlutter.showOnRelease = true;
  WidgetsFlutterBinding.ensureInitialized();
  // Error popup stream initialised.
  ResponseHandler.getErrorStream();
  // Success popup stream initialised.
  ResponseHandler.getSuccessStream();
  // Connectivity check stream initialised.
  await InternetConnectivity.networkStatusService();

  await Future.wait(<Future<void>>[
    BaseAPIHandler.setupDioAPICache(),
    setUpSharedPrefs(),
    setHighRefreshRate(),
  ]);

  // final initLink = await initUniLink();
  uniLinkStream();
  final bool auth = await AuthRepository().isAuthenticated;
  // runApp(NewWidget());
  runApp(
    MyApp(
      authenticated: auth,
      // initDeepLink: initLink,
    ),
  );
  await debugURLLauncher();
}

class NewWidget extends StatelessWidget {
  const NewWidget({
    super.key,
  });

  @override
  Widget build(final BuildContext context) => MaterialApp(
        navigatorObservers: <NavigatorObserver>[
          ChuckerFlutter.navigatorObserver,
        ],
        home: Builder(
          builder: (final BuildContext context) => Stack(
            children: <Widget>[
              SafeArea(
                child: Scaffold(
                  body: NestedScrollView(
                    headerSliverBuilder: (final BuildContext context,
                            final bool innerBoxIsScrolled) =>
                        <Widget>[
                      const SliverAppBar(
                        title: Text('ajhs jhads '),
                        expandedHeight: 500,
                      ),
                    ],
                    body: ListView.builder(
                      itemBuilder:
                          (final BuildContext context, final int index) =>
                              ListTile(title: Text(index.toString())),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).padding.top,
                child: GestureDetector(
                  onTap: () {
                    PrimaryScrollController.of(context).animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.bounceIn,
                    );
                  },
                  child: Container(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({required this.authenticated, super.key});

  // final String? initDeepLink;
  final bool authenticated;

  @override
  Widget build(final BuildContext context) => MultiBlocProvider(
        providers: <SingleChildWidget>[
          // Initialise Authentication Bloc and add event to check auth state.
          BlocProvider<AuthenticationBloc>(
            create: (final _) =>
                AuthenticationBloc(authenticated: authenticated),
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
                ),
              ),
              ChangeNotifierProvider<SearchDataProvider>(
                create: (final _) => SearchDataProvider(),
              ),
              ChangeNotifierProvider<FontSettings>(
                create: (final _) => FontSettings(),
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
  }

  @override
  Widget build(final BuildContext context) => DynamicColorBuilder(
        builder:
            (final ColorScheme? lightDynamic, final ColorScheme? darkDynamic) {
          ColorScheme? lightScheme;
          ColorScheme? darkScheme;
          print('hjbs jhbf s');
          print(lightDynamic);
          print(darkDynamic);
          // if (lightDynamic != null && darkDynamic != null) {
          //   (lightScheme, darkScheme) =
          //       _generateDynamicColourSchemes(lightDynamic, darkDynamic);
          // } else {
          //   lightScheme = _defaultLightColorScheme;
          //   darkScheme = _defaultDarkColorScheme;
          // }
          return riverpod.ProviderScope(
            child: MaterialApp.router(
              theme: getTheme(
                context,
                brightness: Brightness.light,
                colorScheme: lightScheme,
              ),
              darkTheme: getTheme(
                context,
                brightness: Brightness.dark,
                colorScheme: darkScheme,
              ),
              localizationsDelegates: const <LocalizationsDelegate>[
                DefaultMaterialLocalizations.delegate,
                DefaultCupertinoLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
              ],
              // getTheme(context, brightness: Brightness.light),
              // darkTheme: getTheme(context, brightness: Brightness.dark),
              routerDelegate: customRouter.delegate(
                deepLinkBuilder: (final PlatformDeepLink deepLink) =>
                    DeepLink(<PageRouteInfo>[
                  LandingLoadingRoute(
                    initLink: deepLink.configuration.uri,
                  ),
                ]),
                navigatorObservers: () => <NavigatorObserver>[
                  ChuckerFlutter.navigatorObserver,
                ],
                rebuildStackOnDeepLink: true,
              ),
              routeInformationParser: customRouter.defaultRouteParser(),
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
  final ColorScheme? cs = colorScheme;
  // cs= cs.copyWith(surfaceTint: Colors.transparent);
  const SurfaceStyleTheme surfaceStyle = SurfaceStyleTheme();
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: Provider.of<FontSettings>(context).currentSetting,
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
    colorScheme: cs,
    extensions: <ThemeExtension<dynamic>>[
      surfaceStyle,
    ],
  );
}

const Color _seedColor = Color(0xff2563eb);

final ColorScheme _defaultLightColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.light,
);

final ColorScheme _defaultDarkColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.dark,
);

// Nice dark cs.
//ColorScheme#b066f(brightness: Brightness.dark, primary: Color(0xffbb86fc), onPrimary: Color(0xff000000), primaryContainer: Color(0xffbb86fc), onPrimaryContainer: Color(0xff000000), error: Color(0xffcf6679), onError: Color(0xff000000), errorContainer: Color(0xffcf6679), onErrorContainer: Color(0xff000000), background: Color(0xff121212), onBackground: Color(0xffffffff), surface: Color(0xff121212), onSurface: Color(0xffffffff), surfaceVariant: Color(0xff121212), onSurfaceVariant: Color(0xffffffff), outline: Color(0xffffffff), outlineVariant: Color(0xffffffff), inverseSurface: Color(0xffffffff), onInverseSurface: Color(0xff121212), inversePrimary: Color(0xff000000), surfaceTint: Color(0xffbb86fc))

// Workaround for https://github.com/material-foundation/flutter-packages/issues/582
(ColorScheme light, ColorScheme dark) _generateDynamicColourSchemes(
    final ColorScheme lightDynamic, final ColorScheme darkDynamic) {
  final ColorScheme lightBase =
      ColorScheme.fromSeed(seedColor: lightDynamic.primary);
  final ColorScheme darkBase = ColorScheme.fromSeed(
      seedColor: darkDynamic.primary, brightness: Brightness.dark);

  final List<Color> lightAdditionalColours =
      _extractAdditionalColours(lightBase);
  final List<Color> darkAdditionalColours = _extractAdditionalColours(darkBase);

  final ColorScheme lightScheme =
      _insertAdditionalColours(lightBase, lightAdditionalColours);
  final ColorScheme darkScheme =
      _insertAdditionalColours(darkBase, darkAdditionalColours);

  return (lightScheme.harmonized(), darkScheme.harmonized());
}

List<Color> _extractAdditionalColours(final ColorScheme scheme) => <Color>[
      scheme.surface,
      scheme.surfaceDim,
      scheme.surfaceBright,
      scheme.surfaceContainerLowest,
      scheme.surfaceContainerLow,
      scheme.surfaceContainer,
      scheme.surfaceContainerHigh,
      scheme.surfaceContainerHighest,
    ];

ColorScheme _insertAdditionalColours(
        final ColorScheme scheme, final List<Color> additionalColours) =>
    scheme.copyWith(
      surface: additionalColours[0],
      surfaceDim: additionalColours[1],
      surfaceBright: additionalColours[2],
      surfaceContainerLowest: additionalColours[3],
      surfaceContainerLow: additionalColours[4],
      surfaceContainer: additionalColours[5],
      surfaceContainerHigh: additionalColours[6],
      surfaceContainerHighest: additionalColours[7],
    );
