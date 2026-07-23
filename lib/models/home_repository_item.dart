import 'package:flutter/foundation.dart';

@immutable
class HomeRepositoryItem {
  const HomeRepositoryItem({
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
