import 'package:diohub/common/widgets/tinted_chip.dart';
import 'package:diohub_models/models/issues/author_association.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:diohub/utils/utils.dart';
import 'package:flutter/material.dart';

/// Tiny text badge showing author role (OWNER, MEMBER, CONTRIBUTOR, etc.).
class AuthorAssociationBadge extends StatelessWidget {
  const AuthorAssociationBadge({
    required this.association,
    super.key,
  });

  final String? association;

  static const Set<AuthorAssociation> _showValues = <AuthorAssociation>{
    AuthorAssociation.owner,
    AuthorAssociation.member,
    AuthorAssociation.contributor,
    AuthorAssociation.firstTimeContributor,
    AuthorAssociation.mannequin,
  };

  @override
  Widget build(final BuildContext context) {
    if (association == null || association!.isEmpty) {
      return const SizedBox.shrink();
    }
    final AuthorAssociation assoc = AuthorAssociation.fromString(association!);
    if (assoc == AuthorAssociation.none || 
        assoc == AuthorAssociation.collaborator ||
        !_showValues.contains(assoc)) {
      return const SizedBox.shrink();
    }
    final ColorScheme cs = context.colorScheme;
    final Color color = _tintForAssociation(assoc, cs);
    
    return TintedChip(
      color: color,
      label: assoc.displayName,
      padding: context.spacing.badgePadding,
      labelStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
      ),
    );
  }

  Color _tintForAssociation(final AuthorAssociation association, final ColorScheme cs) {
    switch (association) {
      case AuthorAssociation.owner:
        return cs.primary;
      case AuthorAssociation.member:
        return cs.secondary;
      case AuthorAssociation.contributor:
        return cs.tertiary;
      case AuthorAssociation.firstTimeContributor:
        return cs.primary.withValues(alpha: 0.9);
      case AuthorAssociation.mannequin:
        return cs.onSurfaceVariant;
      default:
        return cs.onSurfaceVariant;
    }
  }
}
