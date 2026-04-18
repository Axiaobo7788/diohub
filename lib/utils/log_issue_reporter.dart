import 'package:diohub/app/scoped_talker_log.dart';
import 'package:diohub/common/logging/structured_log_entry.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Target repository and label for "Report issue" from a log entry.
class ReportTarget {
  const ReportTarget({required this.repo, required this.label});
  final RepoRef repo;
  final String label;
}

/// Helpers to build issue title/body from [TalkerData] and navigate to create-issue flow.
class LogIssueReporter {
  LogIssueReporter._();

  static const RepoRef _appRepo =
      RepoRef(owner: 'namanshergill', name: 'diohub');

  /// Returns the single report target: the app repo. Logs are always app-side
  /// (API errors, parsing, bugs); other repos have no stake in that.
  static List<ReportTarget> getTargets(TalkerData entry) {
    return [
      ReportTarget(repo: _appRepo, label: 'Report to DioHub (app bug)'),
    ];
  }

  /// Same as [getTargets] for [StructuredLogEntry] (persisted log).
  static List<ReportTarget> getTargetsFromStructured(StructuredLogEntry entry) {
    return [
      ReportTarget(repo: _appRepo, label: 'Report to DioHub (app bug)'),
    ];
  }

  /// Builds markdown body for the issue: level, time, app version, optional entity path,
  /// message in code block, optional error and stack in <details>.
  static Future<String> buildIssueBody(TalkerData entry) async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String version = '${info.version}+${info.buildNumber}';
    final StringBuffer sb = StringBuffer();
    sb.writeln('- **Level**: ${entry.logLevel?.name ?? "log"}');
    sb.writeln('- **Time**: ${entry.time.toIso8601String()}');
    sb.writeln('- **App version**: $version');
    if (entry is ScopedTalkerLog) {
      sb.writeln('- **Entity**: `${entry.entityRef.apiPath}`');
    }
    sb.writeln();
    sb.writeln('```');
    sb.writeln(entry.message ?? '(no message)');
    sb.writeln('```');
    final bool hasError = entry.exception != null ||
        entry.error != null ||
        entry.stackTrace != null;
    if (hasError) {
      sb.writeln();
      sb.writeln('<details><summary>Error / stack</summary>');
      if (entry.exception != null)
        sb.writeln('\nException: ${entry.exception}');
      if (entry.error != null) sb.writeln('\nError: ${entry.error}');
      if (entry.stackTrace != null)
        sb.writeln('\n```\n${entry.stackTrace}\n```');
      sb.writeln('</details>');
    }
    return sb.toString();
  }

  /// Truncates [entry.message] to 80 chars and prefixes with `[Auto-report] `.
  static String buildIssueTitle(TalkerData entry) {
    final String msg = entry.message ?? '(no message)';
    final String truncated = msg.length > 80 ? '${msg.substring(0, 80)}…' : msg;
    return '[Auto-report] $truncated';
  }

  /// Same as [buildIssueTitle] for [StructuredLogEntry].
  static String buildIssueTitleFromStructured(StructuredLogEntry entry) {
    final String msg = entry.message;
    final String truncated = msg.length > 80 ? '${msg.substring(0, 80)}…' : msg;
    return '[Auto-report] $truncated';
  }

  /// Builds markdown body from [StructuredLogEntry] for report flow.
  static Future<String> buildIssueBodyFromStructured(
      StructuredLogEntry entry) async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    final String version = '${info.version}+${info.buildNumber}';
    final StringBuffer sb = StringBuffer();
    sb.writeln('- **Level**: ${entry.level}');
    sb.writeln('- **Time**: ${entry.createdAt.toIso8601String()}');
    sb.writeln('- **App version**: $version');
    if (entry.entityPath != null) {
      sb.writeln('- **Entity**: `${entry.entityPath}`');
    }
    sb.writeln();
    sb.writeln('```');
    sb.writeln(entry.message);
    sb.writeln('```');
    if (entry.errorMessage != null || entry.stackTrace != null) {
      sb.writeln();
      sb.writeln('<details><summary>Error / stack</summary>');
      if (entry.errorMessage != null) sb.writeln('\n${entry.errorMessage}');
      if (entry.stackTrace != null)
        sb.writeln('\n```\n${entry.stackTrace}\n```');
      sb.writeln('</details>');
    }
    return sb.toString();
  }

  /// To navigate to the create-issue screen with a pre-filled draft, use
  /// [navigateToCreateIssueFromLog] from the view layer
  /// (`lib/view/log_report_navigation.dart`).
}
