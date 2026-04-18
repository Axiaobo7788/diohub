/// String comparison and utility extensions.
extension StringCompareExt on String {
  /// Case-insensitive string equality check.
  bool isStringEqual(String? other) => toLowerCase() == other?.toLowerCase();
}
