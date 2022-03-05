import 'dart:io';

import 'package:args/args.dart';
import 'powershell/command/mp_preference.dart';
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
      'white-list-file',
      abbr: 'f',
      help: 'white list file',
      defaultsTo: 'white.list',
    );
  try {
    final results = parser.parse({
      ...args,
      // r'--white-list-file=white.list',
      // r'C:\Users\ipcjs\Downloads',
    });
    _apply = results['apply'];

    final whiteList = results.rest.map((e) => Path(e)).toSet();

    final String? whiteListFilePath;
    if ((whiteListFilePath = results['white-list-file']) != null) {
      final whiteListFile = File(whiteListFilePath!);
      if (await whiteListFile.exists()) {
        for (final line in await whiteListFile.readAsLines()) {
          if (line.trim().isNotEmpty && !line.startsWith('#')) {
            whiteList.add(Path(line));
          }
        }
      } else {
        print(
            '[warn] white list file not found: ${whiteListFile.absolute.path}');
      }
    }
    if (whiteList.isEmpty) {
      throw Exception('Please set white list or file');
    }

    await process(
      whiteList: whiteList,
    );
  } catch (e, st) {
    print('$e\n'
        '$st\n'
        'defender_white_list: set windows defender exclude list by white list.\n\n'
        '${parser.usage}');
  }
}

Future<void> process({
  required Set<Path> whiteList,
}) async {
  final results = await revertPaths(
    whiteList,
    onlyIncludeDir: true,
  );
  final excludes = <Path>{
    Path(r'C:\Documents and Settings'),
    Path(r'C:\Recovery'),
  };
  final blackList = results.where((it) {
    final isSystemFile = it.name.startsWith('\$');
    return !isSystemFile && !excludes.contains(it);
  }).toList(growable: false);

  print('''
White list:
${whiteList.map((e) => e.path).join('\n')}

↓↓↓↓↓↓↓↓↓↓

Black list:
${blackList.map((e) => e.path).join('\n')}
''');
  if (_apply) const MpPreference().exclusionPath.set(blackList);
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
