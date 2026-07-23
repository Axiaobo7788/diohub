import 'package:diohub/view/app_chrome/app_chrome_layout.dart';

/// Page-specific responsive dimensions for the GitHub-style home content.
///
/// Global header and drawer dimensions live in [AppChromeLayout]. The desktop
/// repository sidebar deliberately references that shared navigation width.
abstract final class HomeLayout {
  const HomeLayout._();

  /// Below this width the dashboard collapses to its compact, single-column UI.
  static const double desktopBreakpoint = AppChromeLayout.desktopBreakpoint;

  /// At and above this width the changelog aside can be shown with the desktop
  /// repository sidebar and the primary feed.
  static const double asideBreakpoint = 1360;

  /// The compact feed remains centered instead of stretching across a tablet.
  static const double compactContentMaxWidth = 820;

  static const double persistentSidebarWidth =
      AppChromeLayout.navigationDrawerWidth;
  static const double rightAsideWidth = 300;

  static const double compactPaddingBreakpoint = 600;
  static const double mobileHorizontalPadding = 16;
  static const double regularHorizontalPadding = 32;
}
