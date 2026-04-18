/// Minimal DTO for a check suite from the GitHub Checks API
/// (e.g. GET /repos/{owner}/{repo}/check-suites/{check_suite_id}).
class CheckSuiteNotificationDto {
  const CheckSuiteNotificationDto({
    this.conclusion,
    this.status,
    this.appName,
  });

  factory CheckSuiteNotificationDto.fromJson(final Map<String, dynamic> json) {
    final Map<String, dynamic>? app = json['app'] as Map<String, dynamic>?;
    return CheckSuiteNotificationDto(
      conclusion: json['conclusion'] as String?,
      status: json['status'] as String?,
      appName: app?['name'] as String?,
    );
  }

  final String? conclusion;
  final String? status;
  final String? appName;
}
