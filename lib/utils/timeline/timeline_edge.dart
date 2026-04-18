import 'package:diohub_graphql/queries/issues_pulls/issue_pull_typedefs.dart';

/// Sealed type representing a timeline edge from either an Issue or Pull Request.
/// This eliminates the need for dynamic types in timeline processing.
sealed class TimelineEdge {
  const TimelineEdge();

  /// Get the timeline node from the edge
  Object? get node;

  /// Get the cursor for pagination
  String? get cursor;
}

/// Wrapper for IssueTimelineEdge
class IssueTimelineEdgeWrapper extends TimelineEdge {
  const IssueTimelineEdgeWrapper(this.edge);

  final IssueTimelineEdge edge;

  @override
  Object? get node => edge.node;

  @override
  String? get cursor => edge.cursor;
}

/// Wrapper for PullTimelineEdge
class PullTimelineEdgeWrapper extends TimelineEdge {
  const PullTimelineEdgeWrapper(this.edge);

  final PullTimelineEdge edge;

  @override
  Object? get node => edge.node;

  @override
  String? get cursor => edge.cursor;
}
