import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/users/viewer_settings_session_provider.dart';
import 'package:diohub/routes/router.gr.dart';
import 'package:diohub/view/settings/md3/settings_md3_widgets.dart';
import 'package:diohub/view/settings/md3/settings_paginated_collection.dart';
import 'package:diohub_graphql/queries/users/user_repositories_list.graphql.dart'
    show
        Query$getUserRepositories$user$repositories$edges$node,
        Query$getUserRepositories$user$repositories$edges$node$primaryLanguage;
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/user_info_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

ViewerSettingsSessionKey _sessionKey(final AccountModel account) =>
    (scope: resourceScopeForAccount(account), login: account.username);

class SettingsGitHubOrganizationsPage extends ConsumerWidget {
  const SettingsGitHubOrganizationsPage({required this.account, super.key});

  final AccountModel account;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ViewerSettingsSession session = ref.watch(
      viewerSettingsSessionProvider(_sessionKey(account)),
    );
    final PaginationController<UserOrgEdge, UserOrgEdge> controller =
        session.organizations;
    return Column(
      key: const ValueKey<String>('settings-github-organizations'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsOrganizations,
          description: context.l10n.settingsOrganizationsDescription,
          trailing: _GitHubSettingsLink(
            account: account,
            path: '/settings/organizations',
          ),
        ),
        _RefreshRow(controller.refresh),
        const SizedBox(height: 16),
        SettingsPaginatedCollection<UserOrgEdge>(
          controller: controller,
          emptyIcon: Icons.apartment_outlined,
          emptyTitle: context.l10n.settingsNoOrganizations,
          emptyDescription: context.l10n.settingsNoOrganizationsDescription,
          itemBuilder: (final BuildContext context, final UserOrgEdge edge) {
            final UserOrgNode? organization = edge.node;
            if (organization == null) {
              return const SizedBox.shrink();
            }
            final String description = organization.description?.trim() ?? '';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: UserAvatar(
                avatarUrl: organization.avatarUrl.toString(),
                fallbackText: organization.login,
                size: 44,
              ),
              title: Text(
                organization.name?.trim().isNotEmpty ?? false
                    ? organization.name!
                    : organization.login,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('@${organization.login}'),
                  if (description.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.settingsOrganizationSummary(
                      organization.repositories.totalCount,
                      organization.membersWithRole.totalCount,
                    ),
                  ),
                ],
              ),
              isThreeLine: description.isNotEmpty,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.router.push(
                UserProfileRoute(userRef: UserRef(login: organization.login)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class SettingsGitHubRepositoriesPage extends ConsumerWidget {
  const SettingsGitHubRepositoriesPage({required this.account, super.key});

  final AccountModel account;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ViewerSettingsSession session = ref.watch(
      viewerSettingsSessionProvider(_sessionKey(account)),
    );
    final PaginationController<UserRepoEdge, UserRepoEdge> controller =
        session.repositories;
    return Column(
      key: const ValueKey<String>('settings-github-repositories'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.accountRepositories,
          description: context.l10n.settingsRepositoriesDescription,
          trailing: _GitHubSettingsLink(
            account: account,
            path: '/settings/repositories',
          ),
        ),
        _RefreshRow(controller.refresh),
        const SizedBox(height: 16),
        SettingsPaginatedCollection<UserRepoEdge>(
          controller: controller,
          emptyIcon: Icons.book_outlined,
          emptyTitle: context.l10n.settingsNoRepositories,
          emptyDescription: context.l10n.settingsNoRepositoriesDescription,
          itemBuilder: (final BuildContext context, final UserRepoEdge edge) {
            final Query$getUserRepositories$user$repositories$edges$node?
            repository = edge.node;
            if (repository == null) {
              return const SizedBox.shrink();
            }
            final String nameWithOwner = repository.nameWithOwner;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: Icon(
                repository.isPrivate ? Icons.lock_outline : Icons.book_outlined,
              ),
              title: Row(
                children: <Widget>[
                  Expanded(child: Text(nameWithOwner)),
                  if (repository.isFork)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: Chip(
                        label: Text(context.l10n.settingsFork),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (repository.description?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        repository.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: <Widget>[
                      if (repository.primaryLanguage
                          case final Query$getUserRepositories$user$repositories$edges$node$primaryLanguage
                              language)
                        Text(language.name),
                      Text(
                        context.l10n.settingsStars(repository.stargazerCount),
                      ),
                      Text(
                        context.l10n.settingsUpdatedOn(
                          MaterialLocalizations.of(
                            context,
                          ).formatCompactDate(repository.updatedAt.toLocal()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.router.push(
                RepositoryRoute(repo: RepoRef.fromFullName(nameWithOwner)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class SettingsGitHubModerationPage extends ConsumerStatefulWidget {
  const SettingsGitHubModerationPage({required this.account, super.key});

  final AccountModel account;

  @override
  ConsumerState<SettingsGitHubModerationPage> createState() =>
      _SettingsGitHubModerationPageState();
}

class _SettingsGitHubModerationPageState
    extends ConsumerState<SettingsGitHubModerationPage> {
  bool _mutating = false;

  Future<void> _run(final Future<void> Function() action) async {
    if (_mutating) {
      return;
    }
    setState(() => _mutating = true);
    try {
      await action();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaveError)));
      }
    } finally {
      if (mounted) {
        setState(() => _mutating = false);
      }
    }
  }

  Future<void> _block(final ViewerSettingsSession session) async {
    final String? username = await showDialog<String>(
      context: context,
      builder: (final BuildContext context) => const _BlockUserDialog(),
    );
    if (username == null || !mounted) {
      return;
    }
    await _run(() => session.blockUser(username));
  }

  @override
  Widget build(final BuildContext context) {
    final ViewerSettingsSession session = ref.watch(
      viewerSettingsSessionProvider(_sessionKey(widget.account)),
    );
    final PaginationController<SimpleUser, SimpleUser> controller =
        session.blockedUsers;
    return Column(
      key: const ValueKey<String>('settings-github-moderation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsModeration,
          description: context.l10n.settingsModerationDescription,
          trailing: _GitHubSettingsLink(
            account: widget.account,
            path: '/settings/moderation',
          ),
        ),
        Row(
          children: <Widget>[
            FilledButton.icon(
              onPressed: _mutating ? null : () => _block(session),
              icon: const Icon(Icons.person_off_outlined),
              label: Text(context.l10n.settingsBlockUser),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: context.l10n.settingsRefresh,
              onPressed: _mutating ? null : controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsPaginatedCollection<SimpleUser>(
          controller: controller,
          emptyIcon: Icons.person_off_outlined,
          emptyTitle: context.l10n.settingsNoBlockedUsers,
          emptyDescription: context.l10n.settingsNoBlockedUsersDescription,
          itemBuilder: (final BuildContext context, final SimpleUser user) =>
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: UserAvatar(
                  avatarUrl: user.avatarUrl,
                  fallbackText: user.login,
                  size: 40,
                ),
                title: Text(user.login),
                subtitle: user.name == null ? null : Text(user.name!),
                trailing: OutlinedButton(
                  onPressed: _mutating
                      ? null
                      : () => _run(() => session.unblockUser(user.login)),
                  child: Text(context.l10n.settingsUnblock),
                ),
                onTap: () => context.router.push(
                  UserProfileRoute(userRef: UserRef(login: user.login)),
                ),
              ),
        ),
      ],
    );
  }
}

class _RefreshRow extends StatelessWidget {
  const _RefreshRow(this.onRefresh);

  final VoidCallback onRefresh;

  @override
  Widget build(final BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: IconButton.outlined(
      tooltip: context.l10n.settingsRefresh,
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh),
    ),
  );
}

class _GitHubSettingsLink extends StatelessWidget {
  const _GitHubSettingsLink({required this.account, required this.path});

  final AccountModel account;
  final String path;

  @override
  Widget build(final BuildContext context) => IconButton.outlined(
    tooltip: context.l10n.settingsOpenOnGitHub,
    onPressed: () => unawaited(
      launchUrl(
        account.serverConfig.webUrl(path),
        mode: LaunchMode.externalApplication,
      ),
    ),
    icon: const Icon(Icons.open_in_new),
  );
}

class _BlockUserDialog extends StatefulWidget {
  const _BlockUserDialog();

  @override
  State<_BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<_BlockUserDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AlertDialog(
    title: Text(context.l10n.settingsBlockUser),
    content: TextField(
      controller: _controller,
      autofocus: true,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: context.l10n.settingsGitHubUsername,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (final String value) => _submit(),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(onPressed: _submit, child: Text(context.l10n.settingsBlock)),
    ],
  );

  void _submit() {
    final String username = _controller.text.trim();
    if (username.isNotEmpty) {
      Navigator.pop(context, username);
    }
  }
}
