import 'dart:io';

final class _Command {
  const _Command(this.label, this.executable, this.arguments, this.directory);

  final String label;
  final String executable;
  final List<String> arguments;
  final String directory;
}

Future<void> main(final List<String> arguments) async {
  final Directory root = File.fromUri(Platform.script).parent.parent;
  final bool codegenOnly = arguments.contains('--codegen-only');
  final String dart = Platform.isWindows ? 'dart.exe' : 'dart';
  final String flutter = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final List<String> generatorPackages = <String>[
    'packages/diohub_graphql',
    'packages/diohub_models',
    'packages/diohub_database',
  ];

  final List<_Command> commands = <_Command>[
    if (!codegenOnly)
      _Command('root dependencies', flutter, <String>['pub', 'get'], root.path),
    for (final String package in generatorPackages) ...<_Command>[
      if (!codegenOnly)
        _Command('$package dependencies', dart, <String>[
          'pub',
          'get',
        ], '${root.path}/$package'),
      _Command('$package codegen', dart, <String>[
        'run',
        'build_runner',
        'build',
      ], '${root.path}/$package'),
    ],
    _Command('root codegen', dart, <String>[
      'run',
      'build_runner',
      'build',
    ], root.path),
  ];

  for (final _Command command in commands) {
    stdout.writeln('\n==> ${command.label}');
    final Process process = await Process.start(
      command.executable,
      command.arguments,
      workingDirectory: command.directory,
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final int result = await process.exitCode;
    if (result != 0) {
      stderr.writeln('${command.label} failed with exit code $result.');
      exitCode = result;
      return;
    }
  }
}
