import 'package:diohub/view/settings/md3/settings_code_repository_page.dart';
import 'package:diohub/view/settings/md3/settings_general_appearance_page.dart';
import 'package:diohub/view/settings/md3/settings_github_access_pages.dart';
import 'package:diohub/view/settings/md3/settings_github_account_page.dart';
import 'package:diohub/view/settings/md3/settings_github_email_page.dart';
import 'package:diohub/view/settings/md3/settings_github_keys_page.dart';
import 'package:diohub/view/settings/md3/settings_md3_layout.dart';
import 'package:diohub/view/settings/md3/settings_notifications_privacy_page.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';

class SettingsDestinationContent extends StatelessWidget {
  const SettingsDestinationContent({
    required this.destination,
    required this.account,
    super.key,
  });

  final SettingsDestination destination;
  final AccountModel? account;

  @override
  Widget build(final BuildContext context) {
    final AccountModel? activeAccount = account;
    return switch (destination) {
      SettingsDestination.publicProfile => SettingsPublicProfilePage(
        account: activeAccount,
      ),
      SettingsDestination.emails =>
        activeAccount == null
            ? SettingsGitHubManagedPage(
                destination: destination,
                account: activeAccount,
              )
            : SettingsGitHubEmailPage(account: activeAccount),
      SettingsDestination.sshAndGpgKeys =>
        activeAccount == null
            ? SettingsGitHubManagedPage(
                destination: destination,
                account: activeAccount,
              )
            : SettingsGitHubKeysPage(account: activeAccount),
      SettingsDestination.organizations =>
        activeAccount == null
            ? SettingsGitHubManagedPage(
                destination: destination,
                account: activeAccount,
              )
            : SettingsGitHubOrganizationsPage(account: activeAccount),
      SettingsDestination.moderation =>
        activeAccount == null
            ? SettingsGitHubManagedPage(
                destination: destination,
                account: activeAccount,
              )
            : SettingsGitHubModerationPage(account: activeAccount),
      SettingsDestination.githubRepositories =>
        activeAccount == null
            ? SettingsGitHubManagedPage(
                destination: destination,
                account: activeAccount,
              )
            : SettingsGitHubRepositoriesPage(account: activeAccount),
      SettingsDestination.dioHubGeneral => const SettingsGeneralPage(),
      SettingsDestination.dioHubAppearance => const SettingsAppearancePage(),
      SettingsDestination.dioHubAccessibility =>
        const SettingsAccessibilityPage(),
      SettingsDestination.dioHubCodeAndRepositories =>
        const SettingsCodeRepositoryPage(),
      SettingsDestination.dioHubNotifications =>
        const SettingsNotificationsPage(),
      SettingsDestination.dioHubPrivacy => const SettingsPrivacyPage(),
      SettingsDestination.dioHubAbout => const SettingsAboutPage(),
      _ => SettingsGitHubManagedPage(
        destination: destination,
        account: activeAccount,
      ),
    };
  }
}
