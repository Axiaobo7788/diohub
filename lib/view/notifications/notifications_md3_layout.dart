import 'package:diohub/view/app_chrome/app_chrome_layout.dart';
import 'package:flutter/material.dart';

enum NotificationsWindowClass { compact, medium, expanded }

/// Responsive dimensions shared by the notifications inbox presentation.
///
/// The global header and drawer remain owned by [AppChromeLayout]. These
/// values only describe the page-local inbox/sidebar arrangement.
abstract final class NotificationsMd3Layout {
  const NotificationsMd3Layout._();

  static const double compactBreakpoint = 600;
  static const double desktopBreakpoint = AppChromeLayout.desktopBreakpoint;
  static const double contentMaxWidth = 1536;
  static const double sidebarWidth = 264;

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double sectionRadius = 8;

  static NotificationsWindowClass windowClassFor(final double width) {
    if (width < compactBreakpoint) {
      return NotificationsWindowClass.compact;
    }
    if (width < desktopBreakpoint) {
      return NotificationsWindowClass.medium;
    }
    return NotificationsWindowClass.expanded;
  }

  static EdgeInsets pagePaddingFor(
    final NotificationsWindowClass windowClass,
  ) => switch (windowClass) {
    NotificationsWindowClass.compact => const EdgeInsets.all(space12),
    NotificationsWindowClass.medium => const EdgeInsets.all(space24),
    NotificationsWindowClass.expanded => const EdgeInsets.all(space32),
  };
}
