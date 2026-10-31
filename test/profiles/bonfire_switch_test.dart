import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/profiles/bonfire_switch.dart';

const _guid = 'a90f11cb-42a1-432d-94bb-97cc2d42ef8b';

JellyfinConnection _conn() {
  return JellyfinConnection(
    id: 'jf-1',
    baseUrl: 'https://jellyfin.example.net',
    serverName: 'Home Media',
    serverMachineId: 'machine-1',
    userId: 'master-1',
    userName: 'dalgibbard',
    accessToken: 'master-token',
    deviceId: 'device-1',
    createdAt: DateTime(2026, 1, 1),
  );
}

http.Response _json(Object? body, int status) {
  return http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});
}

Future<BonfireSwitchResult> _switch({
  required MockClient mock,
  bool requiresPin = false,
  Future<String?> Function({String? errorMessage}) promptForPin = _noPrompt,
}) {
  return switchBonfireUserWithPin(
    parentConnection: _conn(),
    profileId: _guid,
    requiresPin: requiresPin,
    promptForPin: promptForPin,
    testClient: mock,
  );
}

Future<String?> _noPrompt({String? errorMessage}) async => fail('should not prompt');

void main() {
  group('switchBonfireUserWithPin', () {
    test('succeeds without a PIN and returns the scoped session token', () async {
      var attempts = 0;
      final result = await _switch(
        mock: MockClient((request) async {
          attempts++;
          expect(request.method, 'POST');
          expect(request.url.path, '/plugins/profiles/switch');
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['profileId'], _guid);
          expect(body.containsKey('pin'), isFalse);
          expect(request.headers['Authorization'], contains('MediaBrowser'));
          return _json({'activeProfileToken': 'scoped-token', 'jellyfinUserId': _guid}, 200);
        }),
      );
      expect(attempts, 1);
      expect(result.succeeded, isTrue);
      expect(result.status, BonfireSwitchStatus.success);
      expect(result.userToken, 'scoped-token');
    });

    test('prompts up-front when the profile requires a PIN and sends it', () async {
      final pins = <String?>[];
      final result = await _switch(
        requiresPin: true,
        promptForPin: ({String? errorMessage}) async {
          pins.add(errorMessage);
          return '1234';
        },
        mock: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['pin'], '1234');
          return _json({'activeProfileToken': 'scoped-token'}, 200);
        }),
      );
      expect(result.succeeded, isTrue);
      expect(pins, [isNull]);
    });

    test('cancelling the PIN prompt aborts before any request', () async {
      var attempts = 0;
      final result = await _switch(
        requiresPin: true,
        promptForPin: ({String? errorMessage}) async => null,
        mock: MockClient((request) async {
          attempts++;
          return _json({'activeProfileToken': 'x'}, 200);
        }),
      );
      expect(result.status, BonfireSwitchStatus.cancelled);
      expect(result.succeeded, isFalse);
      expect(attempts, 0);
    });

    test('an incorrect PIN loops with the error surfaced on the next prompt', () async {
      var attempts = 0;
      final sentPins = <String>[];
      final errors = <String?>[];
      final result = await _switch(
        requiresPin: true,
        promptForPin: ({String? errorMessage}) async {
          errors.add(errorMessage);
          return attempts == 0 ? '1111' : '1234';
        },
        mock: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          sentPins.add(body['pin'] as String);
          attempts++;
          if (attempts == 1) return _json({'message': 'Incorrect PIN'}, 400);
          return _json({'activeProfileToken': 'scoped-token'}, 200);
        }),
      );
      expect(result.succeeded, isTrue);
      expect(sentPins, ['1111', '1234']);
      expect(errors.first, isNull);
      expect(errors.last, isNotNull);
    });

    test('a PIN-shaped 400 forces a prompt even when none was expected', () async {
      var attempts = 0;
      var prompted = 0;
      final result = await _switch(
        requiresPin: false,
        promptForPin: ({String? errorMessage}) async {
          prompted++;
          return '1234';
        },
        mock: MockClient((request) async {
          attempts++;
          if (attempts == 1) return _json({'message': 'A PIN is required for this profile'}, 400);
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['pin'], '1234');
          return _json({'activeProfileToken': 'scoped-token'}, 200);
        }),
      );
      expect(result.succeeded, isTrue);
      expect(prompted, 1);
    });

    test('a non-PIN 400 after a sent PIN is final and carries the plugin reason', () async {
      var attempts = 0;
      final result = await _switch(
        requiresPin: true,
        promptForPin: ({String? errorMessage}) async => '1234',
        mock: MockClient((request) async {
          attempts++;
          return _json({'message': 'This profile is restricted to other devices'}, 400);
        }),
      );
      expect(attempts, 1);
      expect(result.status, BonfireSwitchStatus.failed);
      expect(result.message, 'This profile is restricted to other devices');
    });

    test('HTTP 401 is authRejected — about the caller token, never the target', () async {
      final result = await _switch(mock: MockClient((request) async => _json({'message': 'expired'}, 401)));
      expect(result.status, BonfireSwitchStatus.authRejected);
      expect(result.succeeded, isFalse);
    });

    test('HTTP 429 surfaces the rate-limit without retrying', () async {
      var attempts = 0;
      final result = await _switch(
        mock: MockClient((request) async {
          attempts++;
          return _json({'message': 'slow down'}, 429);
        }),
      );
      expect(attempts, 1);
      expect(result.status, BonfireSwitchStatus.failed);
      expect(result.message, contains('Too many attempts'));
    });

    test('a 200 without activeProfileToken is a failure', () async {
      final result = await _switch(mock: MockClient((request) async => _json({'jellyfinUserId': _guid}, 200)));
      expect(result.status, BonfireSwitchStatus.failed);
      expect(result.userToken, isNull);
    });

    test('a PascalCase 200 (Jellyfin 12 serialization) still yields the token', () async {
      final result = await _switch(
        mock: MockClient((request) async => _json({'ActiveProfileToken': 'scoped-token', 'JellyfinUserId': _guid}, 200)),
      );
      expect(result.status, BonfireSwitchStatus.success);
      expect(result.userToken, 'scoped-token');
    });
  });
}
