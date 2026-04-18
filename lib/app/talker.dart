import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Global Talker instance for app-wide logging, Dio, and Riverpod observer.
final Talker appTalker = Talker(
  settings: TalkerSettings(
    maxHistoryItems: 1000, // ring buffer size
    useConsoleLogs: kDebugMode,
  ),
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(
      level: kDebugMode ? LogLevel.verbose : LogLevel.warning,
    ),
  ),
);
