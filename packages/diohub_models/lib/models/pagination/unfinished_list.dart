/// A list that may be truncated (e.g. from GraphQL first: N).
/// [totalCount] is the full count; [limitedAvailableList] is the fetched slice.
class UnfinishedList<T> {
  UnfinishedList({
    required this.limitedAvailableList,
    final int? totalCount,
  }) : totalCount = totalCount ?? limitedAvailableList.length;
  final int totalCount;
  final List<T> limitedAvailableList;

  bool get isComplete => totalCount == limitedAvailableList.length;
}

/// Wraps a node with cursor for cursor-based pagination.
class NodeWithPaginationInfo<T> {
  NodeWithPaginationInfo({
    required this.node,
    required this.cursor,
  });

  NodeWithPaginationInfo.pageKey({
    required this.node,
    required final int pageKey,
  }) : cursor = pageKey.toString();

  /// Build from a GQL connection edge. Pass typed getters to avoid dynamic.
  factory NodeWithPaginationInfo.fromEdge(
    Object edge, {
    required T? Function(Object) getNode,
    required String Function(Object) getCursor,
  }) =>
      NodeWithPaginationInfo<T>(
        node: getNode(edge)!,
        cursor: getCursor(edge),
      );

  final T node;

  final String cursor;
}
