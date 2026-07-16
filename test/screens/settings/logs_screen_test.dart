import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/settings/logs_screen.dart';

void main() {
  test('log upload payload preserves the header and newest complete lines', () {
    const header = 'Plezy test device\n---\n';
    const logs = 'oldest line that should be removed\nmiddle line that should be removed\nnewest 🚀 line';

    final payload = constrainLogUploadPayload(header: header, logs: logs, maxBytes: 52);

    expect(utf8.encode(payload).length, lessThanOrEqualTo(52));
    expect(payload, startsWith(header));
    expect(payload, endsWith('newest 🚀 line'));
    expect(payload, isNot(contains('oldest line')));
  });

  test('log upload payload remains unchanged below the server limit', () {
    const header = 'device\n---\n';
    const logs = 'one\ntwo';

    expect(constrainLogUploadPayload(header: header, logs: logs, maxBytes: 128), '$header$logs');
  });
}
