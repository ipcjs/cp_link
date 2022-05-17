import 'dart:convert';
import 'dart:io';

Future<String> powershell(List<String> args) async {
  final arguments = [
    '-NonInteractive',
    '-Command',
    ...args,
  ];
  final result = await Process.run(
    'powershell',
    arguments,
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw PowerShellException(
      exitCode: result.exitCode,
      stderr: result.stderr,
      stdout: result.stdout,
      command: arguments.join(' '),
    );
  }
  return result.stdout;
}

class PowerShellException implements Exception {
  const PowerShellException({
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
  String toString() => '''PowerShellException: $command => $exitCode
stdout: $stdout
stderr: 
$stderr
''';
}

class MissingAdministratorPrivilegesException implements Exception {
  const MissingAdministratorPrivilegesException(this.message);
  final String message;
  @override
  String toString() => '''MissingAdministratorPrivilegesException:
$message
''';
}

extension PowerShellArrayExt on Iterable<String> {
  String toPowerShellArray() => '@(${this.map((e) => "'$e'").join(', ')})';
}
