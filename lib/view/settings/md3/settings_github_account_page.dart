import 'dart:async';

import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/users/email_item.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/view/settings/md3/settings_md3_layout.dart';
import 'package:diohub/view/settings/md3/settings_md3_navigation.dart';
import 'package:diohub/view/settings/md3/settings_md3_widgets.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPublicProfilePage extends ConsumerWidget {
  const SettingsPublicProfilePage({required this.account, super.key});

  final AccountModel? account;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final AccountModel? activeAccount = account;
    if (activeAccount == null) {
      return const _GitHubAccountRequired();
    }

    final UserRef userRef = UserRef(login: activeAccount.username);
    final AsyncValue<UserProfileData> profile = ref.watch(
      userProvider(userRef),
    );
    return profile.when(
      loading: () => const _PublicProfileLoading(),
      error: (final Object _, final StackTrace _) => _PublicProfileError(
        onRetry: () => ref.invalidate(userProvider(userRef)),
      ),
      data: (final UserProfileData data) {
        final UserProfile? user = data.owner.maybeWhen(
          user: (final UserProfile value) => value,
          orElse: () => null,
        );
        if (user == null) {
          return _PublicProfileError(
            onRetry: () => ref.invalidate(userProvider(userRef)),
          );
        }
        return _PublicProfileForm(
          key: ValueKey<String>('settings-public-profile-${user.login}'),
          account: activeAccount,
          userRef: userRef,
          user: user,
        );
      },
    );
  }
}

class _PublicProfileForm extends ConsumerStatefulWidget {
  const _PublicProfileForm({
    required this.account,
    required this.userRef,
    required this.user,
    super.key,
  });

  final AccountModel account;
  final UserRef userRef;
  final UserProfile user;

  @override
  ConsumerState<_PublicProfileForm> createState() => _PublicProfileFormState();
}

