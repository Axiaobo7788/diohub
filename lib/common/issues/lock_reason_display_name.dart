import 'package:diohub_graphql/schema_typedefs.dart';

/// Human-readable label for [LockReason] (e.g. for banner and status section).
String lockReasonDisplayName(final LockReason reason) {
  return switch (reason) {
    LockReason.OFF_TOPIC => 'Off-topic',
    LockReason.RESOLVED => 'Resolved',
    LockReason.SPAM => 'Spam',
    LockReason.TOO_HEATED => 'Too heated',
    _ => 'Locked',
  };
}
