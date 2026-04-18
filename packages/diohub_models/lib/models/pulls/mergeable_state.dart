enum MergeableState {
  conflicting,
  mergeable,
  unknown;

  static MergeableState? fromString(String? value) {
    if (value == null) return null;
    return switch (value.toUpperCase()) {
      'CONFLICTING' => MergeableState.conflicting,
      'MERGEABLE' => MergeableState.mergeable,
      'UNKNOWN' => MergeableState.unknown,
      _ => null,
    };
  }
}
