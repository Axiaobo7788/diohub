import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showAddGPGKeySheet(
  BuildContext context, {
  required VoidCallback onAdded,
}) async {
  await AppSheet.scrollable<void>(
    context,
    header: AppSheetHeader.text('Add GPG Key'),
    bodyBuilder: (final BuildContext ctx, final StateSetter setState,
            final ScrollController scrollController) =>
        _AddGPGKeyBody(onAdded: onAdded),
  );
}

class _AddGPGKeyBody extends ConsumerStatefulWidget {
  const _AddGPGKeyBody({required this.onAdded});
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddGPGKeyBody> createState() => _AddGPGKeyBodyState();
}

class _AddGPGKeyBodyState extends ConsumerState<_AddGPGKeyBody> {
  final TextEditingController _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String key = _keyController.text.trim();
    if (key.isEmpty) {
      throw Exception('Paste your armored GPG public key');
    }
    await ref
        .read(viewerSettingsServiceProvider)
        .createGPGKey(armoredPublicKey: key);
  }

  @override
  Widget build(BuildContext context) {
    final AppSpacing spacing = context.spacing;
    return Padding(
      padding: spacing.cardContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _keyController,
            decoration: const InputDecoration(
              labelText: 'Armored public key',
              hintText: '-----BEGIN PGP PUBLIC KEY BLOCK-----',
              border: OutlineInputBorder(),
            ),
            maxLines: 8,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          SizedBox(height: spacing.itemSpacing),
          SubmitButton(
            onSubmit: _submit,
            onSuccess: () {
              widget.onAdded();
              Navigator.of(context).pop();
            },
            onError: (e) {
              if (mounted) {
                ref.read(notificationServiceProvider).error(e.toString());
              }
            },
            label: (isSubmitting) =>
                Text(isSubmitting ? 'Adding…' : 'Add GPG key'),
          ),
        ],
      ),
    );
  }
}
