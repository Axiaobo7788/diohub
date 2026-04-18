import 'package:diohub/providers/database_providers.dart' show apiClientProvider;
import 'package:diohub/services/base/service_extensions.dart';
import 'package:diohub/services/issues/issue_fields_service.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/issue_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for organization issue field definitions.
/// 
/// Fetches the schema for all available issue fields in an organization
/// (Priority, Effort, custom fields, etc.).
/// 
/// Cached per organization.
final orgIssueFieldsProvider = FutureProvider.autoDispose
    .family<List<IssueFieldDef>, String>((ref, org) async {
  final apiClient = ref.watch(apiClientProvider);
  
  // Use a temporary IssueRef to access the service
  // (The service doesn't actually need the issue ref for org-level queries)
  final dummyRef = IssueRef(repo: RepoRef(owner: org, name: '_'), number: 1);
  final service = IssueFieldsService(apiClient, dummyRef);
  
  final rawFields = await service.fetchOrgIssueFields(org);
  return rawFields.map((json) => IssueFieldDef.fromJson(json)).toList();
});

/// Provider for issue field values on a specific issue.
/// 
/// Fetches the current values for all fields on this issue.
final issueFieldValuesProvider = FutureProvider.autoDispose
    .family<List<IssueFieldValue>, IssueRef>((ref, issueRef) async {
  final apiClient = ref.watch(apiClientProvider);
  final fieldService = IssueFieldsService(apiClient, issueRef);
  
  final rawValues = await fieldService.fetchIssueFieldValues();
  return rawValues.map((json) => IssueFieldValue.fromJson(json)).toList();
});
