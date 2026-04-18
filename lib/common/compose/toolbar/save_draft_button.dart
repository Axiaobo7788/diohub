import 'package:diohub/common/compose/models/compose_config.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toolbar button that saves the current body to draft storage and shows checkmark feedback.
class SaveDraftButton extends ConsumerStatefulWidget {
  const SaveDraftButton({
    required this.config,
    required this.controller,
    super.key,
  });

  final ComposeConfig config;
  final TextEditingController controller;

  @override
  ConsumerState<SaveDraftButton> createState() => _SaveDraftButtonState();
}

class _SaveDraftButtonState extends ConsumerState<SaveDraftButton> {
  bool _saved = false;

  Future<void> _handleSave() async {
    final config = widget.config;
    if (!config.hasDraft) return;
    final key = DraftKey.fromConfig(config);
    if (key == null) return;
    await ref.read(composeDraftProvider(key).notifier).save(widget.controller.text);
    if (mounted) {
      setState(() => _saved = true);
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_saved ? Icons.check : Icons.save_outlined, size: 20),
      tooltip: 'Save draft',
      onPressed: _handleSave,
    );
  }
}
