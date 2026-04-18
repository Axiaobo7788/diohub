import 'dart:ui' show Color;

/// Pure-function utilities for analyzing lists of changed files.
/// No Flutter dependency — pure Dart, testable in isolation.

enum ChangeSize { xs, small, medium, large, xl }

class DiffAnalysisResult {
  const DiffAnalysisResult({
    required this.directoryBreakdown,
    required this.languageBreakdown,
    required this.complexity,
  });

  final List<DirectoryImpact> directoryBreakdown;
  final List<LanguageImpact> languageBreakdown;
  final ChangeComplexity complexity;
}

class DirectoryImpact {
  const DirectoryImpact({
    required this.directory,
    required this.fileCount,
    required this.additions,
    required this.deletions,
    required this.totalChanges,
    required this.percentage,
  });

  final String directory;
  final int fileCount;
  final int additions;
  final int deletions;
  final int totalChanges;
  final double percentage;
}

class LanguageImpact {
  const LanguageImpact({
    required this.language,
    required this.fileCount,
    required this.additions,
    required this.deletions,
    required this.totalChanges,
    required this.percentage,
    this.color,
  });

  final String language;
  final int fileCount;
  final int additions;
  final int deletions;
  final int totalChanges;
  final double percentage;
  final Color? color;
}

class ChangeComplexity {
  const ChangeComplexity({
    required this.size,
    required this.totalFiles,
    required this.totalAdditions,
    required this.totalDeletions,
    required this.directorySpread,
    required this.label,
  });

  final ChangeSize size;
  final int totalFiles;
  final int totalAdditions;
  final int totalDeletions;
  final int directorySpread;
  final String label;
}

/// Static map of file extensions → (language name, color).
/// Covers the top ~30 languages seen in GitHub repos.
const Map<String, (String name, Color color)> _extensionToLanguage = <String, (String, Color)>{
  '.dart': ('Dart', Color(0xFF00B4AB)),
  '.swift': ('Swift', Color(0xFFFFAC45)),
  '.kt': ('Kotlin', Color(0xFFA97BFF)),
  '.kts': ('Kotlin', Color(0xFFA97BFF)),
  '.java': ('Java', Color(0xFFB07219)),
  '.ts': ('TypeScript', Color(0xFF3178C6)),
  '.tsx': ('TypeScript', Color(0xFF3178C6)),
  '.js': ('JavaScript', Color(0xFFF1E05A)),
  '.jsx': ('JavaScript', Color(0xFFF1E05A)),
  '.mjs': ('JavaScript', Color(0xFFF1E05A)),
  '.cjs': ('JavaScript', Color(0xFFF1E05A)),
  '.py': ('Python', Color(0xFF3572A5)),
  '.go': ('Go', Color(0xFF00ADD8)),
  '.rs': ('Rust', Color(0xFFDEA584)),
  '.rb': ('Ruby', Color(0xFF701516)),
  '.yaml': ('YAML', Color(0xFFCB171E)),
  '.yml': ('YAML', Color(0xFFCB171E)),
  '.json': ('JSON', Color(0xFF292929)),
  '.xml': ('XML', Color(0xFF0060AC)),
  '.md': ('Markdown', Color(0xFF083FA1)),
  '.html': ('HTML', Color(0xFFE34C26)),
  '.htm': ('HTML', Color(0xFFE34C26)),
  '.css': ('CSS', Color(0xFF563D7C)),
  '.scss': ('SCSS', Color(0xFFC6538C)),
  '.sass': ('Sass', Color(0xFFC6538C)),
  '.sh': ('Shell', Color(0xFF89E051)),
  '.bash': ('Shell', Color(0xFF89E051)),
  '.zsh': ('Shell', Color(0xFF89E051)),
  '.sql': ('SQL', Color(0xFFE38C00)),
  '.graphql': ('GraphQL', Color(0xFFE10098)),
  '.gql': ('GraphQL', Color(0xFFE10098)),
  '.proto': ('Protobuf', Color(0xFF6A9FB5)),
  '.c': ('C', Color(0xFF555555)),
  '.cpp': ('C++', Color(0xFFF34B7D)),
  '.cc': ('C++', Color(0xFFF34B7D)),
  '.cxx': ('C++', Color(0xFFF34B7D)),
  '.h': ('C/C++', Color(0xFF555555)),
  '.hpp': ('C++', Color(0xFFF34B7D)),
  '.m': ('Objective-C', Color(0xFF438EFF)),
  '.mm': ('Objective-C++', Color(0xFF438EFF)),
  '.gradle': ('Gradle', Color(0xFF02303A)),
  '.tf': ('HCL', Color(0xFF5C4EE5)),
  '.tfvars': ('HCL', Color(0xFF5C4EE5)),
  '.vue': ('Vue', Color(0xFF41B883)),
  '.svelte': ('Svelte', Color(0xFFFF3E00)),
};

const Color _otherColor = Color(0xFF6E7781);

String _topLevelDirectory(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '(root)';
  final parts = trimmed.split(RegExp(r'[/\\]'));
  final first = parts.first.trim();
  return first.isEmpty ? '(root)' : first;
}

