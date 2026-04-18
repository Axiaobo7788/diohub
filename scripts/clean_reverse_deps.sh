#!/bin/bash

# Fix reverse dependency files: remove lens/AI imports and replace bridge widget usages with PremiumExtension calls

# Files using LensButton
FILES_WITH_LENS_BUTTON=(
  "lib/view/repository/repository_screen.dart"
  "lib/view/issues_pulls/issue_detail_screen.dart"
  "lib/view/issues_pulls/widgets/file_diff_screen.dart"
  "lib/view/profile/user_profile_screen.dart"
  "lib/view/repository/wiki/wiki_viewer.dart"
  "lib/view/repository/commits/commit_info_screen.dart"
  "lib/view/repository/code/file_viewer_screen.dart"
  "lib/view/issues_pulls/pull_request_detail_screen.dart"
  "lib/view/issues_pulls/new_pull_request_screen.dart"
  "lib/view/repository/compare_view_screen.dart"
  "lib/view/repository/issues/new_issue_screen.dart"
  "lib/view/search/search.dart"
  "lib/view/issues_pulls/widgets/p_r_review_screen.dart"
  "lib/view/home/home.dart"
  "lib/view/repository/actions/workflow_run_detail_screen.dart"
  "lib/view/notifications/notifications.dart"
  "lib/view/issues_pulls/comment_screen.dart"
)

# Files using AiSummaryChip
FILES_WITH_AI_SUMMARY=(
  "lib/view/repository/security/security_position.dart"
  "lib/view/issues_pulls/widgets/file_diff_screen.dart"
  "lib/view/notifications/notifications.dart"
  "lib/view/issues_pulls/widgets/discussion_content_slivers.dart"
  "lib/view/repository/actions/log_viewer_screen.dart"
  "lib/common/cards/release_card.dart"
)

# Files using AiComposeActions
FILES_WITH_AI_COMPOSE=(
  "lib/common/compose/toolbar/compose_toolbar_overlay.dart"
  "lib/common/nav_center/compose/compose_markdown_toolbar.dart"
)

# Remove imports from all files
ALL_FILES=("${FILES_WITH_LENS_BUTTON[@]}" "${FILES_WITH_AI_SUMMARY[@]}" "${FILES_WITH_AI_COMPOSE[@]}")
UNIQUE_FILES=($(printf "%s\n" "${ALL_FILES[@]}" | sort -u))

for file in "${UNIQUE_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "Cleaning imports in $file"
    
    # Remove lens/AI related imports
    sed -i '' '/import.*\/services\/lens\//d' "$file"
    sed -i '' '/import.*\/services\/ai\//d' "$file"
    sed -i '' '/import.*\/providers\/lens\//d' "$file"
    sed -i '' '/import.*\/providers\/ai\//d' "$file"
    sed -i '' '/import.*\/view\/lens\//d' "$file"
    sed -i '' '/import.*\/common\/lens\//d' "$file"
    sed -i '' '/import.*\/common\/widgets\/ai_summary_chip/d' "$file"
    sed -i '' '/import.*\/common\/compose\/toolbar\/ai_compose_actions/d' "$file"
    sed -i '' '/import.*\/models\/entity_ref_lens_extensions/d' "$file"
    sed -i '' '/import.*\/view\/home\/widgets\/ai_settings_tab/d' "$file"
    sed -i '' '/import.*diohub_models\/models\/ai\//d' "$file"
    sed -i '' '/import.*diohub_models\/models\/lens\//d' "$file"
  fi
done

echo "Reverse dependency files cleaned"
