import 'package:diohub/services/base/base_service.dart';
import 'package:diohub_models/models/entity_ref.dart';

/// Service for GitHub's Issue Fields API (structured metadata).
/// 
/// Issue Fields are GitHub's structured metadata system for tracking
/// Priority, Effort, dates, and custom fields on issues.
/// 
/// Requires API version 2026-03-10 or later.
class IssueFieldsService extends EntityService<IssueRef> {
  IssueFieldsService(super.apiClient, super.ref);

  static const String _issueFieldsAPIVersion = '2026-03-10';

  /// Fetch all issue field definitions for an organization.
  /// 
  /// Returns the schema for all available fields (Priority, Effort, custom fields).
  /// Results are typically cached per organization.
  Future<List<Map<String, dynamic>>> fetchOrgIssueFields(String org) async {
    try {
      final response = await rest.get<Map<String, dynamic>>(
        '/orgs/$org/issue-fields',
        requestHeaders: {
          'X-GitHub-Api-Version': _issueFieldsAPIVersion,
        },
      );

      if (response.data == null) {
        logWarning('fetchOrgIssueFields returned null data for org: $org');
        return [];
      }

      // API returns an array of field definitions
      final data = response.data!;
      if (data['fields'] is List) {
        return List<Map<String, dynamic>>.from(data['fields'] as List);
      }

      logWarning('fetchOrgIssueFields unexpected response format for org: $org');
      return [];
    } catch (e, st) {
      logError('Failed to fetch org issue fields for $org', e, st);
      rethrow;
    }
  }

  /// Fetch issue field values for a specific issue.
  /// 
  /// Returns the current values for all fields on this issue.
  Future<List<Map<String, dynamic>>> fetchIssueFieldValues() async {
    try {
      final response = await rest.get<Map<String, dynamic>>(
        '/repos/${ref.repo.owner}/${ref.repo.name}/issues/${ref.number}/issue-field-values',
        requestHeaders: {
          'X-GitHub-Api-Version': _issueFieldsAPIVersion,
        },
      );

      if (response.data == null) {
        logWarning('fetchIssueFieldValues returned null data for ${ref.apiPath}');
        return [];
      }

      // API returns an array of field values
      final data = response.data!;
      if (data['values'] is List) {
        return List<Map<String, dynamic>>.from(data['values'] as List);
      }

      logWarning('fetchIssueFieldValues unexpected response format for ${ref.apiPath}');
      return [];
    } catch (e, st) {
      logError('Failed to fetch issue field values for ${ref.apiPath}', e, st);
      rethrow;
    }
  }

  /// Update a single issue field value.
  /// 
  /// [repoId] - The repository database ID (not owner/name)
  /// [fieldId] - The field definition ID
  /// [value] - The new value (type depends on field data type)
  /// 
  /// For single-select fields, [value] should be the option ID.
  /// For text/number/date fields, [value] should be the raw value.
  Future<Map<String, dynamic>?> updateIssueFieldValue({
    required int repoId,
    required String fieldId,
    required dynamic value,
  }) async {
    try {
      final response = await rest.post<Map<String, dynamic>>(
        '/repositories/$repoId/issues/${ref.number}/issue-field-values',
        data: {
          'field_id': fieldId,
          'value': value,
        },
        requestHeaders: {
          'X-GitHub-Api-Version': _issueFieldsAPIVersion,
        },
      );

      return response.data;
    } catch (e, st) {
      logError('Failed to update issue field value for ${ref.apiPath}', e, st);
      rethrow;
    }
  }

  /// Clear an issue field value (set to null).
  Future<void> clearIssueFieldValue({
    required int repoId,
    required String fieldId,
  }) async {
    try {
      await rest.delete(
        '/repositories/$repoId/issues/${ref.number}/issue-field-values/$fieldId',
        requestHeaders: {
          'X-GitHub-Api-Version': _issueFieldsAPIVersion,
        },
      );
    } catch (e, st) {
      logError('Failed to clear issue field value for ${ref.apiPath}', e, st);
      rethrow;
    }
  }
}
