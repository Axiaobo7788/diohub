import 'package:flutter/material.dart';

/// A single day in the contribution calendar
class ContributionDay {
  const ContributionDay({
    required this.date,
    required this.count,
    this.color,
    this.level,
  });

  final DateTime date;
  final int count;
  final Color? color;
  final ContributionLevel? level;
}

/// Contribution level enum
enum ContributionLevel {
  none,
  firstQuartile,
  secondQuartile,
  thirdQuartile,
  fourthQuartile,
}
