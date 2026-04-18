import 'package:diohub/common/misc/user_avatar.dart';
import 'package:diohub/common/nav_center/models/compose_bar_config.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diohub/common/extensions/async_value_logging.dart';

/// Provider that supplies the async fetcher for @-mention candidates.
/// Override with [ProviderScope] when showing [MentionSuggestionsOverlay].
final mentionCandidatesFetcherProvider =
    Provider<Future<List<MentionCandidate>> Function()?>((ref) => null);

final mentionCandidatesProvider =
    FutureProvider.autoDispose<List<MentionCandidate>>(
  (ref) async {
    final getCandidates = ref.watch(mentionCandidatesFetcherProvider);
    if (getCandidates == null) return <MentionCandidate>[];
    return getCandidates();
  },
);

/// Overlay that shows filtered user suggestions when the user types `@` in the
/// compose field. Tapping a suggestion inserts `@username` at the cursor.
/// Requires [mentionCandidatesFetcherProvider] to be overridden with a non-null fetcher.
class MentionSuggestionsOverlay extends ConsumerStatefulWidget {
  const MentionSuggestionsOverlay({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  ConsumerState<MentionSuggestionsOverlay> createState() =>
      _MentionSuggestionsOverlayState();
}

class _MentionSuggestionsOverlayState
    extends ConsumerState<MentionSuggestionsOverlay> {
  String _prefix = '';
  int _selectedIndex = 0;

  static final RegExp _mentionPattern = RegExp(r'@(\w*)$');

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  List<MentionCandidate> _filterCandidates(List<MentionCandidate> candidates) {
    final lower = _prefix.toLowerCase();
    return lower.isEmpty
        ? candidates
        : candidates
            .where((c) => c.login.toLowerCase().startsWith(lower))
            .toList();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    if (cursorPos < 0 || cursorPos > text.length) return;
    final beforeCursor = text.substring(0, cursorPos);
    final match = _mentionPattern.firstMatch(beforeCursor);
    if (match != null) {
      setState(() {
        _prefix = match.group(1) ?? '';
        _selectedIndex = 0;
      });
    }
  }

  void _insert(String login) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPos);
    final match = _mentionPattern.firstMatch(beforeCursor);
    if (match != null) {
      final start = match.start;
      final newText = text.replaceRange(start, cursorPos, '@$login ');
      widget.controller.text = newText;
      widget.controller.selection =
          TextSelection.collapsed(offset: start + login.length + 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncCandidates = ref.watch(mentionCandidatesProvider);
    return asyncCandidates.whenOrShrink(
      debugLabel: 'mentionSuggestions',
      data: (List<MentionCandidate> candidates) {
        final filtered = _filterCandidates(candidates);
        if (filtered.isEmpty) return const SizedBox.shrink();
        final int maxIndex = filtered.isEmpty ? 0 : filtered.length - 1;
        final int clampedIndex = _selectedIndex.clamp(0, maxIndex);
        if (_selectedIndex != clampedIndex) _selectedIndex = clampedIndex;
        final spacing = context.spacing;
        final theme = Theme.of(context);
        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, minWidth: 180),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: spacing.tightSpacing),
              itemExtent: 48,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final candidate = filtered[index];
                final isSelected = index == clampedIndex;
                return InkWell(
                  onTap: () => _insert(candidate.login),
                  child: Container(
                    color: isSelected
                        ? theme.colorScheme.surfaceContainerHighest
                        : null,
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.sectionSpacing,
                      vertical: spacing.compactSpacing,
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          avatarUrl: candidate.avatarUrl,
                          size: 24,
                        ),
                        spacing.itemGap,
                        Text(
                          candidate.login,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
