import 'package:diohub/common/misc/submit_button.dart';
import 'package:diohub_graphql/queries/users/user_typedefs.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub/providers/users/user_providers.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet to set or clear the viewer's status (emoji + message, busy, expiry).
/// Used from the profile popup when viewing own profile.
class StatusEditorSheet extends ConsumerStatefulWidget {
  const StatusEditorSheet({
    required this.userRef,
    super.key,
  });

  final UserRef userRef;

  @override
  ConsumerState<StatusEditorSheet> createState() => _StatusEditorSheetState();
}

class _StatusEditorSheetState extends ConsumerState<StatusEditorSheet> {
  late TextEditingController _emojiController;
  late TextEditingController _messageController;
  bool _limitedAvailability = false;
  StatusExpiry _expiry = StatusExpiry.never;
  bool _initializedFromProfile = false;

  static const List<String> _defaultEmojis = <String>[
    '💼',
    '🏠',
    '🏖️',
    '🤒',
    '✈️',
    '📵',
    '🎉',
    '☕',
    '💻',
    '📚',
    '🎯',
    '🔥',
    '✅',
    '⏸️',
    '🌙',
    '❤️',
  ];

  @override
  void initState() {
    super.initState();
    _emojiController = TextEditingController();
    _messageController = TextEditingController();
  }

  void _maybeInitFromProfile(UserProfileData data) {
    if (_initializedFromProfile) return;
    final status = data.owner.maybeWhen(
      user: (u) => u.status,
      organization: (_) => null,
      orElse: () => null,
    );
    if (status != null) {
      _initializedFromProfile = true;
      _emojiController.text = status.emoji ?? '';
      _messageController.text = status.message ?? '';
      _limitedAvailability = status.indicatesLimitedAvailability;
    }
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  DateTime? _expiryToDateTime() {
    final now = DateTime.now();
    switch (_expiry) {
      case StatusExpiry.never:
        return null;
      case StatusExpiry.min30:
        return now.add(const Duration(minutes: 30));
      case StatusExpiry.hour1:
        return now.add(const Duration(hours: 1));
      case StatusExpiry.hour4:
        return now.add(const Duration(hours: 4));
      case StatusExpiry.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case StatusExpiry.week:
        return now.add(const Duration(days: 7));
      case StatusExpiry.custom:
        return null;
    }
  }

  Future<void> _save() async {
    final String? emoji = _emojiController.text.trim().isEmpty
        ? null
        : _emojiController.text.trim();
    final String? message = _messageController.text.trim().isEmpty
        ? null
        : _messageController.text.trim();
    await ref.read(userProvider(widget.userRef).notifier).setStatus(
          emoji: emoji,
          message: message,
          limitedAvailability: _limitedAvailability,
          expiresAt: _expiryToDateTime(),
        );
  }

  Future<void> _clear() async {
    await ref.read(userProvider(widget.userRef).notifier).clearStatus();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProvider(widget.userRef));
    profileAsync.whenData(_maybeInitFromProfile);
    final spacing = context.spacing;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          spacing.pagePadding.left,
          spacing.tightSpacing,
          spacing.pagePadding.right,
          spacing.pagePadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _emojiController,
            decoration: const InputDecoration(
              labelText: 'Emoji',
              hintText: 'e.g. 🏖️ or :palm_tree:',
            ),
            maxLength: 20,
          ),
          SizedBox(
            height: 48,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
              ),
              itemCount: _defaultEmojis.length,
              itemBuilder: (BuildContext context, int index) {
                final emoji = _defaultEmojis[index];
                return IconButton(
                  onPressed: () {
                    _emojiController.text = emoji;
                  },
                  icon: Text(emoji, style: const TextStyle(fontSize: 24)),
                );
              },
            ),
          ),
          context.spacing.itemGap,
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'e.g. On vacation',
            ),
            maxLines: 2,
          ),
          SwitchListTile.adaptive(
            value: _limitedAvailability,
            onChanged: (bool v) => setState(() => _limitedAvailability = v),
            title: Text('Busy', style: theme.textTheme.bodyLarge),
          ),
          DropdownButtonFormField<StatusExpiry>(
            value: _expiry,
            decoration: const InputDecoration(labelText: 'Expires'),
            items: const <DropdownMenuItem<StatusExpiry>>[
              DropdownMenuItem(value: StatusExpiry.never, child: Text('Never')),
              DropdownMenuItem(
                  value: StatusExpiry.min30, child: Text('30 minutes')),
              DropdownMenuItem(
                  value: StatusExpiry.hour1, child: Text('1 hour')),
              DropdownMenuItem(
                  value: StatusExpiry.hour4, child: Text('4 hours')),
              DropdownMenuItem(value: StatusExpiry.today, child: Text('Today')),
              DropdownMenuItem(
                  value: StatusExpiry.week, child: Text('This week')),
            ],
            onChanged: (StatusExpiry? v) =>
                setState(() => _expiry = v ?? StatusExpiry.never),
          ),
          context.spacing.sectionGap,
          Row(
            children: <Widget>[
              SubmitButton(
                variant: SubmitButtonVariant.text,
                onSubmit: _clear,
                onSuccess: () => Navigator.of(context).pop(true),
                label: (_) => const Text('Clear status'),
              ),
              const Spacer(),
              SubmitButton(
                onSubmit: _save,
                onSuccess: () => Navigator.of(context).pop(true),
                label: (isSubmitting) =>
                    Text(isSubmitting ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum StatusExpiry {
  never,
  min30,
  hour1,
  hour4,
  today,
  week,
  custom,
}
