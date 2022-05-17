import 'dart:convert';
import 'dart:io';

import 'package:tuple/tuple.dart';

import 'exec.dart';

/// Created by ipcjs on 2022/5/17.
Future<Tuple2<List<DartFixFile>, String>> dartFix({bool apply = false}) async {
  final result = await exec(
    Platform.isWindows ? 'dart.bat' : 'dart',
    ['fix', apply ? '--apply' : '--dry-run'],
  );

  // Analysis result
  final files = <DartFixFile>[];
  DartFixFile? file;
  for (final line in LineSplitter.split(result)) {
    if (line.endsWith('.dart')) {
      file = DartFixFile(line.replaceAll('\\', '/'), []);
      files.add(file);
      continue;
    }
    final match = DartFixRule.ruleLineRegExp.firstMatch(line);
    if (match != null) {
      file!.fixRules
          .add(DartFixRule(match.group(1)!, int.parse(match.group(2)!)));
    }
  }
  return Tuple2(files, result);
}

class DartFixFile {
  const DartFixFile(this.path, this.fixRules);

  final String path;
  final List<DartFixRule> fixRules;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'fixRules': fixRules,
      };
}

class DartFixRule {
  static final ruleLineRegExp = RegExp(r'^  (\w+).*(\d+).*fix(es)?$');

  const DartFixRule(this.name, this.fixCount);

  final String name;
  final int fixCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'fixCount': fixCount,
      };
}
