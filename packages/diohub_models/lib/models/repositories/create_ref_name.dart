import 'package:flutter/material.dart' show IconData;
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

/// Describes a ref to create via GraphQL createRef.
/// [qualifiedName] is the full ref path (e.g. refs/heads/foo, refs/tags/v1.0).
/// Use [icon] and [displayLabel] for UI instead of passing branch/tag bools.
///
/// Create via [CreateRefName.branch] or [CreateRefName.tag]; use [withName] to
/// clone with a new name (e.g. after user picks type then enters name).
sealed class CreateRefName {
  const CreateRefName(this.name);

  /// Short name (branch or tag name only).
  final String name;

  /// Full ref name for the API (refs/heads/... or refs/tags/...).
  String get qualifiedName;

  /// Icon for this ref type (branch vs tag). Use in sheets/buttons instead of bools.
  IconData get icon;

  /// Label for this ref type: "Branch" or "Tag".
  String get displayLabel;

  /// Whether this is a tag (vs branch). Avoid using when [icon]/[displayLabel] suffice.
  bool get isTag;

  /// Same ref type with a new name. Use when the user picks branch/tag then enters name.
  CreateRefName withName(String newName);

  @override
  String toString() => qualifiedName;

  /// Create a branch ref (refs/heads/[name]).
  const factory CreateRefName.branch(String name) = _BranchRefName;

  /// Create a tag ref (refs/tags/[name]).
  const factory CreateRefName.tag(String name) = _TagRefName;
}

class _BranchRefName extends CreateRefName {
  const _BranchRefName(super.name);

  @override
  String get qualifiedName => 'refs/heads/$name';

  @override
  IconData get icon => Octicons.git_branch;

  @override
  String get displayLabel => 'Branch';

  @override
  bool get isTag => false;

  @override
  CreateRefName withName(String newName) => CreateRefName.branch(newName);
}

class _TagRefName extends CreateRefName {
  const _TagRefName(super.name);

  @override
  String get qualifiedName => 'refs/tags/$name';

  @override
  IconData get icon => Octicons.tag;

  @override
  String get displayLabel => 'Tag';

  @override
  bool get isTag => true;

  @override
  CreateRefName withName(String newName) => CreateRefName.tag(newName);
}
