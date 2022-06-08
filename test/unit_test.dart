import 'package:test/test.dart';

void main() {
  test('RegExp & \\s', () {
    final regexp = RegExp(r'^\s*line2', multiLine: true);
    final str = 'line1\r\n   line2';

    expect(regexp.firstMatch(str)?.groups([0]).map((e) => e?.toLiteral()),
        [r'\n   line2'],
        reason: '鬼知道什么原因🙃');
  });
}

extension StringExt on String {
  String toLiteral() => this.replaceAll('\n', '\\n').replaceAll('\r', '\\r');
}
