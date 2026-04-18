import 'package:diohub_models/models/search/qualifier.dart';
import 'package:diohub_models/models/search/search_expression.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Chip displaying a single qualifier (e.g. is:open, assignee:me) with optional avatar/icon.
class QualifierChip extends StatelessWidget {
  const QualifierChip({
    required this.expression,
    required this.onDelete,
    super.key,
    this.onTap,
  });

  final QualifierExpression expression;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Qualifier q = expression.qualifier;
    return InputChip(
      avatar: _avatarFor(context, q),
      label: Text(_labelFor(q)),
      deleteIcon: const Icon(Icons.cancel, size: 18),
      onDeleted: onDelete,
      onPressed: onTap != null ? () => onTap!() : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget? _avatarFor(BuildContext context, Qualifier q) {
    return switch (q) {
      IsQualifier(option: IsOption.open) => Icon(
          Octicons.issue_opened,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      IsQualifier(option: IsOption.closed) => Icon(
          Octicons.issue_closed,
          size: 18,
          color: Theme.of(context).colorScheme.secondary,
        ),
      IsQualifier(option: IsOption.merged) => Icon(
          Octicons.git_merge,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
      UserQualifier(:final user) => CircleAvatar(
          radius: 10,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            user.login.isNotEmpty
                ? user.login.substring(0, 1).toUpperCase()
                : '?',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      _ => null,
    };
  }

  String _labelFor(Qualifier q) {
    return expression.negated ? '-${q.toQueryString()}' : q.toQueryString();
  }
}
