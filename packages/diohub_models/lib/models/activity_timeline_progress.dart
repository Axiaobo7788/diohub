import 'package:diohub_models/models/activity/user_activity_timeline_data.dart';

/// Sealed class representing the state of activity timeline loading
sealed class ActivityTimelineState {}

/// Loading state with progress information
class ActivityTimelineLoading extends ActivityTimelineState {
  ActivityTimelineLoading({
    required this.phase,
    required this.current,
    required this.total,
    required this.message,
    this.eventCount = 0,
  });
  final String phase;
  final int current;
  final int total;
  final String message;
  final int eventCount;

  double get progress => total > 0 ? current / total : 0.0;
}

/// Success state with timeline data
class ActivityTimelineSuccess extends ActivityTimelineState {
  ActivityTimelineSuccess(this.data);
  final UserActivityTimelineData data;
}

/// Error state
class ActivityTimelineError extends ActivityTimelineState {
  ActivityTimelineError({
    required this.message,
    required this.error,
    this.stackTrace,
  });
  final String message;
  final Object error;
  final StackTrace? stackTrace;
}
