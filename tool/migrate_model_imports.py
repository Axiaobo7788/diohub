#!/usr/bin/env python3
import os
import re
import sys

# List of models that were moved to the package
MOVED_MODELS = [
    'activity/activity_timeline_event',
    'activity/user_activity_timeline_data',
    'activity_timeline_progress',
    'ai/ai_message',
    'ai/ai_stream_event',
    'ai/ai_tool_definition',
    'ai/ai_tool_response',
    'ai/context_management_config',
    'ai/model_capability',
    'authentication/access_token_model',
    'authentication/access_token_response',
    'authentication/account_model',
    'authentication/account_session',
    'authentication/authenticated_session',
    'authentication/device_code_response',
    'authentication/viewer_user_payload',
    'canonical_node_id',
    'ci/check_conclusion',
    'ci/check_status',
    'cloud_sync/sync_data_key',
    'cloud_sync/sync_item',
    'cloud_sync/sync_metadata',
    'commits/commit_card_data_model',
    'commits/commit_list_item_model',
    'commits/commit_model',
    'commits/diff_status',
    'contributions/contribution_chip_type',
    'contributions/contribution_query_models',
    'contributions/contribution_type',
    'database_types',
    'discussions/discussion_resolution_reason',
    'download/download_item',
    'entity/entity_list_item',
    'entity_ref',
    'entity_ref_lens_extensions',
    'entity_snapshot_factories',
    'events/event_filter',
    'events/event_sort',
    'events/events_list_item',
    'filters/custom_filter',
    'filters/filter_menu_action',
    'git/git_signature',
    'home/home_filter',
    'iap/iap_product',
    'issues/issue_pull_mutation_result',
    'issues/subject_mutation_payload',
    'lens/lens_executor_event',
    'lens/lens_response_segment',
    'lens/lens_response_segment_json',
    'lens/lens_ui_types',
    'lens/tool_result',
    'lens/tool_step',
    'navigable',
    'notifications/grouped_notifications',
    'notifications/notification_filter',
    'notifications/notification_list_item',
    'notifications/notification_sort',
    'pagination/paginated_result',
    'pagination/unfinished_list',
    'pull_requests/pull_request_sort',
    'pulls/review_decision',
    'repositories/code/file_list_item',
    'repositories/tree_typedefs',
    'repository/compare_result',
    'repository/fork_sort',
    'repository/repo_list_item',
    'repository/repo_sort',
    'reviews/review_list_item',
    'search/issue_or_pull',
    'search/issue_pull_search_sort',
    'search/repo_search_sort',
    'search/search_result_item',
    'search/user_search_sort',
    'security/security_severity',
    'social/follow_sort',
    'social/star_sort',
    'social/watching_sort',
    'ssh/user_key',
    'ui/render_mode',
    'unrecognized_destination',
    'users/profile_card_input',
    'users/user_list_item',
]

def migrate_model_imports(content):
    """Migrate model imports from diohub to diohub_models package."""
    original = content
    
    for model_path in MOVED_MODELS:
        # Handle both with and without .dart extension in the pattern
        old_pattern = f"package:diohub/models/{model_path}.dart"
        new_import = f"package:diohub_models/models/{model_path}.dart"
        content = content.replace(old_pattern, new_import)
    
    return content, original != content

def main():
    modified_count = 0
    total_count = 0
    
    lib_dir = "lib"
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                total_count += 1
                
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    new_content, changed = migrate_model_imports(content)
                    
                    if changed:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        modified_count += 1
                        print(f"Fixed: {filepath}")
                except Exception as e:
                    print(f"Error processing {filepath}: {e}", file=sys.stderr)
    
    print(f"\n✓ Phase 3: {modified_count} files modified out of {total_count}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
