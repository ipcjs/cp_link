import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'util/path.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag(
      'include-file',
      abbr: 'F',
      help: 'include file',
      defaultsTo: false,
    )
    ..addOption(
      'white-list-file',
      abbr: 'f',
      help: 'white list file',
    );
  try {
    final results = parser.parse([
      ...args,
      // r'C:\Users\ipcjs\Downloads',
      r'K:\.placeholder',
    ]);
    final whiteList = results.rest.map((e) => Path(e)).toSet();

    final String? whiteListFile;
    if ((whiteListFile = results['white-list-file']) != null) {
      for (final line in await File(whiteListFile!).readAsLines()) {
        whiteList.add(Path(line));
      }
    }
    if (whiteList.isEmpty) {
      throw Exception('Please set white list or file');
    }

    await process(
      whiteList: whiteList,
      includeFile: results['include-file'],
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
  bool includeFile = false,
}) async {
  final results = await revertPaths(
    whiteList,
    onlyIncludeDir: !includeFile,
  );
  final excludes = {
    Path(r''),
  };
  final list = results.where((it) {
    final isSystemFile = it.name.startsWith('\$') || //
        it.name == 'System Volume Information';
    return !isSystemFile && !excludes.contains(it);
  }).toList(growable: false);

  print(list.join('\n'));
}

Future<Set<Path>> revertPaths(
  Set<Path> dirs, {
  bool onlyIncludeDir = false,
}) async {
  final results = <Path>{};
  for (final dir in dirs) {
    Path? item = dir;
    while (item != null) {
      results.remove(item);
      final parent = item.parent;
      if (parent != null) {
        await for (final brother in parent.list(followLinks: false)) {
          if (brother != item &&
              (!onlyIncludeDir || await brother.isDirectory())) {
            results.add(brother);
          }
        }
      }
      item = parent;
    }
  }

  return results;
}
