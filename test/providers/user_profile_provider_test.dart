import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/providers/user_profile_provider.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('UserProfileProvider (settings-only)', () {
    test('refreshProfileSettings without a stored token is a no-op', () async {
      final p = UserProfileProvider();
      var notified = 0;
      p.addListener(() => notified++);
      await p.refreshProfileSettings();
      // No token → no API call → no notify, no error.
      expect(notified, 0);
      expect(p.profileSettings, isNull);
      p.dispose();
    });

    test('logout without initialization is safe', () async {
      final p = UserProfileProvider();
      await p.logout();
      expect(p.profileSettings, isNull);
      p.dispose();
    });

    test('safeNotifyListeners after dispose does not throw', () async {
      final p = UserProfileProvider();
      p.dispose();
      await p.logout();
    });

    test('settings connection follows the profile default row', () async {
      final stack = await ProfileStack.create();
      final manager = MultiServerManager();
      addTearDown(() async {
        manager.dispose();
        await stack.dispose();
      });

      final profile = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
      final plex = PlexAccountConnection(
        id: 'plex-a',
        accountToken: 'plex-token',
        clientIdentifier: 'client-a',
        accountLabel: 'Plex',
        createdAt: DateTime(2026, 1, 1),
      );
      final jellyfin = JellyfinConnection(
        id: 'jf-machine/user-a',
        baseUrl: 'https://jf.example.com',
        serverName: 'Jellyfin',
        serverMachineId: 'jf-machine',
        userId: 'user-a',
        userName: 'User A',
        accessToken: 'jf-token',
        deviceId: 'device-a',
        createdAt: DateTime(2026, 1, 1),
      );
      await stack.profiles.upsert(profile);
      await stack.connections.upsert(plex);
      await stack.connections.upsert(jellyfin);
      await stack.profileConnections.upsert(
        ProfileConnection(
          profileId: profile.id,
          connectionId: plex.id,
          userToken: 'plex-user-token',
          userIdentifier: 'plex-user',
          isDefault: true,
        ),
        makeDefault: true,
      );
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
      );
      await stack.storage.setActiveProfileId(profile.id);
      await stack.active.initialize();

      final p = UserProfileProvider()
        ..attach(
          connections: stack.connections,
          activeProfile: stack.active,
          profileConnections: stack.profileConnections,
          serverManager: manager,
        );
      addTearDown(p.dispose);

      expect(await p.debugResolveActiveSettingsConnectionForTesting(), isA<PlexAccountConnection>());

      await stack.profileConnections.setDefault(profile.id, jellyfin.id);

      expect(await p.debugResolveActiveSettingsConnectionForTesting(), isA<JellyfinConnection>());
    });

    test('watches Plex Home profile connection rows', () async {
      final stack = await ProfileStack.create(
        homeUsers: [_homeUser(uuid: 'home-user-a', title: 'Home User')],
      );
      final manager = MultiServerManager();
      addTearDown(() async {
        manager.dispose();
        await stack.dispose();
      });

      final account = PlexAccountConnection(
        id: 'plex-a',
        accountToken: 'account-token-a',
        clientIdentifier: 'client-a',
        accountLabel: 'Plex A',
        createdAt: DateTime(2026, 1, 1),
      );
      await stack.connections.upsert(account);
      await stack.plexHome.refresh(account);
      await stack.storage.setActiveProfileId(
        plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: 'home-user-a'),
      );
      await stack.active.initialize();

      final p = UserProfileProvider()
        ..attach(
          connections: stack.connections,
          activeProfile: stack.active,
          profileConnections: stack.profileConnections,
          serverManager: manager,
        );
      addTearDown(p.dispose);

      expect(p.debugWatchedProfileConnectionProfileId, stack.active.activeId);
    });

    test('Plex Home profile without a switched token makes no user request', () async {
      final fixture = await _HomeProfileFixture.create();
      addTearDown(fixture.dispose);

      expect(await fixture.provider.debugResolveActivePlexUserTokenForTesting(), isNull);

      await fixture.provider.refreshProfileSettings();

      expect(fixture.requests, isEmpty);
      expect(fixture.provider.profileSettings, isNull);
    });

    test('Plex Home profile with an empty switched token makes no user request', () async {
      final fixture = await _HomeProfileFixture.create(switchedToken: '');
      addTearDown(fixture.dispose);

      expect(await fixture.provider.debugResolveActivePlexUserTokenForTesting(), isNull);

      await fixture.provider.refreshProfileSettings();

      expect(fixture.requests, isEmpty);
      expect(fixture.provider.profileSettings, isNull);
    });

    test('Plex Home profile requests and publishes settings with its exact switched token', () async {
      final fixture = await _HomeProfileFixture.create(switchedToken: 'switched-home-user-marker');
      addTearDown(fixture.dispose);

      expect(await fixture.provider.debugResolveActivePlexUserTokenForTesting(), 'switched-home-user-marker');

      await fixture.provider.refreshProfileSettings();

      expect(fixture.requests, hasLength(1));
      final request = fixture.requests.single;
      expect(request.url, Uri.parse('https://clients.plex.tv/api/v2/user'));
      expect(request.headers['X-Plex-Token'], 'switched-home-user-marker');
      expect(request.headers['X-Plex-Token'], isNot('parent-account-marker'));
      expect(fixture.provider.profileSettings?.autoSelectAudio, isFalse);
      expect(fixture.provider.profileSettings?.defaultAudioLanguage, 'jpn');
      expect(fixture.provider.profileSettings?.defaultAudioLanguages, ['jpn', 'eng']);
    });

    test('Plex token fallback uses the selected local profile account', () async {
      final stack = await ProfileStack.create();
      final manager = MultiServerManager();
      addTearDown(() async {
        manager.dispose();
        await stack.dispose();
      });

      final profile = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
      final accountA = PlexAccountConnection(
        id: 'plex-a',
        accountToken: 'wrong-owner-token',
        clientIdentifier: 'client-a',
        accountLabel: 'Plex A',
        createdAt: DateTime(2026, 1, 1),
      );
      final accountB = PlexAccountConnection(
        id: 'plex-b',
        accountToken: 'selected-owner-token',
        clientIdentifier: 'client-b',
        accountLabel: 'Plex B',
        createdAt: DateTime(2026, 1, 1),
      );
      await stack.profiles.upsert(profile);
      await stack.connections.upsert(accountA);
      await stack.connections.upsert(accountB);
      await stack.profileConnections.upsert(
        ProfileConnection(
          profileId: profile.id,
          connectionId: accountB.id,
          userIdentifier: 'home-user-b',
          isDefault: true,
        ),
        makeDefault: true,
      );
      await stack.storage.setActiveProfileId(profile.id);
      await stack.active.initialize();

      final requests = <http.Request>[];
      final auth = _recordingAuth(requests, audioLanguage: 'fra');
      addTearDown(auth.dispose);

      final p = UserProfileProvider(authService: auth)
        ..attach(
          connections: stack.connections,
          activeProfile: stack.active,
          profileConnections: stack.profileConnections,
          serverManager: manager,
        );
      addTearDown(p.dispose);

      expect(await p.debugResolveActivePlexUserTokenForTesting(), 'selected-owner-token');
      await p.refreshProfileSettings();
      expect(requests, hasLength(1));
      expect(requests.single.headers['X-Plex-Token'], 'selected-owner-token');
      expect(requests.single.headers['X-Plex-Token'], isNot('wrong-owner-token'));
      expect(p.profileSettings?.defaultAudioLanguage, 'fra');
    });
  });
}