class _PublicProfileFormState extends ConsumerState<_PublicProfileForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late String _bio;
  late String _blog;
  late String _company;
  late String _location;
  late String _twitter;
  late bool _hireable;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _readUser(widget.user);
  }

  @override
  void didUpdateWidget(covariant final _PublicProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.login != widget.user.login || !_dirty) {
      _readUser(widget.user);
    }
  }

  void _readUser(final UserProfile user) {
    _name = user.name ?? '';
    _email = user.email;
    _bio = user.bio ?? '';
    _blog = user.websiteUrl?.toString() ?? '';
    _company = user.company ?? '';
    _location = user.location ?? '';
    _twitter = user.twitterUsername ?? '';
    _hireable = user.isHireable;
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      final bool updated = await ref
          .read(userProvider(widget.userRef).notifier)
          .updateProfileFields(<String, dynamic>{
            'name': _name.trim(),
            'email': _email.trim(),
            'bio': _bio.trim(),
            'blog': _blog.trim(),
            'company': _company.trim(),
            'location': _location.trim(),
            'twitter_username': _twitter.trim(),
            'hireable': _hireable,
          });
      if (!mounted) {
        return;
      }
      if (!updated) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaveError)));
        return;
      }
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsProfileUpdated)),
      );
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaveError)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(final BuildContext context) => Form(
    key: _formKey,
    child: Column(
      key: const ValueKey<String>('settings-public-profile-page'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsPublicProfile,
          description: context.l10n.settingsPublicProfileDescription,
        ),
        LayoutBuilder(
          builder:
              (final BuildContext context, final BoxConstraints constraints) {
                final Widget fields = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _field(
                      fieldKey: const ValueKey<String>('settings-profile-name'),
                      label: context.l10n.settingsProfileName,
                      initialValue: _name,
                      onChanged: (final String value) {
                        _name = value;
                        _markDirty();
                      },
                    ),
                    _emailPicker(context),
                    _field(
                      label: context.l10n.settingsProfileBio,
                      initialValue: _bio,
                      maxLines: 4,
                      onChanged: (final String value) {
                        _bio = value;
                        _markDirty();
                      },
                    ),
                    _readOnlyField(
                      context,
                      label: context.l10n.settingsProfilePronouns,
                      value: widget.user.pronouns ?? '',
                      onOpen: () => _openGitHubPath('/settings/profile'),
                    ),
                    _field(
                      label: context.l10n.settingsProfileUrl,
                      initialValue: _blog,
                      keyboardType: TextInputType.url,
                      onChanged: (final String value) {
                        _blog = value;
                        _markDirty();
                      },
                    ),
                    _field(
                      label: context.l10n.settingsProfileCompany,
                      initialValue: _company,
                      onChanged: (final String value) {
                        _company = value;
                        _markDirty();
                      },
                    ),
                    _field(
                      label: context.l10n.settingsProfileLocation,
                      initialValue: _location,
                      onChanged: (final String value) {
                        _location = value;
                        _markDirty();
                      },
                    ),
                    _field(
                      label: context.l10n.settingsProfileTwitter,
                      initialValue: _twitter,
                      onChanged: (final String value) {
                        _twitter = value;
                        _markDirty();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.settingsProfileAvailableForHire),
                      value: _hireable,
                      onChanged: (final bool value) {
                        setState(() {
                          _hireable = value;
                          _dirty = true;
                        });
                      },
                    ),
                  ],
                );
                final Widget avatar = _ProfileAvatarPanel(
                  account: widget.account,
                  onManage: () => _openGitHubPath('/settings/profile'),
                );
                if (constraints.maxWidth < 820) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      avatar,
                      const SizedBox(height: 24),
                      fields,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: fields),
                    const SizedBox(width: 48),
                    SizedBox(width: 260, child: avatar),
                  ],
                );
              },
        ),
        const SizedBox(height: 20),
        FilledButton(
          key: const ValueKey<String>('settings-update-profile'),
          onPressed: _dirty && !_saving ? () => unawaited(_save()) : null,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.settingsUpdateProfile),
        ),
        const SizedBox(height: 40),
      ],
    ),
  );

  Widget _field({
    required final String label,
    required final String initialValue,
    required final ValueChanged<String> onChanged,
    final Key? fieldKey,
    final String? helperText,
    final TextInputType? keyboardType,
    final int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      key: fieldKey,
      initialValue: initialValue,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
      onChanged: onChanged,
    ),
  );

  Widget _readOnlyField(
    final BuildContext context, {
    required final String label,
    required final String value,
    required final VoidCallback onOpen,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: onOpen,
          tooltip: context.l10n.settingsOpenOnGitHub,
          icon: const Icon(Icons.open_in_new),
        ),
      ),
    ),
  );

  Widget _emailPicker(final BuildContext context) {
    final AsyncValue<List<EmailItem>> verifiedEmails = ref.watch(
      viewerVerifiedEmailsProvider,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: verifiedEmails.when(
        loading: () => InputDecorator(
          decoration: InputDecoration(
            labelText: context.l10n.settingsProfilePublicEmail,
            helperText: context.l10n.settingsProfilePublicEmailDescription,
            border: const OutlineInputBorder(),
          ),
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (final Object _, final StackTrace _) => InputDecorator(
          decoration: InputDecoration(
            labelText: context.l10n.settingsProfilePublicEmail,
            helperText: context.l10n.settingsProfileEmailLoadError,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () => ref.invalidate(viewerVerifiedEmailsProvider),
              tooltip: context.l10n.commonRetry,
              icon: const Icon(Icons.refresh),
            ),
          ),
          child: Text(
            _email.isEmpty ? context.l10n.settingsProfileEmailHidden : _email,
          ),
        ),
        data: (final List<EmailItem> emails) {
          final List<String> choices = <String>[
            '',
            ...emails.map((final EmailItem item) => item.email),
          ];
          if (_email.isNotEmpty && !choices.contains(_email)) {
            choices.add(_email);
          }
          return DropdownButtonFormField<String>(
            key: ValueKey<String>(
              'settings-profile-email-${choices.join('|')}',
            ),
            initialValue: choices.contains(_email) ? _email : '',
            decoration: InputDecoration(
              labelText: context.l10n.settingsProfilePublicEmail,
              helperText: context.l10n.settingsProfilePublicEmailDescription,
              border: const OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: '',
                child: Text(context.l10n.settingsProfileEmailHidden),
              ),
              for (final String email in choices.skip(1))
                DropdownMenuItem<String>(value: email, child: Text(email)),
            ],
            onChanged: (final String? value) {
              _email = value ?? '';
              _markDirty();
            },
          );
        },
      ),
    );
  }

  Future<void> _openGitHubPath(final String path) => launchUrl(
    widget.account.serverConfig.webUrl(path),
    mode: LaunchMode.externalApplication,
  );
}

class _ProfileAvatarPanel extends StatelessWidget {
  const _ProfileAvatarPanel({required this.account, required this.onManage});

  final AccountModel account;
  final VoidCallback onManage;

  @override
  Widget build(final BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        context.l10n.settingsProfilePicture,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Center(
        child: UserAvatar(
          avatarUrl: account.avatarUrl,
          fallbackText: account.username,
          size: 180,
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: OutlinedButton.icon(
          onPressed: onManage,
          icon: const Icon(Icons.edit_outlined),
          label: Text(context.l10n.settingsManageProfilePicture),
        ),
      ),
    ],
  );
}

