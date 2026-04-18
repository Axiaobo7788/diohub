/// Converts GitHub Actions log annotations to ANSI for display in xterm.
String processGitHubAnnotations(String raw) {
  return raw
      .replaceAllMapped(
        RegExp(r'##\[group\](.*)'),
        (m) => '\x1b[1;36m▸ ${m[1]}\x1b[0m',
      )
      .replaceAll('##[endgroup]', '')
      .replaceAllMapped(
        RegExp(r'##\[error\](.*)'),
        (m) => '\x1b[1;31m✗ ${m[1]}\x1b[0m',
      )
      .replaceAllMapped(
        RegExp(r'##\[warning\](.*)'),
        (m) => '\x1b[1;33m⚠ ${m[1]}\x1b[0m',
      );
}
