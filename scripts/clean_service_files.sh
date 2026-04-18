#!/bin/bash

# Clean 21 service files: remove lens engine imports

FILES=(
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/markdown/markdown_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/repo_deployment_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/repo_workflows_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/repo_label_milestone_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/wiki_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/repo_stats_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/repo_branch_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/repo_services.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/repo_release_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/repositories/repo_collaborator_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/git_database/git_database_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/search/search_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/users/user_contributions_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/users/viewer_info_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/users/user_info_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/users/user_activity_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/users/viewer_settings_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/pulls/pull_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/pulls/pull_creation_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/issues/issue_service.dart"
  "/Users/namanshergill/Desktop/dev/diohub/lib/services/issues/issue_creation_service.dart"
)

for file in "${FILES[@]}"; do
  echo "Cleaning $file"
  
  # Remove import for tool_category.dart
  sed -i '' '/import.*\/services\/lens\/tool_category.dart/d' "$file"
  
  # Remove any other lens engine imports (but keep lens_annotations)
  sed -i '' '/import.*\/services\/lens\//d' "$file"
  
  # Remove import for ai service types
  sed -i '' '/import.*\/services\/ai\//d' "$file"
done

echo "Service files cleaned"
