/// Shared code block theme ids and labels for Diff & Code settings.
abstract final class CodeBlockThemes {
  static const List<String> themeIds = <String>[
    'auto',
    'atom-one-light',
    'atom-one-dark',
    'monokai-sublime',
    'github-dark',
    'nord',
    'dracula',
    'vs2015',
  ];

  static String themeLabel(final String id) {
    if (id == 'auto') return 'Auto (match app)';
    return id
        .split('-')
        .map(
          (final String s) =>
              s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}',
        )
        .join(' ');
  }
}
