# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of DioHub seriously. If you discover a security vulnerability, please follow these steps:

### Where to Report

**Please DO NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via one of the following methods:

1. **Email**: Send details to the maintainer at [security contact - add your email here]
2. **GitHub Security Advisories**: Use the [Security Advisories](https://github.com/namanshergill/diohub/security/advisories/new) tab

### What to Include

Please include the following information in your report:

- Type of vulnerability (e.g., SQL injection, XSS, authentication bypass)
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response Timeline

- **Initial Response**: Within 48 hours, you'll receive acknowledgment of your report
- **Status Update**: Within 7 days, you'll receive a detailed response indicating next steps
- **Resolution**: We aim to release patches within 90 days for confirmed vulnerabilities

### Disclosure Policy

- Please give us reasonable time to address the issue before any public disclosure
- We will credit you in the security advisory (unless you prefer to remain anonymous)
- Coordinated disclosure helps protect all DioHub users

## Security Measures

DioHub implements the following security measures:

- **Encrypted Storage**: AES-256-GCM encryption for sensitive data with PBKDF2 key derivation
- **OAuth2 Authentication**: Secure authentication with GitHub's OAuth2 flow
- **Certificate Pinning**: For API communications (when applicable)
- **Secrets Management**: Environment-based configuration with `.env` files (never committed)
- **Code Analysis**: Automated security scanning via Snyk and OpenSSF Scorecard
- **Dependency Updates**: Automated via Dependabot with security-focused reviews

## Security Best Practices for Contributors

When contributing to DioHub:

1. **Never commit secrets**: Use `.env` files for local development (already in `.gitignore`)
2. **Validate all inputs**: Especially user-provided data from GitHub API
3. **Use parameterized queries**: When working with the Drift database
4. **Follow secure coding guidelines**: Refer to [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
5. **Keep dependencies updated**: Respond to Dependabot PRs promptly

## Known Security Considerations

- **OAuth Tokens**: Stored encrypted in local database. Users should revoke access if device is compromised.
- **API Keys for MCP/LLM**: Users must secure their own API keys for third-party services.
- **On-Device AI**: When using Apple Intelligence or Gemini Nano, data remains on device.

## Security Updates

Security updates are released as patch versions (e.g., 1.0.1 -> 1.0.2) and announced via:

- GitHub Releases
- Security Advisories tab
- Telegram Community (for critical issues)

---

**Thank you for helping keep DioHub and its users safe!**
