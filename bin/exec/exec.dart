import 'dart:convert';
import 'dart:io';

Future<String> exec(String executable, List<String> arguments) async {
  final result = await Process.run(
    executable,
    arguments,
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw ExecException(
      exitCode: result.exitCode,
      stderr: result.stderr,
      stdout: result.stdout,
      command: [executable, ...arguments].join(' '),
    );
  }
  return result.stdout;
}

Future<int> runCommandBlock(
  String summary,
  String usage,
  Future<void> Function() block,
) async {
  try {
    await block();
    return 0;
  } catch (e, st) {
    print('$e\n'
        '$st\n'
        '$summary\n\n'
        '$usage');
    return e is ExecException ? e.exitCode : 1;
  }
}

class ExecException implements Exception {
  const ExecException({
    required this.exitCode,
    required this.stderr,
    required this.stdout,
    required this.command,
  });
  final int exitCode;
  final String stdout;
  final String stderr;
  final String command;
  @override
  String toString() => '''ExecException: $command => $exitCode
stdout: $stdout
stderr: 
$stderr
''';
}
