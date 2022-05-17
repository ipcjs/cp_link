Future<int> runCommandBlock<R>(
    String summary, String usage, Future<void> Function() block) async {
  try {
    await block();
    return 0;
  } catch (e, st) {
    print('$e\n'
        '$st\n'
        '$summary\n\n'
        '$usage');
    return e is CodeException ? e.code : 1;
  }
}

class CodeException implements Exception {
  const CodeException(this.code, [this.message]);
  final int code;
  final String? message;
  @override
  String toString() => 'CodeException{code: $code, message: $message}';
}
