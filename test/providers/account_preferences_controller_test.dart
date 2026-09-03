import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('AccountPreferencesController.activePreferences', () {
    test('Plex Home profile without a switched token makes no request and has no preferences', () async {
      final fixture = await _Fixture.plexHome();
      addTearDown(fixture.dispose);

      await fixture.controller.ensureActiveLoaded();

      expect(fixture.requests, isEmpty);
      expect(fixture.controller.activePreferences, isNull);
    });

    test('Plex Home profile with an empty switched token makes no request', () async {
      final fixture = await _Fixture.plexHome(switchedToken: '');
      addTearDown(fixture.dispose);

      await fixture.controller.ensureActiveLoaded();

      expect(fixture.requests, isEmpty);
      expect(fixture.controller.activePreferences, isNull);
    });

    test('Plex Home profile loads with its exact switched token, never the owner token', () async {
      final fixture = await _Fixture.plexHome(switchedToken: 'switched-home-user-marker');
      addTearDown(fixture.dispose);

      await fixture.controller.ensureActiveLoaded();

      expect(fixture.requests, hasLength(1));
      final request = fixture.requests.single;
      expect(request.url, Uri.parse('https://clients.plex.tv/api/v2/user/profile'));
      expect(request.headers['X-Plex-Token'], 'switched-home-user-marker');
      final prefs = fixture.controller.activePreferences;
      expect(prefs?.autoSelectAudio, isFalse);
      expect(prefs?.defaultAudioLanguage, 'jpn');
    });

    test('a switched token minted after attach is picked up without a second initialize', () async {
      final fixture = await _Fixture.plexHome();
      addTearDown(fixture.dispose);
      await fixture.controller.ensureActiveLoaded();
      expect(fixture.requests, isEmpty);

      final loaded = fixture.nextLoad();
      await fixture.stack.profileConnections.upsert(
        ProfileConnection(
          profileId: fixture.stack.active.activeId!,
          connectionId: _Fixture.parentAccountId,
          userToken: 'late-minted-token',
          userIdentifier: _Fixture.homeUserUuid,
          isDefault: true,
        ),
        makeDefault: true,
      );
      await loaded;

      expect(fixture.requests.single.headers['X-Plex-Token'], 'late-minted-token');
      expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'jpn');
    });

    test('local profile reads with the selected account, not another bound owner token', () async {
      final fixture = await _Fixture.local();
      addTearDown(fixture.dispose);

      await fixture.controller.ensureActiveLoaded();

      expect(fixture.requests, hasLength(1));
      expect(fixture.requests.single.headers['X-Plex-Token'], 'selected-owner-token');
      expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'fra');
    });

    test('ensureActiveLoaded keeps an already loaded value instead of re-fetching', () async {
      final fixture = await _Fixture.local();
      addTearDown(fixture.dispose);

      await fixture.controller.ensureActiveLoaded();
      await fixture.controller.ensureActiveLoaded();

      expect(fixture.requests, hasLength(1));
    });

    test('a profile switch nulls the active preferences synchronously and notifies', () async {
      final fixture = await _Fixture.local();
      addTearDown(fixture.dispose);
      await fixture.controller.ensureActiveLoaded();
      expect(fixture.controller.activePreferences, isNotNull);

      final other = Profile.local(id: 'local-other', displayName: 'Other', createdAt: DateTime(2026, 1, 2));
      await fixture.stack.profiles.upsert(other);
      var notified = 0;
      fixture.controller.addListener(() => notified++);
      await fixture.stack.active.activate(other);

      expect(fixture.controller.activePreferences, isNull);
      expect(notified, greaterThan(0));
    });

    test('a settings-screen write to the active account is visible to playback', () async {
      final fixture = await _Fixture.local();
      addTearDown(fixture.dispose);
      await fixture.controller.ensureActiveLoaded();
      final ref = fixture.controller.accounts.single.ref;

      var notified = 0;
      fixture.controller.addListener(() => notified++);
      fixture.audioLanguage = 'deu';
      await fixture.controller.repository.load(ref, forceRefresh: true);

      expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'deu');
      expect(notified, 1);
    });

    test('accounts resolve from the registry watcher rows instead of one-shot re-queries', () async {
      final stack = await ProfileStack.create();
      final connections = _CountingConnectionRegistry(stack.db);
      final profileConnections = _CountingProfileConnectionRegistry(stack.db);
      final fixture = await _Fixture.local(
        stack: stack,
        connections: connections,
        profileConnections: profileConnections,
      );
      addTearDown(fixture.dispose);

      await fixture.controller.ensureActiveLoaded();
      expect(fixture.controller.accounts.single.ref.connectionId, 'plex-b');
      // The load's own token re-resolution is the only one-shot read; attach
      // and both watcher replays resolved from the delivered rows.
      expect(connections.listCalls, 1);
      expect(profileConnections.listCalls, 1);

      // Mutations that leave this profile's accounts unchanged still make the
      // watchers emit; nothing re-queries on top of that payload.
      final other = Profile.local(id: 'local-other', displayName: 'Other', createdAt: DateTime(2026, 1, 2));
      await stack.profiles.upsert(other);
      await stack.profileConnections.upsert(
        ProfileConnection(profileId: other.id, connectionId: 'plex-a', userIdentifier: 'home-user-a', isDefault: true),
        makeDefault: true,
      );
      await pumpEventQueue();
      expect(fixture.controller.accounts.single.ref.connectionId, 'plex-b');
      expect(connections.listCalls, 1);
      expect(profileConnections.listCalls, 1);
      expect(fixture.requests, hasLength(1));

      // A switch resolves against the new profile's rows only — never the
      // previous profile's retained payload.
      await stack.active.activate(other);
      await fixture.controller.ensureActiveLoaded();
      expect(fixture.controller.accounts.single.ref.connectionId, 'plex-a');
      expect(fixture.requests, hasLength(2));
      expect(fixture.requests.last.headers['X-Plex-Token'], 'wrong-owner-token');
    });
  });
}

