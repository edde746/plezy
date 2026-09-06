import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/services/seerr/seerr_session_store.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/sensitive_prefs.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

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

/// Hold the first password-protection operation before the session can be
/// written. This exercises the real vault and shared store, not a fake queue.
final class _DeferredVaultPreferences extends InMemorySharedPreferencesAsync {
  _DeferredVaultPreferences() : super.empty();

  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    if (key == credentialVaultKeyPref && !started.isCompleted) {
      started.complete();
      await release.future;
    }
    return super.setString(key, value, options);
  }
}

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

  test('coalesced explicit refresh recovers a grant and rejects a different principal', () async {
    final response = Completer<http.Response>();
    var calls = 0;
    var userId = 7;
    final provider = bind(
      MockClient((request) async {
        calls++;
        if (calls == 1) return jsonResponse({'id': 7, 'permissions': 0});
        if (calls == 2) return response.future;
        return jsonResponse({'id': userId, 'permissions': 0});
      }),
    );
    await provider.onActiveProfileChanged(_userUuid);
    await pumpEventQueue();
    final first = provider.refreshUser();
    final second = provider.refreshUser();
    response.complete(jsonResponse({'id': 7, 'permissions': SeerrPermission.request}));
    await Future.wait([first, second]);
    expect(calls, 2);
    expect(provider.permissions, SeerrPermission.request);
    userId = 99;
    await provider.refreshUser();
    expect(provider.permissions, SeerrPermission.request);
    expect(provider.session?.userId, 7);
    expect((await const SeerrSessionStore().load(_userUuid))?.permissions, SeerrPermission.request);
  });

  test('an old profile refresh cannot alter a newly adopted account or its saved cookie', () async {
    final response = Completer<http.Response>();
    final started = Completer<void>();
    final provider = bind(
      MockClient((request) async {
        started.complete();
        return response.future;
      }),
    );
    await provider.onActiveProfileChanged(_userUuid);
    await started.future;
    await provider.onActiveProfileChanged('profile-2');
    expect(provider.isConnected, isFalse);
    await provider.adoptSession(_staleSession().copyWith(cookie: 'new-account', permissions: SeerrPermission.request));
    response.complete(jsonResponse({'id': 7, 'permissions': SeerrPermission.admin}));
    await pumpEventQueue();
    expect(provider.session?.cookie, 'new-account');
    expect(provider.permissions, SeerrPermission.request);
    expect((await const SeerrSessionStore().load('profile-2'))?.cookie, 'new-account');
    expect((await const SeerrSessionStore().load(_userUuid))?.permissions, 0);
  });

  _DeferredVaultPreferences deferVault() {
    resetSharedPreferencesForTest();
    CredentialVault.resetKeyForTesting();
    addTearDown(CredentialVault.resetKeyForTesting);
    final prefs = _DeferredVaultPreferences();
    SharedPreferencesAsyncPlatform.instance = prefs;
    return prefs;
  }

  SeerrAccountProvider offlineAccount() {
    final account = SeerrAccountProvider(
      authService: SeerrAuthService(
        httpClientFactory: () => MockClient((_) async => throw http.ClientException('offline')),
      ),
    );
    return account;
  }

  test('a recreated provider loads after the disposed provider finishes protecting its save', () async {
    final prefs = deferVault();
    final old = offlineAccount();
    await old.onActiveProfileChanged(_userUuid);
    final save = old.adoptSession(_staleSession().copyWith(cookie: 'rotated', secret: 'password'));
    await prefs.started.future;
    old.dispose();
    final current = offlineAccount();
    addTearDown(current.dispose);
    final load = current.onActiveProfileChanged(_userUuid);
    prefs.release.complete();
    await Future.wait([save, load]);
    await current.refreshUser();
    expect(current.session?.cookie, 'rotated');
    expect(current.session?.secret, 'password');
    expect((await const SeerrSessionStore().load(_userUuid))?.cookie, 'rotated');
  });

  test('disconnect clears after a deferred adoption and cannot resurrect its session', () async {
    final prefs = deferVault();
    final account = offlineAccount();
    addTearDown(account.dispose);
    await account.onActiveProfileChanged(_userUuid);
    final save = account.adoptSession(_staleSession().copyWith(secret: 'password'));
    await prefs.started.future;
    final clear = account.disconnect();
    prefs.release.complete();
    await Future.wait([save, clear]);
    expect(account.isConnected, isFalse);
    expect(await const SeerrSessionStore().load(_userUuid), isNull);
  });

  test('a recreated provider adoption supersedes its pending load and the disposed provider save', () async {
    final prefs = deferVault();
    final old = offlineAccount();
    await old.onActiveProfileChanged(_userUuid);
    final oldSave = old.adoptSession(_staleSession().copyWith(cookie: 'old', secret: 'old-password'));
    await prefs.started.future;
    old.dispose();
    final current = offlineAccount();
    addTearDown(current.dispose);
    final load = current.onActiveProfileChanged(_userUuid);
    final newSave = current.adoptSession(_staleSession().copyWith(cookie: 'new', secret: 'new-password'));
    prefs.release.complete();
    await Future.wait([oldSave, load, newSave]);
    final persisted = await const SeerrSessionStore().load(_userUuid);
    expect(current.session?.cookie, 'new');
    expect(current.session?.secret, 'new-password');
    expect(persisted?.cookie, 'new');
    expect(persisted?.secret, 'new-password');
  });
}
