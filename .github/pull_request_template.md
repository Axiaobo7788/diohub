## Summary

<!-- Briefly describe what this PR does and why (1-2 sentences) -->

## Related Issues

<!-- Link related issues using "Closes #123" or "Fixes #456" -->

Closes #

## Type of Change

<!-- Check all that apply -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Refactoring (code improvement without changing functionality)
- [ ] CI/CD changes (workflow updates, scripts, configuration)
- [ ] Documentation update
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)

## Testing

<!-- Describe how you tested this change -->

- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

**Manual Testing Details:**
- Flavor(s) tested: <!-- dev / beta / rel -->
- Platform(s) tested: <!-- Android / iOS / macOS / Linux / Windows -->
- Test scenarios: <!-- Brief description of what you tested -->

## Screenshots / Recordings

<!-- If applicable, add screenshots or screen recordings to demonstrate the change -->

## Pre-merge Checklist

<!-- Ensure all items are checked before requesting review -->

- [ ] `dart analyze --fatal-infos` passes with no errors
- [ ] `dart format` applied to all changed Dart files
- [ ] Conventional commit messages used (e.g., `feat:`, `fix:`, `chore:`)
- [ ] No unintended generated file diffs (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`)
- [ ] GraphQL codegen re-run if schema/operations changed (`dart run build_runner build`)
- [ ] `.env.example` updated if new environment variables added
- [ ] Tests pass locally (`flutter test`)
- [ ] Changes work across relevant flavors (dev/beta/rel)

## Additional Notes

<!-- Any additional context, concerns, or information for reviewers -->