class _Fixture {
  _Fixture._(this.stack, this.controller, this.requests);

  static const parentAccountId = 'plex-parent';
  static const homeUserUuid = 'home-user-a';

  final ProfileStack stack;
  final AccountPreferencesController controller;
  final List<http.Request> requests;
  String audioLanguage = 'jpn';

  /// Resolves when the repository next publishes a value for the active
  /// account.
  Future<void> nextLoad() {
    final completer = Completer<void>();
    late final StreamSubscription<Object?> sub;
    sub = controller.repository.changes.listen((_) {
      if (controller.activePreferences == null) return;
      sub.cancel();
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  static Future<_Fixture> plexHome({String? switchedToken}) async {
    final stack = await ProfileStack.create(
      homeUsers: [_homeUser(uuid: homeUserUuid, title: 'Home User')],
    );
    final account = PlexAccountConnection(
      id: parentAccountId,
      accountToken: 'parent-account-marker',
      clientIdentifier: 'client-a',
      accountLabel: 'Plex Parent',
      createdAt: DateTime(2026, 1, 1),
    );
    await stack.connections.upsert(account);
    await stack.plexHome.refresh(account);

    final activeId = plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: homeUserUuid);
    if (switchedToken != null) {
      await stack.profileConnections.upsert(
        ProfileConnection(
          profileId: activeId,
          connectionId: account.id,
          userToken: switchedToken,
          userIdentifier: homeUserUuid,
          isDefault: true,
        ),
        makeDefault: true,
      );
    }
    await stack.storage.setActiveProfileId(activeId);
    await stack.active.initialize();
    return _attach(stack, audioLanguage: 'jpn');
  }

  static Future<_Fixture> local({
    ProfileStack? stack,
    ConnectionRegistry? connections,
    ProfileConnectionRegistry? profileConnections,
  }) async {
    stack ??= await ProfileStack.create();
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
    return _attach(stack, audioLanguage: 'fra', connections: connections, profileConnections: profileConnections);
  }

  static _Fixture _attach(
    ProfileStack stack, {
    required String audioLanguage,
    ConnectionRegistry? connections,
    ProfileConnectionRegistry? profileConnections,
  }) {
    final requests = <http.Request>[];
    late final _Fixture fixture;
    final controller =
        AccountPreferencesController(
          plexServiceFactory: () async => _recordingAuth(requests, audioLanguage: () => fixture.audioLanguage),
        )..attach(
          connections: connections ?? stack.connections,
          profileConnections: profileConnections ?? stack.profileConnections,
          activeProfile: stack.active,
        );
    fixture = _Fixture._(stack, controller, requests)..audioLanguage = audioLanguage;
    return fixture;
  }

  Future<void> dispose() async {
    controller.dispose();
    await stack.dispose();
  }
}

class _CountingConnectionRegistry extends ConnectionRegistry {
  _CountingConnectionRegistry(super.db);

  int listCalls = 0;

  @override
  Future<List<Connection>> list() {
    listCalls++;
    return super.list();
  }
}

class _CountingProfileConnectionRegistry extends ProfileConnectionRegistry {
  _CountingProfileConnectionRegistry(super.db);

  int listCalls = 0;

  @override
  Future<List<ProfileConnection>> listForProfile(String profileId) {
    listCalls++;
    return super.listForProfile(profileId);
  }
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

PlexAuthService _recordingAuth(List<http.Request> requests, {required String Function() audioLanguage}) {
  return PlexAuthService.forTesting(
    http: MediaServerHttpClient(
      client: MockClient((request) async {
        requests.add(request);
        final language = audioLanguage();
        return http.Response(
          jsonEncode({
            'profile': {
              'autoSelectAudio': false,
              'defaultAudioLanguage': language,
              'defaultAudioLanguages': '$language,eng',
              'defaultSubtitleLanguage': 'eng',
              'defaultSubtitleLanguages': ['eng'],
              'autoSelectSubtitle': 0,
              'defaultSubtitleAccessibility': 0,
              'defaultSubtitleForced': 1,
              'watchedIndicator': 1,
              'mediaReviewsVisibility': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    ),
  );
}
