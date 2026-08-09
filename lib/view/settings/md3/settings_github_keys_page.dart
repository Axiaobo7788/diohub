import 'dart:async';

import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/providers/resource_runtime/resource_runtime_provider.dart';
import 'package:diohub/providers/users/viewer_settings_session_provider.dart';
import 'package:diohub/view/settings/md3/settings_md3_widgets.dart';
import 'package:diohub/view/settings/md3/settings_paginated_collection.dart';
import 'package:diohub_models/models/authentication/account_model.dart';
import 'package:diohub_models/models/users/gpg_key_item.dart';
import 'package:diohub_models/models/users/ssh_key_item.dart';
import 'package:diohub_models/models/users/ssh_signing_key_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

enum _SettingsKeyKind { ssh, gpg, signing }

class SettingsGitHubKeysPage extends ConsumerStatefulWidget {
  const SettingsGitHubKeysPage({required this.account, super.key});

  final AccountModel account;

  @override
  ConsumerState<SettingsGitHubKeysPage> createState() =>
      _SettingsGitHubKeysPageState();
}

class _SettingsGitHubKeysPageState
    extends ConsumerState<SettingsGitHubKeysPage> {
  _SettingsKeyKind _kind = _SettingsKeyKind.ssh;
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

  Future<void> _addKey(final ViewerSettingsSession session) async {
    final _KeyDraft? draft = await showDialog<_KeyDraft>(
      context: context,
      builder: (final BuildContext context) => _AddKeyDialog(kind: _kind),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _run(
      () => switch (_kind) {
        _SettingsKeyKind.ssh => session.createSSHKey(
          title: draft.title,
          key: draft.key,
        ),
        _SettingsKeyKind.gpg => session.createGPGKey(
          armoredPublicKey: draft.key,
          name: draft.title,
        ),
        _SettingsKeyKind.signing => session.createSSHSigningKey(
          title: draft.title,
          key: draft.key,
        ),
      },
    );
  }

  Future<bool> _confirmDelete(final String title) async =>
      await showDialog<bool>(
        context: context,
        builder: (final BuildContext context) => AlertDialog(
          title: Text(context.l10n.settingsDeleteKey),
          content: Text(context.l10n.settingsDeleteKeyConfirmation(title)),
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
      ) ??
      false;

  @override
  Widget build(final BuildContext context) {
    final ViewerSettingsSession session = ref.watch(
      viewerSettingsSessionProvider(_sessionKey),
    );
    return Column(
      key: const ValueKey<String>('settings-github-keys'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SettingsPageHeading(
          title: context.l10n.settingsSshAndGpgKeys,
          description: context.l10n.settingsKeysDescription,
          trailing: IconButton.outlined(
            tooltip: context.l10n.settingsOpenOnGitHub,
            onPressed: () => unawaited(
              launchUrl(
                widget.account.serverConfig.webUrl('/settings/keys'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            icon: const Icon(Icons.open_in_new),
          ),
        ),
        LayoutBuilder(
          builder:
              (final BuildContext context, final BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 600;
                final Widget selector = SegmentedButton<_SettingsKeyKind>(
                  segments: <ButtonSegment<_SettingsKeyKind>>[
                    ButtonSegment<_SettingsKeyKind>(
                      value: _SettingsKeyKind.ssh,
                      icon: const Icon(Icons.vpn_key_outlined),
                      label: Text(context.l10n.settingsSshKeys),
                    ),
                    ButtonSegment<_SettingsKeyKind>(
                      value: _SettingsKeyKind.gpg,
                      icon: const Icon(Icons.password_outlined),
                      label: Text(context.l10n.settingsGpgKeys),
                    ),
                    ButtonSegment<_SettingsKeyKind>(
                      value: _SettingsKeyKind.signing,
                      icon: const Icon(Icons.draw_outlined),
                      label: Text(context.l10n.settingsSshSigningKeys),
                    ),
                  ],
                  selected: <_SettingsKeyKind>{_kind},
                  onSelectionChanged: (final Set<_SettingsKeyKind> selected) =>
                      setState(() => _kind = selected.single),
                  showSelectedIcon: false,
                );
                final Widget addButton = FilledButton.icon(
                  onPressed: _mutating ? null : () => _addKey(session),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.settingsAddKey),
                );
                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: selector,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: addButton,
                          ),
                        ],
                      )
                    : Row(
                        children: <Widget>[
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: selector,
                            ),
                          ),
                          const SizedBox(width: 12),
                          addButton,
                        ],
                      );
              },
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          layoutBuilder:
              (
                final Widget? currentChild,
                final List<Widget> previousChildren,
              ) => Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  for (final Widget child in previousChildren)
                    IgnorePointer(child: ExcludeSemantics(child: child)),
                  ?currentChild,
                ],
              ),
          child: switch (_kind) {
            _SettingsKeyKind.ssh => _buildSsh(context, session),
            _SettingsKeyKind.gpg => _buildGpg(context, session),
            _SettingsKeyKind.signing => _buildSigning(context, session),
          },
        ),
      ],
    );
  }

  Widget _buildSsh(
    final BuildContext context,
    final ViewerSettingsSession session,
  ) => SettingsPaginatedCollection<SSHKeyItem>(
    key: const ValueKey<_SettingsKeyKind>(_SettingsKeyKind.ssh),
    controller: session.sshKeys,
    emptyIcon: Icons.vpn_key_outlined,
    emptyTitle: context.l10n.settingsNoSshKeys,
    emptyDescription: context.l10n.settingsNoSshKeysDescription,
    itemBuilder: (final BuildContext context, final SSHKeyItem item) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: const Icon(Icons.vpn_key_outlined),
      title: Text(item.title),
      subtitle: Text(
        '${item.fingerprint}\n${context.l10n.settingsAddedOn(_formatDate(context, item.createdAt))}',
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: context.l10n.settingsDelete,
        onPressed: _mutating
            ? null
            : () async {
                if (await _confirmDelete(item.title)) {
                  await _run(() => session.deleteSSHKey(item.id));
                }
              },
        icon: const Icon(Icons.delete_outline),
      ),
    ),
  );

  Widget _buildGpg(
    final BuildContext context,
    final ViewerSettingsSession session,
  ) => SettingsPaginatedCollection<GpgKeyItem>(
    key: const ValueKey<_SettingsKeyKind>(_SettingsKeyKind.gpg),
    controller: session.gpgKeys,
    emptyIcon: Icons.password_outlined,
    emptyTitle: context.l10n.settingsNoGpgKeys,
    emptyDescription: context.l10n.settingsNoGpgKeysDescription,
    itemBuilder: (final BuildContext context, final GpgKeyItem item) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: const Icon(Icons.password_outlined),
      title: Text(
        item.name?.trim().isNotEmpty ?? false ? item.name! : item.keyId,
      ),
      subtitle: Text(
        '${item.keyId}\n${context.l10n.settingsAddedOn(_formatDate(context, item.createdAt))}',
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: context.l10n.settingsDelete,
        onPressed: _mutating
            ? null
            : () async {
                if (await _confirmDelete(item.name ?? item.keyId)) {
                  await _run(() => session.deleteGPGKey(item.id));
                }
              },
        icon: const Icon(Icons.delete_outline),
      ),
    ),
  );

  Widget _buildSigning(
    final BuildContext context,
    final ViewerSettingsSession session,
  ) => SettingsPaginatedCollection<SSHSigningKeyItem>(
    key: const ValueKey<_SettingsKeyKind>(_SettingsKeyKind.signing),
    controller: session.sshSigningKeys,
    emptyIcon: Icons.draw_outlined,
    emptyTitle: context.l10n.settingsNoSigningKeys,
    emptyDescription: context.l10n.settingsNoSigningKeysDescription,
    itemBuilder: (final BuildContext context, final SSHSigningKeyItem item) =>
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: const Icon(Icons.draw_outlined),
          title: Text(item.title),
          subtitle: Text(
            '${_abbreviate(item.key)}\n${context.l10n.settingsAddedOn(_formatDate(context, item.createdAt))}',
          ),
          isThreeLine: true,
          trailing: IconButton(
            tooltip: context.l10n.settingsDelete,
            onPressed: _mutating
                ? null
                : () async {
                    if (await _confirmDelete(item.title)) {
                      await _run(() => session.deleteSSHSigningKey(item.id));
                    }
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ),
  );

  String _formatDate(final BuildContext context, final DateTime date) =>
      MaterialLocalizations.of(context).formatCompactDate(date.toLocal());

  String _abbreviate(final String value) {
    final String normalized = value.trim();
    return normalized.length <= 44
        ? normalized
        : '${normalized.substring(0, 44)}…';
  }
}

