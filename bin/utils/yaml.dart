// ignore_for_file: unnecessary_this

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

extension YamlExt on YamlEditor {
  /// @see [Map.putIfAbsent]
  YamlNode putIfAbsent(
    List<Object?> path,
    Object? Function() ifAbsent,
  ) {
    for (var deep = 1; deep <= path.length; deep++) {
      final subpath = path.sublist(0, deep);
      final node = this.parseAt(
        subpath,
        orElse: () => wrapAsYamlNode(null),
      );
      if (node.value == null) {
        this.update(
          subpath,
          deep == path.length
              ? ifAbsent()
              : subpath.last is String
                  ? {}
                  : [],
        );
      }
    }
    return this.parseAt(path);
  }
}
