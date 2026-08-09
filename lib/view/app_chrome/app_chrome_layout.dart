/// Responsive dimensions owned by the shared application chrome.
///
/// Page-specific layouts may reference these values when they intentionally
/// align with the global header or navigation, but global chrome must not
/// depend on a page's layout tokens.
abstract final class AppChromeLayout {
  const AppChromeLayout._();

  static const double desktopBreakpoint = 1040;
  static const double desktopToolbarHeight = 52;
  static const double compactToolbarHeight = 56;
  static const double navigationDrawerWidth = 360;
  static const double navigationDrawerEdgeReveal = 56;
  static const double globalSearchWidth = 320;

  /// Leaves a visible edge of the underlying page on narrow windows.
  static double drawerWidthFor(final double viewportWidth) {
    if (viewportWidth < navigationDrawerWidth + navigationDrawerEdgeReveal) {
      return viewportWidth > navigationDrawerEdgeReveal
          ? viewportWidth - navigationDrawerEdgeReveal
          : viewportWidth;
    }
    return navigationDrawerWidth;
  }
}
