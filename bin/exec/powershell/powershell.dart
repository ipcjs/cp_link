import '../exec.dart';

Future<String> powershell(List<String> args) async {
  return exec('powershell', [
    '-NonInteractive',
    '-Command',
    ...args,
  ]);
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
