import 'package:diohub/view/app_chrome/app_chrome_layout.dart';

enum ProfileWindowClass { compact, medium, expanded }

/// Responsive dimensions for the GitHub-style profile surface.
abstract final class ProfileMd3Layout {
  const ProfileMd3Layout._();

  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = AppChromeLayout.desktopBreakpoint;
  static const double contentMaxWidth = 1280;
  static const double identityWidth = 296;

  static ProfileWindowClass windowClassFor(final double width) {
    if (width < compactBreakpoint) return ProfileWindowClass.compact;
    if (width < expandedBreakpoint) return ProfileWindowClass.medium;
    return ProfileWindowClass.expanded;
  }

  static double pageInsetFor(final ProfileWindowClass windowClass) =>
      switch (windowClass) {
        ProfileWindowClass.compact => 16,
        ProfileWindowClass.medium => 24,
        ProfileWindowClass.expanded => 32,
      };

  static double avatarSizeFor(final ProfileWindowClass windowClass) =>
      switch (windowClass) {
        ProfileWindowClass.compact => 88,
        ProfileWindowClass.medium => 112,
        ProfileWindowClass.expanded => 256,
      };
}
