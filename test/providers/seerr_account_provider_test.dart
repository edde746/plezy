import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/seerr/seerr_session_store.dart';
import 'package:plezy/services/sensitive_prefs.dart';

import '../test_helpers/http_fixtures.dart';
import '../test_helpers/prefs.dart';

const _userUuid = 'profile-1';

/// A session as builds before #2213's fix persisted it for a local login:
/// the partial `/auth/local` body's `permissions: 0` and email display name.
/// No secret, so the store round-trips it without the credential vault.
SeerrSession _staleSession() => const SeerrSession(
  baseUrl: 'https://seerr.example.com',
  method: SeerrAuthMethod.local,
  identifier: 'a@b.c',
  secret: '',
  cookie: 'stored',
  userId: 7,
  permissions: 0,
  displayName: 'a@b.c',
  instanceLabel: 'Seerr',
  createdAt: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SeerrAccountProvider bind(MockClient mock) {
    resetSharedPreferencesForTest(
      initialAsync: {profileScopedPrefsKey(_userUuid, seerrSessionBaseKey): _staleSession().encode()},
    );
    final provider = SeerrAccountProvider(authService: SeerrAuthService(httpClientFactory: () => mock));
    addTearDown(provider.dispose);
    return provider;
  }

  test('a stored session re-reads its permissions from auth/me on bind', () async {
    final paths = <String>[];
    final provider = bind(
      MockClient((request) async {
        paths.add(request.url.path);
        expect(request.headers['Cookie'], '${SeerrConstants.sessionCookieName}=stored');
        return jsonResponse({'id': 7, 'displayName': 'Alice', 'permissions': SeerrPermission.request});
      }),
    );

    await provider.onActiveProfileChanged(_userUuid);
    // Binding exposes the stored snapshot at once; the refresh follows.
    expect(provider.session?.permissions, 0);
    await pumpEventQueue();

    expect(paths, ['/api/v1/auth/me']);
    expect(provider.session?.permissions, SeerrPermission.request);
    expect(provider.displayName, 'Alice');
    expect(provider.catalogClient?.session.permissions, SeerrPermission.request);
    final persisted = await const SeerrSessionStore().load(_userUuid);
    expect(persisted?.permissions, SeerrPermission.request);
    expect(persisted?.cookie, 'stored');
  });

  test('an unreachable instance leaves the stored snapshot bound', () async {
    final provider = bind(MockClient((request) async => throw http.ClientException('connection refused')));

    await provider.onActiveProfileChanged(_userUuid);
    await pumpEventQueue();

    expect(provider.isConnected, isTrue);
    expect(provider.session?.permissions, 0);
    expect((await const SeerrSessionStore().load(_userUuid))?.permissions, 0);
  });

  test('a JSON 401 from a gateway on the bind-time refresh keeps the stored session', () async {
    // Seerr never answers 401; the wall's JSON body is not Seerr's verdict
    // on the cookie, so the refresh fails without unlinking.
    final paths = <String>[];
    final provider = bind(
      MockClient((request) async {
        paths.add(request.url.path);
        return jsonResponse({'message': 'Unauthorized'}, status: 401);
      }),
    );

    await provider.onActiveProfileChanged(_userUuid);
    await pumpEventQueue();

    expect(paths, ['/api/v1/auth/me'], reason: 'no re-login through the wall');
    expect(provider.isConnected, isTrue);
    expect(provider.session?.cookie, 'stored');
    expect((await const SeerrSessionStore().load(_userUuid))?.cookie, 'stored');
  });

  test('a Seerr 403 on the bind-time refresh unlinks once re-auth has nothing to offer', () async {
    // Seerr's own middleware rejected the cookie and the stored session
    // carries no secret to re-login with: the credentials are gone for good.
    final provider = bind(
      MockClient(
        (request) async =>
            jsonResponse({'status': 403, 'error': 'You do not have permission to access this endpoint'}, status: 403),
      ),
    );

    await provider.onActiveProfileChanged(_userUuid);
    await pumpEventQueue();

    expect(provider.isConnected, isFalse);
    expect(provider.session, isNull);
    expect(await const SeerrSessionStore().load(_userUuid), isNull);
  });
}
