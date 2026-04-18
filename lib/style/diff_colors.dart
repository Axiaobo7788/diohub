import 'package:diohub_models/models/commits/commit_model.dart';
import 'package:flutter/material.dart';

/// GitHub-standard colors for diff/changed-files UI (additions, deletions, etc.).
/// Use these so diff bars, stats, and chips stay consistent across cards and metadata.
class DiffColors {
  DiffColors._();

  /// Additions / success (e.g. +123 lines).
  static const Color addition = Color(0xFF2DA44E);

  /// Deletions / removal (e.g. -45 lines).
  static const Color deletion = Color(0xFFCF222E);

  /// Modified (e.g. changed but not add/delete).
  static const Color modified = Color(0xFFBF8700);

  /// Renamed (e.g. file rename).
  static const Color renamed = Color(0xFF1F6FEB);

  /// Returns the color for a [DiffStatus] (e.g. added → addition, removed → deletion).
  static Color forDiffStatus(final DiffStatus? status) {
    switch (status) {
      case DiffStatus.added:
        return addition;
      case DiffStatus.removed:
        return deletion;
      case DiffStatus.modified:
      case DiffStatus.changed:
      case DiffStatus.unchanged:
        return modified;
      case DiffStatus.renamed:
      case DiffStatus.copied:
        return renamed;
      case null:
        return modified;
    }
  }

  /// Returns the color for a status string (e.g. CHECK_SUCCESS → addition, CHECK_FAILURE → deletion).
  static Color forStatus(final String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
      case 'CHECK_SUCCESS':
      case 'COMPLETED':
        return addition;
      case 'FAILURE':
      case 'CHECK_FAILURE':
      case 'ERROR':
      case 'ACTION_REQUIRED':
        return deletion;
      case 'PENDING':
      case 'IN_PROGRESS':
      case 'QUEUED':
        return modified;
      default:
        return addition;
    }
  }
}
