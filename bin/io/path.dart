import 'package:path/path.dart' as p;
import 'dart:io';

/// [Directory]/[File]没有实现[hashCode]&[==]方法, 不方便比较
/// [String]当作路径处理容易出错
/// 故封装该类, 处理路径问题
class Path {
  static Path current = Path('.');

  Path(
    String path,
  ) : this._(p.normalize(p.absolute(path)));

  const Path._(this.path) : assert(path != '');

  final String path;

  String get name => p.basename(path);

  bool get isRoot => parent == null;

  Path? get parent {
    final parentPath = p.dirname(path);
    return parentPath != path ? Path._(parentPath) : null;
  }

  Directory toDirectory() => Directory(path);

  File toFile() => File(path);

  Future<FileStat> stat() => FileStat.stat(path);

  Future<bool> isDirectory({bool followLinks = true}) async =>
      await FileSystemEntity.type(path, followLinks: followLinks) ==
      FileSystemEntityType.directory;

  Stream<Path> list({bool recursive = false, bool followLinks = true}) =>
      toDirectory()
          .list(recursive: recursive, followLinks: followLinks)
          .map((it) => Path(it.path));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Path && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;
  @override
  String toString() => 'Path{$path}';
}
