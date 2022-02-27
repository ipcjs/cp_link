import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:args/args.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'hardlink',
      help: 'hard link dir',
      abbr: 'h',
      mandatory: true,
    )
    ..addOption(
      'softlink',
      help: 'soft link dir, default is same as hard link dir',
      abbr: 's',
      mandatory: false,
    )
    ..addOption(
      'target',
      help: 'target dir',
      abbr: 't',
      mandatory: true,
    )
    ..addOption('size',
        abbr: 'S',
        help:
            'File size threshold. If it is greater than or equal to it, use a soft link, otherwise use a hard link, default is 50MB',
        defaultsTo: '50')
    ..addFlag(
      'apply',
      abbr: 'A',
      help: 'apply copy, default is $_apply',
      defaultsTo: _apply,
    );

  try {
    final results = parser.parse([
      // r'--hardlink=C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING Source',
      // r'--softlink=Z:\Archives\ELDEN RING',
      // r'--target=C:\Program Files (x86)\Steam\steamapps\common\ELDEN RING',
      ...args
    ]);
    _apply = results['apply'];

    await process(
      results['hardlink'],
      results['softlink'] ?? results['hardlink'],
      results['target'],
      int.parse(results['size']) * 1024 * 1024,
    );
  } catch (e, st) {
    print('$e\n'
        '$st\n'
        'cp_link: Copy files from [hardlink] or [softlink] to [target].\n\n'
        '${parser.usage}');
  }
}

bool _apply = false;

/// If the file is larger than [size]MB, copy the hard link from the [hardlink] to the
/// [target], otherwise copy the soft link from the [softlink] to the [target]
Future<void> process(
  String hardlink,
  String softlink,
  String target,
  int size,
) async {
  final hardlinkDir = Directory(hardlink);
  final softlinkDir = Directory(softlink);
  final targetDir = Directory(target);
  await copy(
    hardlinkDir,
    targetDir,
    copyImpl: (src, dst) async {
      if (!await dst.parent.exists()) {
        print('create dir: ${dst.parent}');
        await dst.parent.create(recursive: true);
      }
      await src.copy(dst.absolute.path);
    },
    test: (file) async => (await file.stat()).size < size,
  );
  await copy(
    softlinkDir,
    targetDir,
    copyImpl: (src, dst) =>
        Link(dst.absolute.path).create(src.absolute.path, recursive: true),
    test: (file) async => (await file.stat()).size >= size,
  );
}

Future<void> copy(
  Directory source,
  Directory target, {
  required Future<bool> Function(File file) test,
  required Future<void> Function(File src, File dst) copyImpl,
}) async {
  await for (final item in source.list(recursive: true)) {
    if (item is File && await test(item)) {
      final dst = File(path.join(
        target.absolute.path,
        path.relative(item.path, from: source.absolute.path),
      ));
      print('copy: $item -> $dst');
      if (_apply) {
        /* await */ copyImpl(item, dst);
      }
    }
  }
}
