import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/all.dart' as re_highlight_langs;
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/all.dart' as re_highlight_styles;

/// Maps app code block theme IDs to re_highlight theme keys.
const Map<String, String> _themeIdToReHighlightKey = <String, String>{
  'atom-one-light': 'atom-one-light',
  'atom-one-dark': 'atom-one-dark',
  'monokai-sublime': 'monokai-sublime',
  'github-dark': 'github-dark',
  'nord': 'nord',
  'dracula': 'base16-dracula',
  'vs2015': 'vs2015',
};

/// Default light and dark re_highlight keys for themeId 'auto'.
const String _autoLightKey = 'atom-one-light';
const String _autoDarkKey = 'atom-one-dark';

/// Returns the raw theme map (language scope -> TextStyle) for [themeId] and [brightness].
/// Use for previews or when only the style map is needed (e.g. DiffCodeContextPreview).
Map<String, TextStyle> codeBlockThemeMap(
  final String themeId,
  final Brightness brightness,
) {
  final String key = reHighlightThemeKey(themeId, brightness);
  return re_highlight_styles.builtinAllThemes[key] ??
      re_highlight_styles.builtinAllThemes[_autoLightKey]!;
}

/// Returns the re_highlight theme key for [themeId] and optional [brightness].
/// When [themeId] is 'auto', [brightness] is used to pick a light or dark theme.
String reHighlightThemeKey(final String themeId, [final Brightness? brightness]) {
  if (themeId == 'auto' && brightness != null) {
    return brightness == Brightness.dark ? _autoDarkKey : _autoLightKey;
  }
  return _themeIdToReHighlightKey[themeId] ?? _autoLightKey;
}

/// Builds a [CodeHighlightTheme] for use with re_editor.
///
/// [themeId] is the app theme id (e.g. 'auto', 'atom-one-light').
/// [brightness] is used when [themeId] is 'auto' to pick light vs dark.
/// [language] is the syntax language id (e.g. 'dart', 'python').
CodeHighlightTheme codeHighlightTheme(
  final String themeId,
  final Brightness brightness,
  final String language,
) {
  final String key = reHighlightThemeKey(themeId, brightness);
  final Map<String, TextStyle> themeMap =
      re_highlight_styles.builtinAllThemes[key] ??
          re_highlight_styles.builtinAllThemes[_autoLightKey]!;

  final Mode? mode = re_highlight_langs.builtinAllLanguages[language];
  final Map<String, CodeHighlightThemeMode> languages = <String, CodeHighlightThemeMode>{};
  if (mode != null) {
    languages[language] = CodeHighlightThemeMode(mode: mode);
  }
  // Fallback: include common languages so highlightAuto can work when language is unknown.
  if (languages.isEmpty) {
    final Mode? plain = re_highlight_langs.builtinAllLanguages['plaintext'];
    if (plain != null) {
      languages['plaintext'] = CodeHighlightThemeMode(mode: plain);
    }
  }

  return CodeHighlightTheme(
    languages: languages,
    theme: themeMap,
  );
}
