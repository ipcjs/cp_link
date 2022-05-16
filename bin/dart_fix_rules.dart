import 'dart:convert';
import 'dart:io';

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
  if (args.isEmpty) {
    throw ArgumentError('Please pass in the rule list.');
  }
  final targetRules = args;

  final result = await Process.run(
    'dart',
    ['fix', '--dry-run'],
    stderrEncoding: utf8,
    stdoutEncoding: utf8,
  );
  if (result.exitCode != 0) {
    return result.exitCode;
  }

  // Analysis result
  final files = <FixFile>[];
  FixFile? file;
  for (final line in LineSplitter.split(result.stdout as String)) {
    if (line.endsWith('.dart')) {
      file = FixFile(line.replaceAll('\\', '/'), []);
      files.add(file);
      continue;
    }
    final match = _ruleLineRegExp.firstMatch(line);
    if (match != null) {
      file!.fixRules.add(FixRule(match.group(1)!, int.parse(match.group(2)!)));
    }
  }

  // Compute the paths and rules to be excluded.
  final excludePaths = <String>[];
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
  print('''
linter:
  rules:
${excludeRules.map((e) => '    $e: false').join('\n')}

analyzer:
  exclude:
${excludePaths.map((e) => '    - $e').join('\n')}
  '''
      .trim());
  // TODO: perform dart fix

  return 0;
}

final _ruleLineRegExp = RegExp(r'^  (\w+).*(\d+).*fix(es)?$');

class FixFile {
  const FixFile(this.path, this.fixRules);

  final String path;
  final List<FixRule> fixRules;
}

class FixRule {
  const FixRule(this.name, this.fixCount);

  final String name;
  final int fixCount;
}
