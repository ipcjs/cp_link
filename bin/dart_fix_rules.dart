// ignore_for_file: unnecessary_this

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:tuple/tuple.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import 'exception/exception.dart';
import 'utils/dart_sdk.dart';
import 'utils/yaml.dart';

/// Generate analysis_options files that only fix specific rules:
///
/// ```
/// ```
///
/// Print rules that will be fixed:
///
/// ```
/// dart fix --dry-run | grep -Po '(?<=^  )\w+(?=.*fix(es)?$)' | sort -u | awk '{print $0 ": false"}'
/// ```
///
/// Created by ipcjs on 2022/5/16.
Future<int> main(List<String> args) async {
  final parser = ArgParser() //
    ..addFlag('apply', abbr: 'A', help: 'apply change');

  return runCommandBlock(
    'dart_fix_rules: use `dart fix` to fix specific rules',
    parser.usage,
    () async {
      final results = parser.parse([...args, 'fuck']);

      final apply = results['apply'] as bool;

      final targetRules = results.rest;

      if (targetRules.isEmpty) {
        throw ArgumentError('Please pass at least one rule.');
      }
      final configFile = File('analysis_options.yaml');
      if (!await configFile.exists()) {
        throw ArgumentError(
            'Please run the program in the directory of analysis_options.yaml');
      }

      process(
        configFile,
        targetRules,
        apply,
      );
    },
  );
}

Future<Tuple2<List<_FixFile>, String>> _dartFix({bool apply = false}) async {
  final result = await Process.run(
    'dart',
    ['fix', '--dry-run'],
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
  );
  if (result.exitCode != 0) {
    throw CodeException(result.exitCode, result.stderr);
  }

  // Analysis result
  final files = <_FixFile>[];
  _FixFile? file;
  for (final line in LineSplitter.split(result.stdout as String)) {
    if (line.endsWith('.dart')) {
      file = _FixFile(line.replaceAll('\\', '/'), []);
      files.add(file);
      continue;
    }
    final match = _ruleLineRegExp.firstMatch(line);
    if (match != null) {
      file!.fixRules.add(_FixRule(match.group(1)!, int.parse(match.group(2)!)));
    }
  }
  return Tuple2(files, result.stdout);
}

Future<void> process(
  File configFile,
  List<String> targetRules,
  bool apply,
) async {
  print('dart fix --dry-run...');
  final files = (await _dartFix(apply: false)).item1;

  print('Analysis result...');
  // Compute the paths and rules to be excluded.
  final excludePaths = <String>{};
  final excludeRules = <String>{};

  for (final file in files) {
    if (file.fixRules.any((it) => targetRules.contains(it.name))) {
      excludeRules.addAll(file.fixRules.map((e) => e.name));
    } else {
      excludePaths.add(file.path);
    }
  }
  excludeRules.removeAll(targetRules);

  // output analysis_options file
  if (!apply) {
    print('''
linter:
  rules:
${excludeRules.map((e) => '    $e: false').join('\n')}

analyzer:
  exclude:
${excludePaths.map((e) => '    - $e').join('\n')}
  '''
        .trim());
    return;
  }

  print('update analysis_options.yaml...');
  final originConfig = await configFile.readAsString();
  final tempConfig = _patchYaml(originConfig, excludePaths, excludeRules);
  try {
    await configFile.writeAsString(tempConfig);

    print('exec dart fix...');
    final stdout = (await _dartFix(apply: true)).item2;

    print(stdout);
  } finally {
    print('resume analysis_options.yaml...');
    await configFile.writeAsString(originConfig);
  }
}

String _patchYaml(
  String yamlContent,
  Set<String> excludePaths,
  Set<String> excludeRules,
) {
  final yaml = YamlEditor(yamlContent);

  final rules = yaml.putIfAbsent(['linter', 'rules'], () => []);
  if (rules is! YamlList) {
    throw ArgumentError('linter.rules must be a list');
  }
  final excludes = yaml.putIfAbsent(['analyzer', 'exclude'], () => []);
  if (excludes is! YamlList) {
    throw ArgumentError('analyzer.exclude must be a list');
  }

  final mergedRules = excludeRules
      .map<Map>((e) => {e: false})
      .merge(rules.map((it) => (it is Map ? it : {it: true})).merge())
      .entries
      .map((e) => {e.key: e.value})
      .toList();
  yaml.update(['linter', 'rules'], mergedRules);

  final mergedExcludes = {
    ...excludes,
    ...excludePaths,
  }.toList();
  yaml.update(['analyzer', 'exclude'], mergedExcludes);

  return yaml.toString();
}

final _ruleLineRegExp = RegExp(r'^  (\w+).*(\d+).*fix(es)?$');

class _FixFile {
  const _FixFile(this.path, this.fixRules);

  final String path;
  final List<_FixRule> fixRules;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'fixRules': fixRules,
      };
}

class _FixRule {
  const _FixRule(this.name, this.fixCount);

  final String name;
  final int fixCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'fixCount': fixCount,
      };
}
