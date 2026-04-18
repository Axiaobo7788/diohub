/// One code scanning alert from REST GET .../code-scanning/alerts.
class CodeScanningAlertItem {
  const CodeScanningAlertItem({
    required this.number,
    required this.state,
    required this.severity,
    required this.toolName,
    this.toolVersion,
    required this.ruleName,
    required this.ruleDescription,
    this.securitySeverityLevel,
    required this.htmlUrl,
    required this.createdAt,
    this.fixedAt,
    this.dismissedAt,
    this.dismissedReason,
    this.dismissedComment,
    this.mostRecentInstanceRef,
    this.mostRecentInstancePath,
    this.mostRecentInstanceStartLine,
  });

  final int number;
  final String state;
  final String severity;
  final String toolName;
  final String? toolVersion;
  final String ruleName;
  final String ruleDescription;
  final String? securitySeverityLevel;
  final String htmlUrl;
  final DateTime createdAt;
  final DateTime? fixedAt;
  final DateTime? dismissedAt;
  final String? dismissedReason;
  final String? dismissedComment;
  final String? mostRecentInstanceRef;
  final String? mostRecentInstancePath;
  final int? mostRecentInstanceStartLine;

  factory CodeScanningAlertItem.fromJson(Map<String, dynamic> json) {
    final rule = json['rule'] as Map<String, dynamic>?;
    final tool = json['tool'] as Map<String, dynamic>?;
    final instance = json['most_recent_instance'] as Map<String, dynamic>?;
    final location = instance?['location'] as Map<String, dynamic>?;

    return CodeScanningAlertItem(
      number: json['number'] as int,
      state: json['state'] as String? ?? 'open',
      severity: (rule?['severity'] ??
              rule?['security_severity_level'] ??
              json['severity']) as String? ??
          'warning',
      toolName: tool?['name'] as String? ?? 'Code scanning',
      toolVersion: tool?['version'] as String?,
      ruleName: rule?['name'] as String? ?? '',
      ruleDescription: rule?['description'] as String? ??
          rule?['full_description'] as String? ??
          '',
      securitySeverityLevel: rule?['security_severity_level'] as String?,
      htmlUrl: json['html_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      fixedAt: json['fixed_at'] != null
          ? DateTime.tryParse(json['fixed_at'] as String)
          : null,
      dismissedAt: json['dismissed_at'] != null
          ? DateTime.tryParse(json['dismissed_at'] as String)
          : null,
      dismissedReason: json['dismissed_reason'] as String?,
      dismissedComment: json['dismissed_comment'] as String?,
      mostRecentInstanceRef: instance?['ref'] as String?,
      mostRecentInstancePath: location?['path'] as String?,
      mostRecentInstanceStartLine: location?['start_line'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'state': state,
        'severity': severity,
        'tool_name': toolName,
        if (toolVersion != null) 'tool_version': toolVersion,
        'rule_name': ruleName,
        'rule_description': ruleDescription,
        if (securitySeverityLevel != null)
          'security_severity_level': securitySeverityLevel,
        'html_url': htmlUrl,
        'created_at': createdAt.toIso8601String(),
        if (fixedAt != null) 'fixed_at': fixedAt!.toIso8601String(),
        if (dismissedAt != null) 'dismissed_at': dismissedAt!.toIso8601String(),
        if (dismissedReason != null) 'dismissed_reason': dismissedReason,
        if (dismissedComment != null) 'dismissed_comment': dismissedComment,
        if (mostRecentInstanceRef != null)
          'most_recent_instance_ref': mostRecentInstanceRef,
        if (mostRecentInstancePath != null)
          'most_recent_instance_path': mostRecentInstancePath,
        if (mostRecentInstanceStartLine != null)
          'most_recent_instance_start_line': mostRecentInstanceStartLine,
      };
}
