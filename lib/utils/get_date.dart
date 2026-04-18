import 'package:intl/intl.dart';

final DateFormat _dateFormatFull = DateFormat('MMM d, yyyy');
final DateFormat _dateFormatShort = DateFormat('MMM d');

/// Extension on [DateTime] to format dates as relative time or absolute dates.
extension DateTimeFormatting on DateTime {
  /// Formats the date as a relative time string (e.g., "2h ago", "3d ago")
  /// or an absolute date for older dates.
  ///
  /// [shorten] controls the format:
  /// - `true`: Short format (e.g., "2h", "3d", "Jan 15")
  /// - `false`: Long format (e.g., "2 hrs ago", "3 days ago", "Jan 15, 2024")
  String toRelativeDate({final bool shorten = true}) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(this);

    // Handle future dates (shouldn't happen but just in case)
    if (difference.isNegative) {
      return _dateFormatFull.format(this);
    }

    // Very recent (less than a minute)
    if (difference.inSeconds < 60) {
      return shorten ? 'now' : 'just now';
    }

    // Minutes ago
    if (difference.inMinutes < 60) {
      final int minutes = difference.inMinutes;
      if (shorten) {
        return '${minutes}m';
      }
      return minutes == 1 ? '1 min ago' : '$minutes mins ago';
    }

    // Hours ago
    if (difference.inHours < 24) {
      final int hours = difference.inHours;
      if (shorten) {
        return '${hours}h';
      }
      return hours == 1 ? '1 hr ago' : '$hours hrs ago';
    }

    // Days ago
    final int days = difference.inDays;
    if (days == 1) {
      return shorten ? '1d' : 'yesterday';
    }

    if (days < 7) {
      return shorten ? '${days}d' : '$days days ago';
    }

    // Weeks ago
    final int weeks = (days / 7).floor();
    if (weeks < 4) {
      if (shorten) {
        return '${weeks}w';
      }
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }

    // Months ago
    final int months = (days / 30).floor();
    if (months < 12) {
      if (shorten) {
        return '${months}mo';
      }
      return months == 1 ? '1 month ago' : '$months months ago';
    }

    // Years ago
    final int years = (days / 365).floor();
    if (years < 2) {
      return shorten ? '1y' : '1 year ago';
    }

    // For dates older than 1 year, show formatted date with full year
    if (shorten) {
      // Check if it's the current year
      if (this.year == now.year) {
        return _dateFormatShort.format(this);
      }
      return _dateFormatFull.format(this);
    } else {
      if (this.year == now.year) {
        return _dateFormatShort.format(this);
      }
      return _dateFormatFull.format(this);
    }
  }
}

/// Extension on nullable [DateTime] for convenience.
extension DateTimeFormattingNullable on DateTime? {
  /// Formats the date as a relative time string, or returns empty string if null.
  String toRelativeDate({final bool shorten = true}) {
    if (this == null) return '';
    return this!.toRelativeDate(shorten: shorten);
  }
}
