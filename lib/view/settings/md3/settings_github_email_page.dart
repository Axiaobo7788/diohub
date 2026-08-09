import 'dart:async';

import 'package:diohub/common/pagination/pagination_controller.dart';
import 'package:diohub/common/pagination/pagination_state.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/models/users/email_item.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/users/viewer_settings_session_provider.dart';
import 'package:diohub/view/settings/md3/settings_md3_widgets.dart';
import 'package:diohub/view/settings/md3/settings_paginated_collection.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsGitHubEmailPage extends ConsumerStatefulWidget {
  const SettingsGitHubEmailPage({required this.account, super.key});

  final AccountModel account;

  @override
  ConsumerState<SettingsGitHubEmailPage> createState() =>
      _SettingsGitHubEmailPageState();
}

class _SettingsGitHubEmailPageState
    extends ConsumerState<SettingsGitHubEmailPage> {
  bool _mutating = false;

  ViewerSettingsSessionKey get _sessionKey => (
    scope: resourceScopeForAccount(widget.account),
    login: widget.account.username,
  );

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

  Future<void> _addEmail(final ViewerSettingsSession session) async {
    final String? email = await showDialog<String>(
      context: context,
      builder: (final BuildContext context) => const _AddEmailDialog(),
    );
    if (email == null || !mounted) {
      return;
    }
    await _run(() => session.addEmails(<String>[email]));
  }

  Future<void> _deleteEmail(
    final ViewerSettingsSession session,
    final EmailItem item,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (final BuildContext context) => AlertDialog(
        title: Text(context.l10n.settingsDeleteEmail),
        content: Text(context.l10n.settingsDeleteEmailConfirmation(item.email)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.settingsDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _run(() => session.deleteEmail(item.email));
  }

  @override
  Widget build(final BuildContext context) {
    final ViewerSettingsSession session = ref.watch(
      viewerSettingsSessionProvider(_sessionKey),
    );
    final PaginationController<EmailItem, EmailItem> controller =
        session.emails;
    return Column(
      key: const ValueKey<String>('settings-github-emails'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsEmails,
          description: context.l10n.settingsEmailsDescription,
          trailing: IconButton.outlined(
            tooltip: context.l10n.settingsOpenOnGitHub,
            onPressed: () => unawaited(
              launchUrl(
                widget.account.serverConfig.webUrl('/settings/emails'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            icon: const Icon(Icons.open_in_new),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _mutating ? null : () => _addEmail(session),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.settingsAddEmail),
            ),
            IconButton.outlined(
              tooltip: context.l10n.settingsRefresh,
              onPressed: _mutating ? null : controller.refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<PaginationState<EmailItem>>(
          valueListenable: controller.state,
          builder:
              (
                final BuildContext context,
                final PaginationState<EmailItem> state,
                final Widget? _,
              ) {
                EmailItem? primary;
                for (final EmailItem email in state.items) {
                  if (email.primary) {
                    primary = email;
                    break;
                  }
                }
                if (primary == null) {
                  return const SizedBox.shrink();
                }
                final bool isPublic = primary.visibility == 'public';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card.outlined(
                    margin: EdgeInsets.zero,
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      value: isPublic,
                      onChanged: _mutating
                          ? null
                          : (final bool value) => _run(
                              () => session.setEmailVisibility(isPublic: value),
                            ),
                      title: Text(context.l10n.settingsPrimaryEmailVisibility),
                      subtitle: Text(
                        context.l10n.settingsPrimaryEmailVisibilityDescription,
                      ),
                    ),
                  ),
                );
              },
        ),
        SettingsPaginatedCollection<EmailItem>(
          controller: controller,
          emptyIcon: Icons.mark_email_read_outlined,
          emptyTitle: context.l10n.settingsNoEmails,
          emptyDescription: context.l10n.settingsNoEmailsDescription,
          itemBuilder: (final BuildContext context, final EmailItem item) =>
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Icon(
                  item.primary
                      ? Icons.mark_email_read_outlined
                      : Icons.email_outlined,
                ),
                title: Text(item.email),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      if (item.primary)
                        Chip(
                          label: Text(context.l10n.settingsEmailPrimary),
                          visualDensity: VisualDensity.compact,
                        ),
                      Chip(
                        label: Text(
                          item.verified
                              ? context.l10n.settingsEmailVerified
                              : context.l10n.settingsEmailUnverified,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (item.visibility case final String visibility)
                        Chip(
                          label: Text(
                            visibility == 'public'
                                ? context.l10n.settingsEmailPublic
                                : context.l10n.settingsEmailPrivate,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
                trailing: item.primary
                    ? null
                    : IconButton(
                        tooltip: context.l10n.settingsDelete,
                        onPressed: _mutating
                            ? null
                            : () => _deleteEmail(session, item),
                        icon: const Icon(Icons.delete_outline),
                      ),
              ),
        ),
      ],
    );
  }
}

class _AddEmailDialog extends StatefulWidget {
  const _AddEmailDialog();

  @override
  State<_AddEmailDialog> createState() => _AddEmailDialogState();
}

class _AddEmailDialogState extends State<_AddEmailDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AlertDialog(
    title: Text(context.l10n.settingsAddEmail),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const <String>[AutofillHints.email],
        decoration: InputDecoration(
          labelText: context.l10n.settingsEmailAddress,
          border: const OutlineInputBorder(),
        ),
        validator: (final String? value) {
          final String email = value?.trim() ?? '';
          return email.contains('@') && email.split('@').last.contains('.')
              ? null
              : context.l10n.settingsEmailInvalid;
        },
        onFieldSubmitted: (final String _) => _submit(),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.commonCancel),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(context.l10n.settingsAddEmail),
      ),
    ],
  );

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }
}
