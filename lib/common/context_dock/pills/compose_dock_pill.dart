import 'dart:async';

import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/context_dock/models/dock_pill.dart';
import 'package:diohub/common/context_dock/models/dock_pill_phase.dart';
import 'package:diohub/providers/compose/compose_draft_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract base for compose pills (comment and review).
///
/// Handles draft persistence (DAO-backed, 500ms debounce), unfocus →
/// HintPhase or IdlePhase, and submit → clear draft → IdlePhase. Subclasses
/// customize icon, buildCompanions, onSubmit, and optional buildHintOverride.
abstract class ComposeDockPill extends DockPill {
  ComposeDockPill({required this.persistenceKey});

  /// Draft storage key (used with compose draft provider).
  final String persistenceKey;

  /// Companion pills are built during [onTap]. Submit companion should call
  /// [getCurrentText] and [onSubmit], then clear draft and set [value] to Idle.
  List<DockPill> buildCompanions();

  /// Submit the composed text. Called by the submit companion with ref + text.
  Future<void> onSubmit(WidgetRef ref, String text);

  /// Optional hint override (e.g. review: "N pending"). Default: null.
  Widget? buildHintOverride(BuildContext context) => null;

  /// Set by [_ComposeActiveContent] when active; cleared on dispose.
  /// Used by submit companion to read current text.
  TextEditingController? _activeController;

  void setActiveController(TextEditingController? c) {
    _activeController = c;
  }

  /// Current text from the active compose field. Empty if not active.
  String getCurrentText() => _activeController?.text ?? '';

  @override
  void onTap(BuildContext context, WidgetRef ref) {
    value = ActivePhase(companions: buildCompanions());
  }

  @override
  Widget? buildContent(BuildContext context) {
    return switch (value) {
      ActivePhase() => _ComposeActiveContent(
        persistenceKey: persistenceKey,
        pill: this,
      ),
      HintPhase() =>
        buildHintOverride(context) ??
            _ComposeDraftHint(persistenceKey: persistenceKey),
      IdlePhase() => null,
    };
  }
}

/// Active-phase compose area shared by comment and review pills.
class _ComposeActiveContent extends ConsumerStatefulWidget {
  const _ComposeActiveContent({
    required this.persistenceKey,
    required this.pill,
  });

  final String persistenceKey;
  final ComposeDockPill pill;

  @override
  ConsumerState<_ComposeActiveContent> createState() =>
      _ComposeActiveContentState();
}

class _ComposeActiveContentState extends ConsumerState<_ComposeActiveContent> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    widget.pill.setActiveController(_controller);
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
      }
    } catch (e, st) {
      AppLogger.warning(
        'Loading compose draft failed',
        error: e,
        stackTrace: st,
        tag: 'ComposeDockPill',
      );
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = _controller.text.trim();
      widget.pill.value = text.isEmpty ? const IdlePhase() : const HintPhase();
    }
  }

  void _onTextChanged() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref
          .read(
            composeDraftProvider(DraftKey.pill(widget.persistenceKey)).notifier,
          )
          .updateBody(_controller.text);
    });
  }

  @override
  void dispose() {
    widget.pill.setActiveController(null);
    _draftDebounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

/// Default hint for compose pills — shows "Draft" when draft exists.
class _ComposeDraftHint extends ConsumerWidget {
  const _ComposeDraftHint({required this.persistenceKey});
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
