import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/profiles/bonfire_switch.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';

import '../test_helpers/http_fixtures.dart';
import '../test_helpers/prefs.dart';

const _guid = 'a90f11cb-42a1-432d-94bb-97cc2d42ef8b';

JellyfinConnection _conn() {
  return JellyfinConnection(
    id: 'jf-1',
    baseUrl: 'https://jellyfin.example.net',
    serverName: 'Home Media',
    serverMachineId: 'machine-1',
    userId: 'master-1',
    userName: 'Householder',
    accessToken: 'master-token',
    deviceId: 'device-1',
    createdAt: DateTime(2026, 1, 1),
  );
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
          return jsonResponse({'activeProfileToken': 'scoped-token', 'jellyfinUserId': _guid}, status: 200);
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
          return jsonResponse({'activeProfileToken': 'scoped-token'}, status: 200);
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
          return jsonResponse({'activeProfileToken': 'x'}, status: 200);
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
          if (attempts == 1) return jsonResponse({'message': 'Incorrect PIN'}, status: 400);
          return jsonResponse({'activeProfileToken': 'scoped-token'}, status: 200);
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
          if (attempts == 1) return jsonResponse({'message': 'A PIN is required for this profile'}, status: 400);
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['pin'], '1234');
          return jsonResponse({'activeProfileToken': 'scoped-token'}, status: 200);
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
          return jsonResponse({'message': 'This profile is restricted to other devices'}, status: 400);
        }),
      );
      expect(attempts, 1);
      expect(result.status, BonfireSwitchStatus.failed);
      expect(result.message, 'This profile is restricted to other devices');
    });

    test('HTTP 401 is authRejected — about the caller token, never the target', () async {
      final result = await _switch(
        mock: MockClient((request) async => jsonResponse({'message': 'expired'}, status: 401)),
      );
      expect(result.status, BonfireSwitchStatus.authRejected);
      expect(result.succeeded, isFalse);
    });

    test('HTTP 429 surfaces the rate-limit without retrying', () async {
      var attempts = 0;
      final result = await _switch(
        mock: MockClient((request) async {
          attempts++;
          return jsonResponse({'message': 'slow down'}, status: 429);
        }),
      );
      expect(attempts, 1);
      expect(result.status, BonfireSwitchStatus.failed);
      expect(result.message, contains('Too many attempts'));
    });

    test('a 200 without activeProfileToken is a failure', () async {
      final result = await _switch(
        mock: MockClient((request) async => jsonResponse({'jellyfinUserId': _guid}, status: 200)),
      );
      expect(result.status, BonfireSwitchStatus.failed);
      expect(result.userToken, isNull);
    });

    test('a PascalCase 200 (Jellyfin 12 serialization) still yields the token', () async {
      final result = await _switch(
        mock: MockClient(
          (request) async => jsonResponse({'ActiveProfileToken': 'scoped-token', 'JellyfinUserId': _guid}, status: 200),
        ),
      );
      expect(result.status, BonfireSwitchStatus.success);
      expect(result.userToken, 'scoped-token');
    });
  });

  group('switchBonfireUserWithPin non-PIN failures', () {
    // A 400 that says nothing about a PIN ('profile not found', device
    // restrictions) is final. Prompting for a PIN anyway sends the user to
    // re-enter a credential that cannot change the outcome.
    test('a non-PIN 400 with no PIN sent yet is final — no phantom prompt', () async {
      var prompted = 0;
      final result = await _switch(
        mock: MockClient((request) async => jsonResponse({'message': 'Profile not found'}, status: 400)),
        promptForPin: ({String? errorMessage}) async {
          prompted++;
          return '1234';
        },
      );
      expect(prompted, 0);
      expect(result.status, BonfireSwitchStatus.failed);
      expect(result.message, 'Profile not found');
    });

    test('HTTP 5xx is a plain failure without retrying', () async {
      var attempts = 0;
      final result = await _switch(
        mock: MockClient((request) async {
          attempts++;
          return jsonResponse({'message': 'bad gateway'}, status: 502);
        }),
      );
      expect(attempts, 1);
      expect(result.status, BonfireSwitchStatus.failed);
      expect(result.message, 'bad gateway');
    });
  });

  group('bonfireProfileTokenStillValid', () {
    test('a live 200 keeps the cached token', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/Users/$_guid/Views');
        return http.Response('[]', 200);
      });
      expect(await bonfireProfileTokenStillValid(_conn(), _guid, 'child-token', testClient: mock), isTrue);
    });

    test('a 401 (expired after master re-auth) invalidates the cached token', () async {
      final mock = MockClient((request) async => http.Response('', 401));
      expect(await bonfireProfileTokenStillValid(_conn(), _guid, 'child-token', testClient: mock), isFalse);
    });

    test('transport failure keeps the cached token (offline cold start)', () async {
      final mock = MockClient((request) async => throw http.ClientException('offline'));
      expect(await bonfireProfileTokenStillValid(_conn(), _guid, 'child-token', testClient: mock), isTrue);
    });
  });

  group('mintBonfireProfileToken persistence', () {
    setUp(() => resetSharedPreferencesForTest());

    // Fresh installs persist Jellyfin connections under the compound
    // machineId/userId row id, and profile_connections.connectionId carries
    // an FK to that row. Minted Bonfire tokens must land on the parent's
    // real row id — a bare machine id throws FOREIGN KEY constraint failed
    // and every profile switch dies at activation.
    test('join row references the parent connection row, not the machine id', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final parent = _conn().copyWith(id: 'machine-1/master-1');
      await ConnectionRegistry(db).upsert(parent);
      final registry = ProfileConnectionRegistry(db);
      final mock = MockClient(
        (request) async => jsonResponse({'activeProfileToken': 'scoped-token', 'jellyfinUserId': _guid}, status: 200),
      );

      final result = await mintBonfireProfileToken(
        parentConnection: parent,
        profileId: _guid,
        requiresPin: false,
        promptForPin: _noPrompt,
        persistTo: registry,
        persistProfileId: 'bonfire-machine-1-$_guid',
        testClient: mock,
      );
      expect(result.succeeded, isTrue);

      final rows = await registry.listForProfile('bonfire-machine-1-$_guid');
      expect(rows.single.connectionId, parent.id);
      expect(rows.single.connectionId, isNot(parent.serverMachineId));
      expect(rows.single.userToken, 'scoped-token');
    });

    test('a join row keyed by the bare machine id violates the connections FK', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await ConnectionRegistry(db).upsert(_conn().copyWith(id: 'machine-1/master-1'));
      final registry = ProfileConnectionRegistry(db);
      await expectLater(
        registry.upsert(
          ProfileConnection(
            profileId: 'bonfire-machine-1-$_guid',
            connectionId: 'machine-1',
            userToken: 'scoped-token',
            userIdentifier: _guid,
          ),
        ),
        throwsA(
          predicate(
            (Object? e) => e.toString().contains('FOREIGN KEY constraint failed'),
            'FOREIGN KEY constraint failed',
          ),
        ),
      );
    });
  });
}
