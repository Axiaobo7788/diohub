import 'package:diohub/view/app_chrome/app_chrome_layout.dart';
import 'package:flutter/material.dart';

enum SettingsWindowClass { compact, medium, expanded }

enum SettingsDestination {
  publicProfile,
  account,
  githubAppearance,
  githubAccessibility,
  githubNotifications,
  billingAndLicensing,
  emails,
  passwordAndAuthentication,
  sessions,
  sshAndGpgKeys,
  organizations,
  enterprises,
  moderation,
  githubRepositories,
  codespaces,
  dioHubGeneral,
  dioHubAppearance,
  dioHubAccessibility,
  dioHubCodeAndRepositories,
  dioHubNotifications,
  dioHubPrivacy,
  dioHubAbout;

  static SettingsDestination fromPath(final String? path) => switch (path) {
    null || '' || 'profile' => SettingsDestination.publicProfile,
    'account' => SettingsDestination.account,
    'appearance' => SettingsDestination.githubAppearance,
    'accessibility' => SettingsDestination.githubAccessibility,
    'notifications' => SettingsDestination.githubNotifications,
    'billing' => SettingsDestination.billingAndLicensing,
    'emails' => SettingsDestination.emails,
    'security' => SettingsDestination.passwordAndAuthentication,
    'sessions' => SettingsDestination.sessions,
    'keys' => SettingsDestination.sshAndGpgKeys,
    'organizations' => SettingsDestination.organizations,
    'enterprises' => SettingsDestination.enterprises,
    'moderation' => SettingsDestination.moderation,
    'repositories' => SettingsDestination.githubRepositories,
    'codespaces' => SettingsDestination.codespaces,
    'app' || 'general' => SettingsDestination.dioHubGeneral,
    'app/appearance' => SettingsDestination.dioHubAppearance,
    'app/accessibility' => SettingsDestination.dioHubAccessibility,
    'app/code' || 'code' => SettingsDestination.dioHubCodeAndRepositories,
    'app/notifications' => SettingsDestination.dioHubNotifications,
    'app/privacy' || 'privacy' => SettingsDestination.dioHubPrivacy,
    'app/about' || 'about' => SettingsDestination.dioHubAbout,
    _ => SettingsDestination.publicProfile,
  };

  String get path => switch (this) {
    SettingsDestination.publicProfile => 'profile',
    SettingsDestination.account => 'account',
    SettingsDestination.githubAppearance => 'appearance',
    SettingsDestination.githubAccessibility => 'accessibility',
    SettingsDestination.githubNotifications => 'notifications',
    SettingsDestination.billingAndLicensing => 'billing',
    SettingsDestination.emails => 'emails',
    SettingsDestination.passwordAndAuthentication => 'security',
    SettingsDestination.sessions => 'sessions',
    SettingsDestination.sshAndGpgKeys => 'keys',
    SettingsDestination.organizations => 'organizations',
    SettingsDestination.enterprises => 'enterprises',
    SettingsDestination.moderation => 'moderation',
    SettingsDestination.githubRepositories => 'repositories',
    SettingsDestination.codespaces => 'codespaces',
    SettingsDestination.dioHubGeneral => 'app',
    SettingsDestination.dioHubAppearance => 'app/appearance',
    SettingsDestination.dioHubAccessibility => 'app/accessibility',
    SettingsDestination.dioHubCodeAndRepositories => 'app/code',
    SettingsDestination.dioHubNotifications => 'app/notifications',
    SettingsDestination.dioHubPrivacy => 'app/privacy',
    SettingsDestination.dioHubAbout => 'app/about',
  };

  bool get requiresGitHubAccount =>
      index <= SettingsDestination.codespaces.index;
}

abstract final class SettingsMd3Layout {
  const SettingsMd3Layout._();

  static const double compactBreakpoint = 720;
  static const double desktopBreakpoint = AppChromeLayout.desktopBreakpoint;
  static const double contentMaxWidth = 1600;
  static const double navigationWidth = 352;
  static const double settingsColumnMaxWidth = 1160;

  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  static SettingsWindowClass windowClassFor(final double width) {
    if (width < compactBreakpoint) {
      return SettingsWindowClass.compact;
    }
    if (width < desktopBreakpoint) {
      return SettingsWindowClass.medium;
    }
    return SettingsWindowClass.expanded;
  }

  static EdgeInsets pagePaddingFor(
    final SettingsWindowClass windowClass,
  ) => switch (windowClass) {
    SettingsWindowClass.compact => const EdgeInsets.fromLTRB(16, 20, 16, 32),
    SettingsWindowClass.medium => const EdgeInsets.fromLTRB(24, 28, 24, 40),
    SettingsWindowClass.expanded => const EdgeInsets.fromLTRB(32, 32, 32, 48),
  };
}