PlexHomeUser _homeUser({required String uuid, required String title}) {
  return PlexHomeUser(
    id: 1,
    uuid: uuid,
    title: title,
    thumb: '',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: false,
    guest: true,
    protected: false,
  );
}

PlexAuthService _recordingAuth(List<http.Request> requests, {required String audioLanguage}) {
  return PlexAuthService.forTesting(
    http: MediaServerHttpClient(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'profile': {
              'autoSelectAudio': false,
              'defaultAudioAccessibility': 0,
              'defaultAudioLanguage': audioLanguage,
              'defaultAudioLanguages': [audioLanguage, 'eng'],
              'defaultSubtitleLanguage': 'eng',
              'defaultSubtitleLanguages': ['eng'],
              'autoSelectSubtitle': 0,
              'defaultSubtitleAccessibility': 0,
              'defaultSubtitleForced': 1,
              'watchedIndicator': 1,
              'mediaReviewsVisibility': 0,
              'mediaReviewsLanguages': ['eng'],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
  );
}

class _HomeProfileFixture {
  _HomeProfileFixture({required this.stack, required this.auth, required this.provider, required this.requests});

  final ProfileStack stack;
  final PlexAuthService auth;
  final UserProfileProvider provider;
  final List<http.Request> requests;

  static Future<_HomeProfileFixture> create({String? switchedToken}) async {
    final stack = await ProfileStack.create(
      homeUsers: [_homeUser(uuid: 'home-user-a', title: 'Home User')],
    );
    final account = PlexAccountConnection(
      id: 'plex-parent',
      accountToken: 'parent-account-marker',
      clientIdentifier: 'client-a',
      accountLabel: 'Plex Parent',
      createdAt: DateTime(2026, 1, 1),
    );
    await stack.connections.upsert(account);
    await stack.plexHome.refresh(account);

    final activeId = plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: 'home-user-a');
    if (switchedToken != null) {
      await stack.profileConnections.upsert(
        ProfileConnection(
          profileId: activeId,
          connectionId: account.id,
          userToken: switchedToken,
          userIdentifier: 'home-user-a',
          isDefault: true,
        ),
        makeDefault: true,
      );
    }
    await stack.storage.setActiveProfileId(activeId);
    await stack.active.initialize();

    final requests = <http.Request>[];
    final auth = _recordingAuth(requests, audioLanguage: 'jpn');
    final provider = UserProfileProvider(authService: auth)
      ..attach(
        connections: stack.connections,
        activeProfile: stack.active,
        profileConnections: stack.profileConnections,
      );
    return _HomeProfileFixture(stack: stack, auth: auth, provider: provider, requests: requests);
  }

  Future<void> dispose() async {
    provider.dispose();
    auth.dispose();
    await stack.dispose();
  }
}
