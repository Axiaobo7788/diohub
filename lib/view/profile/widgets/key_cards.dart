import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/cards/metadata_chips.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub/common/misc/bordered_container.dart';
import 'package:diohub/common/riverpod/delete_confirm_mutation_icon.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/users/gpg_key_item.dart';
import 'package:diohub_models/models/users/ssh_key_item.dart';
import 'package:diohub_models/models/users/ssh_signing_key_item.dart';
import 'package:diohub/providers/profile/delete_key_mutation_providers.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:diohub/common/widgets/tinted_chip.dart';

/// SSH key card for the viewer's Keys position (with delete).
Widget buildSSHKeyCard(
  BuildContext context,
  WidgetRef ref,
  UserRef userRef,
  SSHKeyItem item,
) {
  final theme = Theme.of(context);
  final spacing = context.spacing;

  final Widget content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(Octicons.key, size: 18, color: theme.colorScheme.primary),
          SizedBox(width: spacing.tightSpacing),
          Expanded(
            child: Text(
              item.title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.readOnly)
            Padding(
              padding: EdgeInsets.only(right: spacing.tightSpacing),
              child: TintedChip(
                color: theme.colorScheme.onSurfaceVariant,
                icon: Icons.lock_outline_rounded,
                label: 'Read-only',
              ),
            ),
          DeleteConfirmMutationIcon(
            mutation: ref.watch(
                deleteSSHKeyMutationProvider((user: userRef, keyId: item.id))),
            onDelete: () => ref
                .read(deleteSSHKeyMutationProvider(
                    (user: userRef, keyId: item.id)).notifier)
                .delete(),
            confirmTitle: 'Delete key',
          ),
        ],
      ),
      SizedBox(height: spacing.tightSpacing),
      Row(
        children: [
          Flexible(
            child: Text(
              item.fingerprint,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: spacing.tightSpacing),
          TimestampLabel(date: item.createdAt.toIso8601String()),
          if (item.lastUsedAt != null) ...[
            Text(
              ' · ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TimestampLabel(
              date: item.lastUsedAt!.toIso8601String(),
              shorten: true,
            ),
          ],
        ],
      ),
      SizedBox(height: spacing.tightSpacing),
      Text(
        item.key.length > 80 ? '${item.key.substring(0, 80)}...' : item.key,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  return Padding(
    padding: EdgeInsets.only(bottom: spacing.itemSpacing),
    child: BorderedContainer(
      padding: spacing.cardContentPadding,
      child: content,
    ),
  );
}

/// Read-only SSH key card for other users' Public Keys (no delete).
Widget buildPublicSSHKeyCard(BuildContext context, SSHKeyItem item) {
  final theme = Theme.of(context);
  final spacing = context.spacing;

  final Widget content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(Octicons.key, size: 18, color: theme.colorScheme.primary),
          SizedBox(width: spacing.tightSpacing),
          Expanded(
            child: Text(
              item.title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item.readOnly)
            TintedChip(
              color: theme.colorScheme.onSurfaceVariant,
              icon: Icons.lock_outline_rounded,
              label: 'Read-only',
            ),
        ],
      ),
      SizedBox(height: spacing.tightSpacing),
      Row(
        children: [
          Flexible(
            child: Text(
              item.fingerprint,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: spacing.tightSpacing),
          TimestampLabel(date: item.createdAt.toIso8601String()),
          if (item.lastUsedAt != null) ...[
            Text(
              ' · ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TimestampLabel(
              date: item.lastUsedAt!.toIso8601String(),
              shorten: true,
            ),
          ],
        ],
      ),
      SizedBox(height: spacing.tightSpacing),
      Text(
        item.key.length > 80 ? '${item.key.substring(0, 80)}...' : item.key,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  return Padding(
    padding: EdgeInsets.only(bottom: spacing.itemSpacing),
    child: BorderedContainer(
      padding: spacing.cardContentPadding,
      child: content,
    ),
  );
}

/// GPG key card for the viewer's Keys position (with delete).
Widget buildGpgKeyCard(
  BuildContext context,
  WidgetRef ref,
  UserRef userRef,
  GpgKeyItem item,
) {
  final theme = Theme.of(context);
  final spacing = context.spacing;
  final isExpiringSoon = item.expiresAt != null &&
      item.expiresAt!.difference(DateTime.now()).inDays < 30;

  final Widget content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(Octicons.shield_check,
              size: 18, color: theme.colorScheme.primary),
          SizedBox(width: spacing.tightSpacing),
          Expanded(
            child: Text(
              item.keyId,
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DeleteConfirmMutationIcon(
            mutation: ref.watch(
                deleteGpgKeyMutationProvider((user: userRef, keyId: item.id))),
            onDelete: () => ref
                .read(deleteGpgKeyMutationProvider(
                    (user: userRef, keyId: item.id)).notifier)
                .delete(),
            confirmTitle: 'Delete GPG key',
          ),
        ],
      ),
      SizedBox(height: spacing.tightSpacing),
      if (item.emails.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(bottom: spacing.tightSpacing),
          child: Wrap(
            spacing: spacing.tightSpacing,
            runSpacing: spacing.tightSpacing,
            children: item.emails
                .map(
                  (e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: spacing.tightSpacing),
                      Text(
                        e.email,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (e.verified) ...[
                        SizedBox(width: spacing.tightSpacing),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      Row(
        children: [
          if (item.subkeys.isNotEmpty)
            TintedChip(
              color: theme.colorScheme.onSurfaceVariant,
              icon: Octicons.key,
              label: '+${item.subkeys.length} subkeys',
            ),
          SizedBox(width: spacing.tightSpacing),
          if (item.canSign)
            TintedChip(
              color: theme.colorScheme.primary,
              icon: Icons.draw_rounded,
              label: 'Sign',
            ),
          if (item.canEncryptComms) ...[
            SizedBox(width: spacing.tightSpacing),
            TintedChip(
              color: theme.colorScheme.primary,
              icon: Icons.lock_rounded,
              label: 'Encrypt',
            ),
          ],
          if (item.canCertify) ...[
            SizedBox(width: spacing.tightSpacing),
            TintedChip(
              color: theme.colorScheme.primary,
              icon: Icons.verified_rounded,
              label: 'Certify',
            ),
          ],
        ],
      ),
      SizedBox(height: spacing.tightSpacing),
      Row(
        children: [
          TimestampLabel(date: item.createdAt.toIso8601String()),
          if (item.expiresAt != null) ...[
            Text(
              ' · ',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TimestampLabel(
              date: item.expiresAt!.toIso8601String(),
              shorten: true,
            ),
            if (isExpiringSoon)
              Padding(
                padding: EdgeInsets.only(left: spacing.tightSpacing),
                child: Text(
                  'Expires soon',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ],
      ),
    ],
  );

  return Padding(
    padding: EdgeInsets.only(bottom: spacing.itemSpacing),
    child: BorderedContainer(
      padding: spacing.cardContentPadding,
      child: content,
    ),
  );
}

/// SSH signing key card for the viewer's Keys position (with delete).
Widget buildSSHSigningKeyCard(
  BuildContext context,
  WidgetRef ref,
  UserRef userRef,
  SSHSigningKeyItem item,
) {
  final theme = Theme.of(context);
  final spacing = context.spacing;

  final Widget content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(Octicons.pencil, size: 18, color: theme.colorScheme.primary),
          SizedBox(width: spacing.tightSpacing),
          Expanded(
            child: Text(
              item.title,
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DeleteConfirmMutationIcon(
            mutation: ref.watch(deleteSSHSigningKeyMutationProvider(
                (user: userRef, keyId: item.id))),
            onDelete: () => ref
                .read(deleteSSHSigningKeyMutationProvider(
                    (user: userRef, keyId: item.id)).notifier)
                .delete(),
            confirmTitle: 'Delete signing key',
          ),
        ],
      ),
      SizedBox(height: spacing.tightSpacing),
      Text(
        item.key.length > 80 ? '${item.key.substring(0, 80)}...' : item.key,
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      SizedBox(height: spacing.tightSpacing),
      TimestampLabel(date: item.createdAt.toIso8601String()),
    ],
  );

  return Padding(
    padding: EdgeInsets.only(bottom: spacing.itemSpacing),
    child: BorderedContainer(
      padding: spacing.cardContentPadding,
      child: content,
    ),
  );
}

bool _isValidSSHKeyPrefix(String key) {
  final trimmed = key.trim();
  return trimmed.startsWith('ssh-rsa ') ||
      trimmed.startsWith('ssh-ed25519 ') ||
      trimmed.startsWith('ecdsa-sha2-nistp256 ') ||
      trimmed.startsWith('ecdsa-sha2-nistp384 ') ||
      trimmed.startsWith('ecdsa-sha2-nistp521 ');
}

/// Shows the add-SSH-key bottom sheet. On success pops and triggers refresh.
Future<void> showAddSSHKeySheet(
  BuildContext context, {
  required UserRef userRef,
  required VoidCallback onAdded,
}) async {
  await AppSheet.form<void>(
    context,
    header: AppSheetHeader(title: Text('Add SSH key')),
    bodyBuilder: (BuildContext ctx, StateSetter setState) =>
        _AddSSHKeySheet(userRef: userRef, onAdded: onAdded),
  );
}

class _AddSSHKeySheet extends ConsumerStatefulWidget {
  const _AddSSHKeySheet({
    required this.userRef,
    required this.onAdded,
  });

  final UserRef userRef;
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddSSHKeySheet> createState() => _AddSSHKeySheetState();
}

class _AddSSHKeySheetState extends ConsumerState<_AddSSHKeySheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final key = _keyController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required');
      return;
    }
    if (key.isEmpty) {
      setState(() => _error = 'Key is required');
      return;
    }
    if (!_isValidSSHKeyPrefix(key)) {
      setState(() => _error =
          'Key should start with ssh-rsa, ssh-ed25519, or ecdsa-sha2-*');
      return;
    }
    setState(() => _error = null);
    await ref
        .read(viewerSettingsServiceProvider)
        .createSSHKey(title: title, key: key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return SingleChildScrollView(
      child: Padding(
        padding: spacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. My Laptop',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            SizedBox(height: spacing.itemSpacing),
            TextFormField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                hintText: 'Paste your public key',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              SizedBox(height: spacing.itemSpacing),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            SizedBox(height: spacing.sectionSpacing),
            SubmitButton(
              onSubmit: _submit,
              onSuccess: () {
                widget.onAdded();
                Navigator.of(context).pop();
              },
              onError: (e) {
                AppLogger.warning(
                  'Create SSH key failed',
                  error: e,
                  stackTrace: StackTrace.current,
                  tag: 'KeyCards',
                );
                setState(() => _error = e.toString());
              },
              label: (isSubmitting) =>
                  Text(isSubmitting ? 'Adding...' : 'Add key'),
            ),
          ],
        ),
      ),
    );
  }
}
