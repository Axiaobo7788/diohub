import 'package:diohub/app/app_logger.dart';
import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/discussions/discussion_upvote_mutation_provider.dart';
import 'package:diohub/providers/repository/release_discussion_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Upvote button for a discussion. Toggles add/remove with optimistic UI.
class DiscussionUpvoteButton extends ConsumerStatefulWidget {
  const DiscussionUpvoteButton({
    required this.discussionId,
    required this.upvoteCount,
    required this.viewerHasUpvoted,
    required this.repoRef,
    required this.discussionNumber,
    super.key,
  });

  final String discussionId;
  final int upvoteCount;
  final bool viewerHasUpvoted;
  final RepoRef repoRef;
  final int discussionNumber;

  @override
  ConsumerState<DiscussionUpvoteButton> createState() =>
      _DiscussionUpvoteButtonState();
}

class _DiscussionUpvoteButtonState
    extends ConsumerState<DiscussionUpvoteButton> {
  late int _localCount;
  late bool _localHasUpvoted;

  @override
  void initState() {
    super.initState();
    _localCount = widget.upvoteCount;
    _localHasUpvoted = widget.viewerHasUpvoted;
  }

  @override
  void didUpdateWidget(final DiscussionUpvoteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.upvoteCount != widget.upvoteCount ||
        oldWidget.viewerHasUpvoted != widget.viewerHasUpvoted) {
      _localCount = widget.upvoteCount;
      _localHasUpvoted = widget.viewerHasUpvoted;
    }
  }

  Future<void> _toggle() async {
    setState(() {
      if (_localHasUpvoted) {
        _localCount = (_localCount - 1).clamp(0, 0x7fffffff);
        _localHasUpvoted = false;
      } else {
        _localCount++;
        _localHasUpvoted = true;
      }
    });
    final notifier =
        ref.read(discussionUpvoteMutationProvider(widget.discussionId).notifier);
    if (_localHasUpvoted) {
      await notifier.addUpvote();
    } else {
      await notifier.removeUpvote();
    }
    if (mounted) {
      ref.invalidate(discussionByNumberProvider(
        DiscussionRef(repo: widget.repoRef, number: widget.discussionNumber),
      ));
    }
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SubmitButton(
      variant: SubmitButtonVariant.text,
      onSubmit: _toggle,
      onError: (e) {
        AppLogger.warning(
          'Discussion upvote mutation failed',
          error: e,
          stackTrace: StackTrace.current,
          tag: 'DiscussionUpvoteButton',
        );
        if (mounted) {
          setState(() {
            _localCount = widget.upvoteCount;
            _localHasUpvoted = widget.viewerHasUpvoted;
          });
        }
      },
      icon: Icon(
        Octicons.arrow_up,
        size: 18,
        color: _localHasUpvoted ? cs.primary : cs.onSurfaceVariant,
      ),
      label: (isSubmitting) => Text(
        '$_localCount',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: _localHasUpvoted ? cs.primary : null,
        ),
      ),
    );
  }
}
