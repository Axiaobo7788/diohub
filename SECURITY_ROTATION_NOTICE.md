# Security Notice: Secret Rotation Required

## Background

This PR migrates from Envied (compile-time `.env` file generation) to `--dart-define-from-file` for injecting secrets at build time. This change fixes a security vulnerability where secrets were being baked into generated code and then:

1. Packed into `generated-code.tar.gz`
2. Uploaded as GitHub Actions artifacts
3. Cached in `actions/cache` (shared across branches)

## Required Actions After Merge

### 1. Rotate All Affected GitHub Secrets

The following secrets **MUST** be rotated immediately after this PR is merged to production:

- `OAUTH_CLIENT_SECRET` - GitHub OAuth app secret
- `SENTRY_DSN` - Sentry Data Source Name (contains project token)
- `SLACK_CLIENT_ID` - Slack OAuth client ID
- `SLACK_CLIENT_SECRET` - Slack OAuth client secret

**How to rotate:**

1. **GitHub OAuth credentials** (`OAUTH_CLIENT_SECRET`):
   - Go to [GitHub Developer Settings](https://github.com/settings/developers)
   - Find your OAuth app
   - Generate a new client secret
   - Update the `OAUTH_CLIENT_SECRET` GitHub secret in repository settings

2. **Sentry DSN** (`SENTRY_DSN`):
   - Go to Sentry Project Settings → Client Keys (DSN)
   - Revoke the old key and create a new one
   - Update the `SENTRY_DSN` GitHub secret

3. **Slack credentials** (`SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`):
   - Go to [Slack API Apps](https://api.slack.com/apps)
   - Find your app and regenerate credentials
   - Update both GitHub secrets

### 2. Clear GitHub Actions Cache

Run this command to clear all cached artifacts that may contain the old secrets:

```bash
# List all caches
gh cache list

# Delete all caches (or filter by key if needed)
gh cache delete --all
```

Or manually delete from the Actions cache UI at:
`https://github.com/namanshergill/diohub/actions/caches`

### 3. Verify No Artifacts Contain Secrets

Check that old artifacts have expired (retention is 1 day for codegen artifacts) or manually delete them:

```bash
# List artifacts
gh run list --limit 10

# Delete specific run artifacts if needed
gh run delete <run-id>
```

## Timeline

1. **Before merge**: Review this PR and plan rotation timing
2. **Immediately after merge**: Rotate all secrets within 1 hour
3. **Within 24 hours**: Clear caches and verify artifacts expired
4. **Verification**: Run a full CI/release workflow to confirm the new flow works

## Verification

After rotation, verify the changes are working:

1. Trigger a test release workflow (on `develop` or `beta`)
2. Confirm the build completes successfully
3. Check that secrets are not present in any uploaded artifacts
4. Verify the app functions correctly with the new secrets

## Questions?

If you have questions about the rotation process, contact the security team or @namanshergill.
