import 'dart:io';

import 'package:args/args.dart';
import 'exec/powershell/command/mp_preference.dart';
import 'io/path.dart';

bool _apply = false;
void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'apply',
      abbr: 'A',
      help: 'Apply the changes, default is $_apply',
      defaultsTo: _apply,
    )
    ..addOption(
      'danger-list-file',
      abbr: 'f',
      help: 'danger list file',
      defaultsTo: 'danger.list',
    );
  try {
    final results = parser.parse({
      ...args,
      // r'--danger-list-file=danger.list',
      // r'C:\Users\ipcjs\Downloads',
    });
    _apply = results['apply'];

    final dangerList = results.rest.map((e) => Path(e)).toSet();

    final String? dangerListFilePath;
    if ((dangerListFilePath = results['danger-list-file']) != null) {
      final dangerListFile = File(dangerListFilePath!);
      if (await dangerListFile.exists()) {
        for (final line in await dangerListFile.readAsLines()) {
          if (line.trim().isNotEmpty && !line.startsWith('#')) {
            dangerList.add(Path(line));
          }
        }
      } else {
        print(
            '[warn] danger list file not found: ${dangerListFile.absolute.path}');
      }
    }
    if (dangerList.isEmpty) {
      throw Exception('Please set danger list or file');
    }

    await process(
      dangerList: dangerList,
    );
  } catch (e, st) {
    print('$e\n'
        '$st\n'
        'defender_danger_list: set windows defender exclude list by danger list.\n\n'
        '${parser.usage}');
  }
}

Future<void> process({
  required Set<Path> dangerList,
}) async {
  final results = await revertPaths(
    dangerList,
    onlyIncludeDir: true,
  );
  final excludes = <Path>{
    Path(r'C:\Documents and Settings'),
    Path(r'C:\Recovery'),
  };
  final safetyList = results.where((it) {
    final isSystemFile = it.name.startsWith('\$');
    return !isSystemFile && !excludes.contains(it);
  }).toList(growable: false);

  print('''
Danger list:
${dangerList.map((e) => e.path).join('\n')}

↓↓↓↓↓↓↓↓↓↓

Safety list:
${safetyList.map((e) => e.path).join('\n')}
''');
  if (_apply) const MpPreference().exclusionPath.set(safetyList);
}

Future<Set<Path>> revertPaths(
  Set<Path> dirs, {
  bool onlyIncludeDir = false,
}) async {
  final includes = <Path>{};
  final excludes = <Path>{};
  for (final dir in dirs) {
    Path? item = dir;
    while (item != null) {
      excludes.add(item);
      final parent = item.parent;
      if (parent != null) {
        await for (final brother in parent.list(followLinks: false)) {
          if (brother != item) {
            final stat = await brother.stat();
            if ((!onlyIncludeDir ||
                    stat.type == FileSystemEntityType.directory) &&
                // mode=0 is special system file, should be excluded
                stat.mode != 0) {
              // print('${stat.modeString()} ${brother.path}');
              includes.add(brother);
            }
          }
        }
      }
      item = parent;
    }
  }

  includes.removeAll(excludes);
  return includes;
}
