import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/common/clipboard/clipboard_service.dart';
import 'package:diohub/l10n/l10n.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Bottom sheet showing HTTPS and SSH clone URLs with copy buttons.
class CloneUrlSheet extends ConsumerWidget {
  const CloneUrlSheet({
    required this.httpsUrl,
    required this.sshUrl,
    super.key,
  });

  final String httpsUrl;
  final String sshUrl;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final spacing = context.spacing;
    final clipboard = ref.read(clipboardServiceProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _UrlRow(
          label: 'HTTPS',
          url: httpsUrl,
          onCopy: () => clipboard.copy(httpsUrl),
        ),
        SizedBox(height: spacing.itemSpacing),
        _UrlRow(
          label: 'SSH',
          url: sshUrl,
          onCopy: () => clipboard.copy(sshUrl),
        ),
      ],
    );
  }
}

class _UrlRow extends StatelessWidget {
  const _UrlRow({required this.label, required this.url, required this.onCopy});

  final String label;
  final String url;
  final VoidCallback onCopy;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            url,
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Octicons.copy),
          onPressed: onCopy,
          tooltip: context.l10n.repoCopyCloneUrl,
        ),
      ],
    );
  }
}
