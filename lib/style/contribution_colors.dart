import 'package:flutter/material.dart';

/// Shared colors for contribution types (commits, PRs, issues, reviews, repos).
/// Use these so contribution chips, stats, and breakdowns stay consistent.
class ContributionColors {
  ContributionColors._();

  static const Color commit = Color(0xFF2196F3);
  static const Color pullRequest = Color(0xFF9C27B0);
  static const Color issue = Color(0xFF4CAF50);
  static const Color review = Color(0xFFFF9800);
  static const Color repo = Color(0xFF795548);
}
