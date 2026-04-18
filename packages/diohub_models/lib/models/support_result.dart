/// Result of a support mutation (create or update).
sealed class SupportResult {}

class SupportSuccess extends SupportResult {
  SupportSuccess(this.data);
  final dynamic data;
}

class SupportNeedsBilling extends SupportResult {}

class SupportError extends SupportResult {
  SupportError(this.message);
  final String message;
}
