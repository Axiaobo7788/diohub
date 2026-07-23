import 'package:diohub/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Formats application-owned timestamps using the current Flutter locale.
///
/// GitHub content remains untouched; this only localizes DioHub's surrounding
/// time label. Compact units intentionally stay language-neutral (`2m`, `3h`).
String formatRelativeTime(
  final BuildContext context,
  final DateTime value, {
  final bool compact = false,
}) {
  final DateTime date = value.toLocal();
  final Duration difference = DateTime.now().difference(date);
  if (difference.isNegative) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }
  if (difference.inSeconds < 60) {
    return compact ? 'now' : context.l10n.relativeJustNow;
  }
  if (difference.inMinutes < 60) {
    return compact
        ? '${difference.inMinutes}m'
        : context.l10n.relativeMinutesAgo(difference.inMinutes);
  }
  if (difference.inHours < 24) {
    return compact
        ? '${difference.inHours}h'
        : context.l10n.relativeHoursAgo(difference.inHours);
  }

  final int days = difference.inDays;
  if (days == 1) {
    return compact ? '1d' : context.l10n.relativeYesterday;
  }
  if (days < 7) {
    return compact ? '${days}d' : context.l10n.relativeDaysAgo(days);
  }

  final int weeks = days ~/ 7;
  if (weeks < 4) {
    return compact ? '${weeks}w' : context.l10n.relativeWeeksAgo(weeks);
  }

  final int months = days ~/ 30;
  if (months < 12) {
    return compact ? '${months}mo' : context.l10n.relativeMonthsAgo(months);
  }

  final int years = days ~/ 365;
  if (years < 2) {
    return compact ? '1y' : context.l10n.relativeYearsAgo(1);
  }
  return MaterialLocalizations.of(context).formatMediumDate(date);
}
