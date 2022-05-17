// ignore_for_file: unnecessary_this
import 'package:path/path.dart' as p;

import 'dart:io';

import 'package:args/args.dart';
import 'package:tuple/tuple.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import 'exec/dart_fix.dart';
import 'exec/exec.dart';
import 'utils/dart_sdk.dart';
import 'utils/yaml.dart';

///
/// Print rules that will be fixed:
///
/// ```
/// dart fix --dry-run | grep -Po '(?<=^  )\w+(?=.*fix(es)?$)' | sort -u | awk '{print $0 ": ignore"}'
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
      final results = parser.parse(
        args,
        // [...args, 'invalid_null_aware_operator'],
      );

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
        // configFile,
        targetRules,
        apply,
      );
    },
  );
}

Future<void> process(
  // File configFile,
  List<String> targetRules,
  bool apply,
) async {
  print('Pre-execute dart fix --dry-run...');
  final files = (await dartFix(apply: false)).item1;

  print('Analysis result...');
  final excludePaths = <String>{};
  final excludeRules = <String>{};
  final excludeErrors = <String>{};

  for (final file in files) {
    excludeErrors.addAll(file.fixRules.map((e) => e.name));
    if (file.fixRules.any((it) => targetRules.contains(it.name))) {
      excludeRules.addAll(file.fixRules.map((e) => e.name));
    } else {
      excludePaths.add(file.path);
    }
  }
  excludeRules.removeAll(targetRules);
  excludeErrors.removeAll(targetRules);

  print('Update analysis_options.yaml...');
  final configFiles = await Directory.current
      .list(recursive: true)
      .where(
        (it) => p.basename(it.path) == 'analysis_options.yaml' && it is File,
      )
      .cast<File>()
      .toList();
  final originConfigs =
      await Future.wait(configFiles.map((e) => e.readAsString()));
  try {
    await Future.wait(Tuple2(configFiles, originConfigs)
        .map((e) => e.item1.writeAsString(_patchYaml(
              e.item2,
              // TODO: excludePaths在子目录中可能不对, 但当前没有使用它(
              excludePaths,
              excludeRules,
              excludeErrors,
              useAnalyzerErrors: true,
              yamlPath: e.item1.path,
            ))));

    print('Execute dart fix ${apply ? '--apply' : '--dry-run'}...');
    final stdout = (await dartFix(apply: apply)).item2;

    print(stdout);
  } finally {
    print('Resume analysis_options.yaml...');
    await Future.wait(Tuple2(configFiles, originConfigs)
        .map((e) => e.item1.writeAsString(e.item2)));
  }
}

String _patchYaml(
  String yamlContent,
  Set<String> excludePaths,
  Set<String> excludeRules,
  Set<String> excludeErrors, {
  bool useAnalyzerErrors = true,
  String? yamlPath,
}) {
  final yaml = YamlEditor(yamlContent);

  if (!useAnalyzerErrors) {
    final rules = yaml.putIfAbsent(['linter', 'rules'], () => []);
    if (rules is! YamlList) {
      throw ArgumentError('linter.rules must be a list');
    }
    // rules字段似乎没用?...
    final mergedRules = excludeRules
        .map<Map>((e) => {e: false})
        .merge(rules.map((it) => (it is Map ? it : {it: true})).merge())
        .entries
        .map((e) => {e.key: e.value})
        .toList();
    yaml.update(['linter', 'rules'], mergedRules);
  }

  if (useAnalyzerErrors) {
    final errors = yaml.putIfAbsent(['analyzer', 'errors'], () => {});
    if (errors is! YamlMap) {
      throw ArgumentError('analyzer.errors must be a map');
    }
    if (false)
      print('$yamlPath:\n'
          'errors: $errors\n'
          'excludeErrors: $excludeErrors');
    final mergedErrors =
        excludeErrors.map((e) => {e: 'ignore'}).merge({...errors});
    yaml.update(['analyzer', 'errors'], mergedErrors);
  }

  if (!useAnalyzerErrors) {
    final excludes = yaml.putIfAbsent(['analyzer', 'exclude'], () => []);
    if (excludes is! YamlList) {
      throw ArgumentError('analyzer.exclude must be a list');
    }
    final mergedExcludes = {
      ...excludes,
      ...excludePaths,
    }.toList();
    yaml.update(['analyzer', 'exclude'], mergedExcludes);
  }

  return yaml.toString();
}
