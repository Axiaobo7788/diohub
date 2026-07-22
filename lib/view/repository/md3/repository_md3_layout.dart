import 'package:flutter/material.dart';

/// Repository page breakpoints shared by Android and desktop.
enum RepositoryWindowClass { compact, medium, expanded }

abstract final class RepositoryMd3Layout {
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1200;
  static const double inlineCodeToolbarBreakpoint = 760;

  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double compactPageInset = 12;
  static const double regularPageInset = 24;
  static const double expandedPageInset = 32;
  static const double navigationRailWidth = 80;
  static const double expandedNavigationRailWidth = 224;
  static const double asideWidth = 296;
  static const double appSearchWidth = 480;
  static const double pickerWidth = 560;
  static const double pickerHeight = 520;
  static const double avatarSize = 32;
  static const double statusIconSize = 48;
  static const double refButtonLabelWidth = 180;
  static const double fileIconWidth = 36;
  static const double fileMessageWidth = 280;
  static const double fileUpdatedWidth = 104;

  static RepositoryWindowClass windowClassFor(final double width) {
    if (width < compactBreakpoint) {
      return RepositoryWindowClass.compact;
    }
    if (width < expandedBreakpoint) {
      return RepositoryWindowClass.medium;
    }
    return RepositoryWindowClass.expanded;
  }

  static EdgeInsets pagePaddingFor(final RepositoryWindowClass windowClass) {
    return switch (windowClass) {
      RepositoryWindowClass.compact => const EdgeInsets.all(compactPageInset),
      RepositoryWindowClass.medium => const EdgeInsets.all(regularPageInset),
      RepositoryWindowClass.expanded => const EdgeInsets.all(expandedPageInset),
    };
  }
}