class SettingsGitHubManagedPage extends StatelessWidget {
  const SettingsGitHubManagedPage({
    required this.destination,
    required this.account,
    super.key,
  });

  final SettingsDestination destination;
  final AccountModel? account;

  @override
  Widget build(final BuildContext context) {
    final String title = settingsDestinationLabel(context, destination);
    final AccountModel? activeAccount = account;
    final ({String title, String description, IconData icon}) availability =
        _availability(context, destination);
    return Column(
      key: ValueKey<String>('settings-github-managed-${destination.path}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: title,
          description: availability.description,
        ),
        Md3SettingsSection(
          title: availability.title,
          children: <Widget>[
            SettingsActionRow(
              title: context.l10n.settingsOpenOnGitHub,
              subtitle: activeAccount == null
                  ? context.l10n.settingsSignInToManageGitHub
                  : context.l10n.settingsOpenOnGitHubDescription(
                      activeAccount.host,
                    ),
              icon: availability.icon,
              onPressed: activeAccount == null
                  ? null
                  : () => unawaited(
                      launchUrl(
                        activeAccount.serverConfig.webUrl(
                          _githubPath(destination),
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
              trailing: activeAccount == null
                  ? const Icon(Icons.lock_outline)
                  : const Icon(Icons.open_in_new),
            ),
          ],
        ),
      ],
    );
  }

  ({String title, String description, IconData icon}) _availability(
    final BuildContext context,
    final SettingsDestination destination,
  ) => switch (destination) {
    SettingsDestination.billingAndLicensing ||
    SettingsDestination.githubNotifications => (
      title: context.l10n.settingsPartialApiCoverage,
      description: context.l10n.settingsPartialApiCoverageDescription(
        settingsDestinationLabel(context, destination),
      ),
      icon: Icons.hub_outlined,
    ),
    SettingsDestination.codespaces => (
      title: context.l10n.settingsOAuthScopeRequired,
      description: context.l10n.settingsOAuthScopeRequiredDescription(
        settingsDestinationLabel(context, destination),
      ),
      icon: Icons.lock_outline,
    ),
    _ => (
      title: context.l10n.settingsBrowserOnly,
      description: context.l10n.settingsBrowserOnlyDescription(
        settingsDestinationLabel(context, destination),
      ),
      icon: Icons.language_outlined,
    ),
  };

  String _githubPath(final SettingsDestination destination) =>
      switch (destination) {
        SettingsDestination.account => '/settings/admin',
        SettingsDestination.githubAppearance => '/settings/appearance',
        SettingsDestination.githubAccessibility => '/settings/accessibility',
        SettingsDestination.githubNotifications => '/settings/notifications',
        SettingsDestination.billingAndLicensing => '/settings/billing',
        SettingsDestination.emails => '/settings/emails',
        SettingsDestination.passwordAndAuthentication => '/settings/security',
        SettingsDestination.sessions => '/settings/sessions',
        SettingsDestination.sshAndGpgKeys => '/settings/keys',
        SettingsDestination.organizations => '/settings/organizations',
        SettingsDestination.enterprises => '/settings/enterprises',
        SettingsDestination.moderation => '/settings/moderation',
        SettingsDestination.githubRepositories => '/settings/repositories',
        SettingsDestination.codespaces => '/settings/codespaces',
        _ => '/settings/profile',
      };
}

class _GitHubAccountRequired extends StatelessWidget {
  const _GitHubAccountRequired();

  @override
  Widget build(final BuildContext context) => Column(
    key: const ValueKey<String>('settings-github-account-required'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SettingsPageHeading(
        title: context.l10n.settingsPublicProfile,
        description: context.l10n.settingsSignInToManageGitHub,
      ),
      const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Icon(Icons.lock_outline, size: 48),
        ),
      ),
    ],
  );
}

class _PublicProfileLoading extends StatelessWidget {
  const _PublicProfileLoading();

  @override
  Widget build(final BuildContext context) => Column(
    key: const ValueKey<String>('settings-public-profile-loading'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SettingsPageHeading(
        title: context.l10n.settingsPublicProfile,
        description: context.l10n.settingsPublicProfileDescription,
      ),
      const LinearProgressIndicator(),
      const SizedBox(height: 24),
      for (final double width in <double>[520, 520, 720, 520])
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Container(
            width: width,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
    ],
  );
}

class _PublicProfileError extends StatelessWidget {
  const _PublicProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) => Column(
    key: const ValueKey<String>('settings-public-profile-error'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SettingsPageHeading(
        title: context.l10n.settingsPublicProfile,
        description: context.l10n.settingsPublicProfileLoadError,
      ),
      OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: Text(context.l10n.commonRetry),
      ),
    ],
  );
}
