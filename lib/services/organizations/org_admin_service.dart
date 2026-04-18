import 'package:dio/dio.dart';
import 'package:diohub_models/models/pagination/paginated_result.dart';
import 'package:diohub/services/base/base_service.dart';
import 'package:diohub/services/base/rest_pagination_helper.dart';
import 'package:diohub_models/models/organizations/pat_request.dart';
import 'package:diohub_models/models/repositories/code_scanning_alert_item.dart';
import 'package:diohub_models/models/repositories/dependabot_alert_item.dart';
import 'package:diohub_models/models/repositories/secret_scanning_alert.dart';

/// Organization administration service: blocking, PAT requests, org-wide security.
/// Unlike viewer-scoped services, this requires org admin permissions.
class OrgAdminService extends BaseService {
  OrgAdminService(super.apiClient);

  // ============================================================================
  // Org-Level User Blocking
  // ============================================================================

  /// Blocks a user at the organization level. PUT /orgs/{org}/blocks/{username}.
  Future<void> blockUser(String org, String username) async {
    await rest.put<void>('/orgs/$org/blocks/$username');
  }

  /// Unblocks a user at the organization level. DELETE /orgs/{org}/blocks/{username}.
  Future<void> unblockUser(String org, String username) async {
    await rest.delete<void>('/orgs/$org/blocks/$username');
  }

  /// Returns true if the given user is blocked by the organization.
  /// GET /orgs/{org}/blocks/{username} returns 204 if blocked, 404 if not.
  Future<bool> isUserBlocked(String org, String username) async {
    try {
      await rest.get<void>('/orgs/$org/blocks/$username');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  // ============================================================================
  // Personal Access Token (PAT) Requests
  // ============================================================================

  /// Lists pending PAT requests for the organization.
  /// GET /orgs/{org}/personal-access-token-requests.
  Future<PaginatedResult<PatRequest>> listPatRequests(
    String org, {
    int page = 1,
    int perPage = 30,
    String? state, // pending, approved, denied
  }) async {
    final Response<dynamic> res = await rest.get<dynamic>(
      '/orgs/$org/personal-access-token-requests',
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (state != null && state.isNotEmpty) 'state': state,
      },
    );
    final List<Object?> raw = extractListFromResponse<Object?>(res);

    final List<PatRequest> items = raw
        .map((dynamic e) => PatRequest.fromJson(e as Map<String, dynamic>))
        .toList();
    return parsePaginatedRestResponse<PatRequest>(
      response: res,
      items: items,
      currentPage: page,
    );
  }

  /// Approves a PAT request.
  /// POST /orgs/{org}/personal-access-token-requests/{request_id}.
  Future<void> approvePatRequest(
    String org,
    int requestId, {
    String? reason,
  }) async {
    await rest.post<void>(
      '/orgs/$org/personal-access-token-requests/$requestId',
      data: <String, dynamic>{
        'action': 'approve',
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  /// Denies a PAT request.
  /// POST /orgs/{org}/personal-access-token-requests/{request_id}.
  Future<void> denyPatRequest(
    String org,
    int requestId, {
    String? reason,
  }) async {
    await rest.post<void>(
      '/orgs/$org/personal-access-token-requests/$requestId',
      data: <String, dynamic>{
        'action': 'deny',
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
  }

  // ============================================================================
  // Org-Wide Security Alerts
  // ============================================================================

  /// Lists code scanning alerts across all repositories in the organization.
  /// GET /orgs/{org}/code-scanning/alerts.
  Future<PaginatedResult<CodeScanningAlertItem>> listCodeScanningAlerts(
    String org, {
    String? state, // open, dismissed, fixed
    String? severity, // critical, high, medium, low
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final Response<dynamic> res = await rest.get<dynamic>(
        '/orgs/$org/code-scanning/alerts',
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (state != null && state.isNotEmpty) 'state': state,
          if (severity != null && severity.isNotEmpty) 'severity': severity,
        },
      );
      final List<Object?> raw = extractListFromResponse<Object?>(res);

      final List<CodeScanningAlertItem> items = raw
          .map(
            (dynamic e) =>
                CodeScanningAlertItem.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return parsePaginatedRestResponse<CodeScanningAlertItem>(
        response: res,
        items: items,
        currentPage: page,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return PaginatedResult(items: [], hasNextPage: false);
      }
      rethrow;
    }
  }

  /// Lists secret scanning alerts across all repositories in the organization.
  /// GET /orgs/{org}/secret-scanning/alerts.
  Future<PaginatedResult<SecretScanningAlert>> listSecretScanningAlerts(
    String org, {
    String? state, // open, resolved
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final Response<dynamic> res = await rest.get<dynamic>(
        '/orgs/$org/secret-scanning/alerts',
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (state != null && state.isNotEmpty) 'state': state,
        },
      );
      final List<Object?> raw = extractListFromResponse<Object?>(res);

      final List<SecretScanningAlert> items = raw
          .map(
            (dynamic e) =>
                SecretScanningAlert.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return parsePaginatedRestResponse<SecretScanningAlert>(
        response: res,
        items: items,
        currentPage: page,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return PaginatedResult(items: [], hasNextPage: false);
      }
      rethrow;
    }
  }

  /// Lists Dependabot alerts across all repositories in the organization.
  /// GET /orgs/{org}/dependabot/alerts.
  Future<PaginatedResult<DependabotAlertItem>> listDependabotAlerts(
    String org, {
    String? state, // auto_dismissed, dismissed, fixed, open
    String? severity, // critical, high, medium, low
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final Response<dynamic> res = await rest.get<dynamic>(
        '/orgs/$org/dependabot/alerts',
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          if (state != null && state.isNotEmpty) 'state': state,
          if (severity != null && severity.isNotEmpty) 'severity': severity,
        },
      );
      final List<Object?> raw = extractListFromResponse<Object?>(res);

      final List<DependabotAlertItem> items = raw
          .map(
            (dynamic e) =>
                DependabotAlertItem.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      return parsePaginatedRestResponse<DependabotAlertItem>(
        response: res,
        items: items,
        currentPage: page,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return PaginatedResult(items: [], hasNextPage: false);
      }
      rethrow;
    }
  }
}
