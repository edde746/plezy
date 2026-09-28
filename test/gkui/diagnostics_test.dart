import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/gkui/diagnostics.dart';

void main() {
  test('redacts Plex and HTTP credentials', () {
    const input = 'GET https://host/video?X-Plex-Token=secret&x=1 '
        'Authorization:Bearer-secret Cookie=session-secret authToken=pin-token';
    final output = redactSecrets(input);

    expect(output, isNot(contains('secret')));
    expect(output, contains('X-Plex-Token=<redacted>'));
    expect(output, contains('Authorization:<redacted>'));
    expect(output, contains('Cookie=<redacted>'));
    expect(output, contains('authToken=<redacted>'));
  });

  test('bounded log drops oldest entries', () {
    final logs = RedactingLogStore(capacity: 2)
      ..add('first', at: DateTime.utc(2026))
      ..add('second', at: DateTime.utc(2026, 1, 2))
      ..add('third', at: DateTime.utc(2026, 1, 3));

    expect(logs.entries, hasLength(2));
    expect(logs.exportText(), isNot(contains('first')));
    expect(logs.exportText(), contains('second'));
    expect(logs.exportText(), contains('third'));
  });
}