final class _KeyDraft {
  const _KeyDraft({required this.title, required this.key});

  final String title;
  final String key;
}

class _AddKeyDialog extends StatefulWidget {
  const _AddKeyDialog({required this.kind});

  final _SettingsKeyKind kind;

  @override
  State<_AddKeyDialog> createState() => _AddKeyDialogState();
}

class _AddKeyDialogState extends State<_AddKeyDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final bool isGpg = widget.kind == _SettingsKeyKind.gpg;
    return AlertDialog(
      title: Text(context.l10n.settingsAddKey),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: isGpg
                      ? context.l10n.settingsKeyNameOptional
                      : context.l10n.settingsKeyTitle,
                  border: const OutlineInputBorder(),
                ),
                validator: isGpg
                    ? null
                    : (final String? value) => value?.trim().isNotEmpty ?? false
                          ? null
                          : context.l10n.settingsFieldRequired,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keyController,
                minLines: 5,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: isGpg
                      ? context.l10n.settingsArmoredGpgKey
                      : context.l10n.settingsPublicKey,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (final String? value) =>
                    value?.trim().isNotEmpty ?? false
                    ? null
                    : context.l10n.settingsFieldRequired,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n.settingsAddKey),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.pop(
      context,
      _KeyDraft(
        title: _titleController.text.trim(),
        key: _keyController.text.trim(),
      ),
    );
  }
}
