import 'package:flutter/widgets.dart';

/// Indicator displayed in the trailing area of tabs.
sealed class TrailingIndicator {
  const TrailingIndicator();
}

/// Badge indicator with a count callback
final class CountTrailing extends TrailingIndicator {
  const CountTrailing(this.count);
  
  /// Callback that returns the count to display, or null if no badge should be shown
  final int? Function() count;
}

/// Activity indicator (loading spinner)
final class LoadingTrailing extends TrailingIndicator {
  const LoadingTrailing();
}

/// Compound trailing indicator containing multiple children
final class CompoundTrailing extends TrailingIndicator {
  const CompoundTrailing(this.children);
  
  /// Child indicators to display
  final List<TrailingIndicator> children;
}

/// Icon indicator
final class IconTrailing extends TrailingIndicator {
  const IconTrailing(this.icon);
  
  /// Icon to display
  final IconData icon;
}
