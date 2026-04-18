import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/context_dock/models/dock_pill_descriptor.dart';
import 'package:diohub/common/notifications/notification_service.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:diohub/providers/dock/dock_pill_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ComposePillTextNotifier extends Notifier<String> {
  _ComposePillTextNotifier(this._descriptor);

  final DockPillDescriptor _descriptor;

  @override
  String build() => '';
}

/// Current text for a compose pill (for Submit companion to read).
/// Updated by [ComposePillContent] on debounced change.
final composePillTextProvider = NotifierProvider.autoDispose
    .family<_ComposePillTextNotifier, String, DockPillDescriptor>(
  _ComposePillTextNotifier.new,
);

class _ComposePillSubmitRequestedNotifier extends Notifier<bool> {
  _ComposePillSubmitRequestedNotifier(this._descriptor);

  final DockPillDescriptor _descriptor;

  @override
  bool build() => false;
}

/// When set to true, [ComposePillContent] runs submit (so it can show snackbar on error).
final composePillSubmitRequestedProvider = NotifierProvider.autoDispose
    .family<_ComposePillSubmitRequestedNotifier, bool, DockPillDescriptor>(
  _ComposePillSubmitRequestedNotifier.new,
);

/// Active-phase compose area: multi-line field, draft persistence (500ms debounce), unfocus → hint/idle.
/// Listens to [composePillSubmitRequestedProvider]; when true, runs [onSubmit] with try-catch and snackbar.
class ComposePillContent extends ConsumerStatefulWidget {
  const ComposePillContent({
    required this.persistenceKey,
    required this.descriptor,
    required this.onSubmit,
    super.key,
  });

  final String persistenceKey;
  final DockPillDescriptor descriptor;

  /// Called when user submits (via companion or internal button). Content widget wraps in try-catch and shows snackbar on error.
  final Future<void> Function(WidgetRef ref, String text) onSubmit;

  @override
  ConsumerState<ComposePillContent> createState() => _ComposePillContentState();
}

class _ComposePillContentState extends ConsumerState<ComposePillContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..requestFocus();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    try {
      final draftKey = DraftKey.pill(widget.persistenceKey);
      final body = await ref.read(composeDraftProvider(draftKey).future);
      if (body.isNotEmpty && mounted) {
        _controller.text = body;
        ref.read(composePillTextProvider(widget.descriptor).notifier).state =
            body;
      }
    } catch (e, st) {
      AppLogger.warning(
        'Loading compose draft failed',
        error: e,
        stackTrace: st,
        tag: 'ComposePillContent',
      );
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = _controller.text.trim();
      final notifier =
          ref.read(dockPillPhaseProvider(widget.descriptor).notifier);
      if (text.isEmpty) {
        notifier.idle();
      } else {
        notifier.hint();
      }
    }
  }

  void _onTextChanged() {
    final text = _controller.text;
    ref.read(composePillTextProvider(widget.descriptor).notifier).state = text;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref
          .read(composeDraftProvider(DraftKey.pill(widget.persistenceKey))
              .notifier)
          .updateBody(text);
    });
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await widget.onSubmit(ref, text);
      if (!mounted) return;
      ref
          .read(composeDraftProvider(DraftKey.pill(widget.persistenceKey))
              .notifier)
          .clear();
      ref.read(composePillTextProvider(widget.descriptor).notifier).state = '';
      ref.read(dockPillPhaseProvider(widget.descriptor).notifier).idle();
    } catch (e, st) {
      AppLogger.warning(
        'Compose submit failed',
        error: e,
        stackTrace: st,
        tag: 'ComposePillContent',
      );
      if (mounted) {
        ref.read(notificationServiceProvider).error(e.toString());
      }
    } finally {
      if (mounted) {
        ref
            .read(
                composePillSubmitRequestedProvider(widget.descriptor).notifier)
            .state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      composePillSubmitRequestedProvider(widget.descriptor),
      (prev, next) {
        if (next) _performSubmit();
      },
    );
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      minLines: 2,
      decoration: InputDecoration(
        hintText: 'Type your message...',
        border: InputBorder.none,
        isDense: true,
      ),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

/// Default hint: "Draft" when draft exists for [persistenceKey].
class ComposePillHint extends ConsumerWidget {
  const ComposePillHint({required this.persistenceKey, super.key});

  final String persistenceKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDraft = ref.watch(composeDraftExistsProvider(persistenceKey));
    if (!hasDraft) return const SizedBox.shrink();

    return Text(
      'Draft',
      maxLines: 1,
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
