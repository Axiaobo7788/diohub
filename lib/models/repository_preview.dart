import 'package:flutter/foundation.dart';

/// Small, trusted repository snapshot used while the full repository query is
/// still in flight.
///
/// The values come from an already-rendered repository entry (for example the
/// Home top-repositories list). They are never used as a replacement for the
/// full repository model; they only keep the destination shell stable and let
/// the default branch start loading independently.
@immutable
class RepositoryPreview {
  const RepositoryPreview({
    required this.fullName,
    required this.name,
    required this.owner,
    required this.ownerAvatarUrl,
    required this.isPrivate,
    this.nodeId,
    this.defaultBranch,
  });

  final String fullName;
  final String name;
  final String owner;
  final String? ownerAvatarUrl;
  final bool isPrivate;
  final String? nodeId;
  final String? defaultBranch;
}
