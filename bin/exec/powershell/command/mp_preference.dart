import '../../../io/path.dart';
import '../command.dart';
import '../powershell.dart';

class MpPreference {
  const MpPreference();

  final Command<List<Path>> exclusionPath = const ExclusionPathCommand();
}

/// @see:
/// - https://stackoverflow.com/questions/40233123/windows-defender-add-exclusion-folder-programmatically/55895607#55895607
/// - https://docs.microsoft.com/en-us/powershell/module/defender/get-mppreference
/// - https://docs.microsoft.com/en-us/powershell/module/defender/add-mppreference
/// - https://docs.microsoft.com/en-us/powershell/module/defender/set-mppreference
/// - https://docs.microsoft.com/en-us/powershell/module/defender/remove-mppreference
class ExclusionPathCommand extends Command<List<Path>> {
  const ExclusionPathCommand();

  @override
  Future<List<Path>> get() async {
    final result = await powershell([r'($p = Get-MpPreference).ExclusionPath']);
    if (result
        .startsWith('N/A: Must be and administrator to view exclusions')) {
      throw MissingAdministratorPrivilegesException(result);
    }
    return result
        .split('\r\n')
        .where((it) => it.trim().isNotEmpty)
        .map((line) => Path(line))
        .toList();
  }

  @override
  Future<void> perform(Action action, List<Path> paths) async {
    await powershell([
      '${action.name}-MpPreference -ExclusionPath',
      paths.map((e) => e.path).toPowerShellArray(),
    ]).onError<PowerShellException>(
      (error, stackTrace) =>
          Future.error(MissingAdministratorPrivilegesException(error.stderr)),
      test: (error) => error.stderr.contains('你的权限不足，无法执行请求的操作。'),
    );
  }
}