String _extensionFromPath(String path) {
  final lastSlash = path.lastIndexOf(RegExp(r'[/\\]'));
  final name = lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return name.substring(dot).toLowerCase();
}

(String name, Color color) _languageFromExtension(String ext) {
  return _extensionToLanguage[ext] ?? ('Other', _otherColor);
}

ChangeSize _changeSizeFromTotals(int totalChanges, int totalFiles, int directorySpread) {
  if (totalChanges < 10 && totalFiles <= 2) return ChangeSize.xs;
  if (totalChanges < 100) return ChangeSize.small;
  if (totalChanges < 500) return ChangeSize.medium;
  if (totalChanges < 1000) return ChangeSize.large;
  return ChangeSize.xl;
}

String _labelForChangeSize(ChangeSize size) {
  switch (size) {
    case ChangeSize.xs:
      return 'Tiny change';
    case ChangeSize.small:
      return 'Small focused change';
    case ChangeSize.medium:
      return 'Medium change';
    case ChangeSize.large:
      return 'Large change';
    case ChangeSize.xl:
      return 'Very large change';
  }
}

/// Top-level analysis function.
///
/// [files] — flat list of DiffEntry / PR file nodes.
/// Works with any type T via [getFilename], [getAdditions], [getDeletions] callbacks
/// so it works for both REST DiffEntry and GQL PullRequestChangedFile.
DiffAnalysisResult analyzeDiffs<T>({
  required List<T> files,
  required String Function(T) getFilename,
  required int Function(T) getAdditions,
  required int Function(T) getDeletions,
}) {
  if (files.isEmpty) {
    return DiffAnalysisResult(
      directoryBreakdown: const <DirectoryImpact>[],
      languageBreakdown: const <LanguageImpact>[],
      complexity: ChangeComplexity(
        size: ChangeSize.xs,
        totalFiles: 0,
        totalAdditions: 0,
        totalDeletions: 0,
        directorySpread: 0,
        label: _labelForChangeSize(ChangeSize.xs),
      ),
    );
  }

  int totalAdditions = 0;
  int totalDeletions = 0;
  final Map<String, _DirAccum> dirMap = <String, _DirAccum>{};
  final Map<String, _LangAccum> langMap = <String, _LangAccum>{};

  for (final T file in files) {
    final path = getFilename(file);
    final adds = getAdditions(file);
    final dels = getDeletions(file);
    final changes = adds + dels;
    totalAdditions += adds;
    totalDeletions += dels;

    final dir = _topLevelDirectory(path);
    dirMap.putIfAbsent(
      dir,
      () => _DirAccum(dir, 0, 0, 0, 0),
    );
    final da = dirMap[dir]!;
    da.fileCount++;
    da.additions += adds;
    da.deletions += dels;
    da.totalChanges += changes;

    final ext = _extensionFromPath(path);
    final (String langName, Color langColor) = _languageFromExtension(ext);
    langMap.putIfAbsent(
      langName,
      () => _LangAccum(langName, langColor, 0, 0, 0, 0),
    );
    final la = langMap[langName]!;
    la.fileCount++;
    la.additions += adds;
    la.deletions += dels;
    la.totalChanges += changes;
  }

  final totalChanges = totalAdditions + totalDeletions;
  final directorySpread = dirMap.length;
  final size = _changeSizeFromTotals(totalChanges, files.length, directorySpread);
  final complexity = ChangeComplexity(
    size: size,
    totalFiles: files.length,
    totalAdditions: totalAdditions,
    totalDeletions: totalDeletions,
    directorySpread: directorySpread,
    label: _labelForChangeSize(size),
  );

  final dirList = dirMap.values
      .map((a) => DirectoryImpact(
            directory: a.directory,
            fileCount: a.fileCount,
            additions: a.additions,
            deletions: a.deletions,
            totalChanges: a.totalChanges,
            percentage: totalChanges > 0 ? (a.totalChanges / totalChanges) * 100 : 0,
          ))
      .toList();
  dirList.sort((a, b) => b.totalChanges.compareTo(a.totalChanges));

  final langList = langMap.values
      .map((a) => LanguageImpact(
            language: a.language,
            fileCount: a.fileCount,
            additions: a.additions,
            deletions: a.deletions,
            totalChanges: a.totalChanges,
            percentage: totalChanges > 0 ? (a.totalChanges / totalChanges) * 100 : 0,
            color: a.color,
          ))
      .toList();
  langList.sort((a, b) => b.percentage.compareTo(a.percentage));

  return DiffAnalysisResult(
    directoryBreakdown: dirList,
    languageBreakdown: langList,
    complexity: complexity,
  );
}

class _DirAccum {
  _DirAccum(this.directory, this.fileCount, this.additions, this.deletions, this.totalChanges);
  final String directory;
  int fileCount;
  int additions;
  int deletions;
  int totalChanges;
}

class _LangAccum {
  _LangAccum(this.language, this.color, this.fileCount, this.additions, this.deletions, this.totalChanges);
  final String language;
  final Color color;
  int fileCount;
  int additions;
  int deletions;
  int totalChanges;
}
