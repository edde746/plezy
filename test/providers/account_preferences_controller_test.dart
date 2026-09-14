import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/account_preferences.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/providers/account_preferences_controller.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
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
      await fixture.controller.repository.update(
        ref,
        AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, 'deu'),
      );

      expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'deu');
      expect(notified, 1);
    });

    for (final dialect in MediaBrowserDialect.values) {
      test('Home jpn survives a borrowed $dialect default, inverse changes and profile switches', () async {
        final fixture = await _Fixture.plexHome(switchedToken: 'home-token');
        addTearDown(fixture.dispose);
        await fixture.controller.ensureActiveLoaded();
        final home = fixture.stack.active.active!;
        final borrowed = testJellyfinConnection(dialect: dialect);
        await fixture.bindBorrowed(borrowed);
        await pumpEventQueue();
        await fixture.controller.ensureActiveLoaded();
        expect(fixture.controller.accounts.first.ref.connectionId, borrowed.id);
        expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'jpn');

        fixture.registerBorrowedClient(borrowed, language: 'deu');
        final borrowedRef = fixture.controller.accounts.first.ref;
        await fixture.controller.repository.load(borrowedRef);
        expect(fixture.controller.repository.cached(borrowedRef)?.defaultAudioLanguage, 'deu');
        expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'jpn');

        await fixture.stack.profileConnections.setDefault(home.id, _Fixture.parentAccountId);
        await pumpEventQueue();
        await fixture.controller.ensureActiveLoaded();
        expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'jpn');
        await fixture.stack.profileConnections.setDefault(home.id, borrowed.id);
        await pumpEventQueue();
        final other = Profile.local(id: 'other', displayName: 'Other', createdAt: DateTime(2026));
        await fixture.stack.profiles.upsert(other);
        await fixture.stack.active.activate(other);
        expect(fixture.controller.activePreferences, isNull);
        await fixture.stack.active.activate(home);
        await fixture.controller.ensureActiveLoaded();
        expect(fixture.controller.accounts.first.ref.connectionId, borrowed.id);
        expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'jpn');
        await fixture.stack.profileConnections.remove(home.id, borrowed.id);
        await pumpEventQueue();
        await fixture.controller.ensureActiveLoaded();
        expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'jpn');
        expect(fixture.requests.every((request) => request.headers['X-Plex-Token'] == 'home-token'), isTrue);
      });

      test('local $dialect default selects its own preferences without reachable-account substitution', () async {
        final fixture = await _Fixture.local();
        addTearDown(fixture.dispose);
        await fixture.controller.ensureActiveLoaded();
        final borrowed = testJellyfinConnection(dialect: dialect);
        await fixture.bindBorrowed(borrowed);
        await pumpEventQueue();
        await fixture.controller.ensureActiveLoaded();
        expect(fixture.controller.activePreferences, isNull);
        fixture.registerBorrowedClient(borrowed, language: 'deu');
        await fixture.controller.ensureActiveLoaded();
        expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'deu');
        await fixture.stack.profileConnections.setDefault(fixture.stack.active.activeId!, 'plex-b');
        await pumpEventQueue();
        await fixture.controller.ensureActiveLoaded();
        expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'fra');
      });
    }

    test('a borrowed default before Home token mint never supplies playback preferences', () async {
      final fixture = await _Fixture.plexHome();
      addTearDown(fixture.dispose);
      final borrowed = testJellyfinConnection();
      fixture.registerBorrowedClient(borrowed, language: 'deu');
      await fixture.bindBorrowed(borrowed);
      await pumpEventQueue();
      await fixture.controller.ensureActiveLoaded();
      expect(fixture.controller.accounts.single.ref.connectionId, borrowed.id);
      expect(fixture.controller.activePreferences, isNull);
      expect(fixture.requests, isEmpty);
      final loaded = fixture.nextLoad();
      await fixture.stack.profileConnections.upsert(
        ProfileConnection(
          profileId: fixture.stack.active.activeId!,
          connectionId: _Fixture.parentAccountId,
          userIdentifier: _Fixture.homeUserUuid,
          userToken: 'late-home-token',
        ),
      );
      await loaded;
      expect(fixture.controller.accounts.first.ref.connectionId, borrowed.id);
      expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'jpn');
    });

    test('removing Home credentials publishes null rather than the previous cache or borrowed identity', () async {
      final fixture = await _Fixture.plexHome(switchedToken: 'home-token');
      addTearDown(fixture.dispose);
      await fixture.controller.ensureActiveLoaded();
      final borrowed = testJellyfinConnection();
      await fixture.bindBorrowed(borrowed);
      await pumpEventQueue();
      final observed = <String?>[];
      fixture.controller.addListener(() => observed.add(fixture.controller.activePreferences?.defaultAudioLanguage));
      await fixture.stack.profileConnections.recordToken(fixture.stack.active.activeId!, _Fixture.parentAccountId, '');
      await pumpEventQueue();
      await fixture.controller.ensureActiveLoaded();
      expect(fixture.controller.activePreferences, isNull);
      expect(observed, isNotEmpty);
      expect(observed, everyElement(isNull));
    });

    test('an old load cannot repopulate preferences after A to B to A', () async {
      final fixture = await _Fixture.local();
      addTearDown(fixture.dispose);
      await fixture.controller.ensureActiveLoaded();
      final original = fixture.stack.active.active!;
      final oldGate = Completer<void>();
      final started = Completer<void>();
      fixture.responseGate = oldGate.future;
      fixture.requestStarted = started;
      final oldLoad = fixture.controller.repository.load(fixture.controller.accounts.single.ref, forceRefresh: true);
      await started.future;
      final other = Profile.local(id: 'other', displayName: 'Other', createdAt: DateTime(2026));
      await fixture.stack.profiles.upsert(other);
      await fixture.stack.active.activate(other);
      fixture.responseGate = null;
      fixture.audioLanguage = 'deu';
      await fixture.stack.active.activate(original);
      await fixture.controller.ensureActiveLoaded();
      expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'deu');
      oldGate.complete();
      await oldLoad;
      expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'deu');
    });

    test('same-principal token refresh detaches an old load before publishing the replacement', () async {
      final fixture = await _Fixture.plexHome(switchedToken: 'old-token');
      addTearDown(fixture.dispose);
      await fixture.controller.ensureActiveLoaded();
      final oldGate = Completer<void>();
      final started = Completer<void>();
      fixture.responseGate = oldGate.future;
      fixture.requestStarted = started;
      final oldLoad = fixture.controller.repository.load(fixture.controller.accounts.single.ref, forceRefresh: true);
      await started.future;
      fixture.responseGate = null;
      fixture.audioLanguage = 'deu';
      final replacement = fixture.nextLoad();
      await fixture.stack.profileConnections.recordToken(
        fixture.stack.active.activeId!,
        _Fixture.parentAccountId,
        'new-token',
      );
      await replacement;
      expect(fixture.requests.last.headers['X-Plex-Token'], 'new-token');
      oldGate.complete();
      await oldLoad;
      expect(fixture.controller.activePreferences?.defaultAudioLanguage, 'deu');
    });
  });
}

class _Fixture {
  _Fixture._(this.stack, this.controller, this.requests, this.serverManager);

  static const parentAccountId = 'plex-parent';
  static const homeUserUuid = 'home-user-a';

  final ProfileStack stack;
  final AccountPreferencesController controller;
  final List<http.Request> requests;
  String audioLanguage = 'jpn';
  final MultiServerManager serverManager;
  Future<void>? responseGate;
  Completer<void>? requestStarted;

  Future<void> bindBorrowed(JellyfinConnection connection) async {
    await stack.connections.upsert(connection);
    await stack.profileConnections.upsert(
      ProfileConnection(
        profileId: stack.active.activeId!,
        connectionId: connection.id,
        userIdentifier: connection.userId,
        userToken: connection.accessToken,
        isDefault: true,
      ),
      makeDefault: true,
    );
  }

  void registerBorrowedClient(JellyfinConnection connection, {required String language}) {
    serverManager.debugRegisterJellyfinClientForTesting(
      testJellyfinClient(
        connection: connection,
        handler: (request) async => jsonResponse(
          request.url.path.contains('/DisplayPreferences/')
              ? {'CustomPrefs': <String, dynamic>{}}
              : {
                  'Configuration': {'AudioLanguagePreference': language},
                },
        ),
      ),
    );
  }

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

  static Future<_Fixture> local() async {
    final stack = await ProfileStack.create();
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
    return _attach(stack, audioLanguage: 'fra');
  }

  static _Fixture _attach(ProfileStack stack, {required String audioLanguage}) {
    final requests = <http.Request>[];
    final serverManager = MultiServerManager();
    late final _Fixture fixture;
    final controller =
        AccountPreferencesController(
          plexServiceFactory: () async => _recordingAuth(
            requests,
            audioLanguage: () => fixture.audioLanguage,
            responseGate: () => fixture.responseGate,
            onRequest: () {
              final started = fixture.requestStarted;
              if (started != null && !started.isCompleted) started.complete();
            },
          ),
        )..attach(
          connections: stack.connections,
          profileConnections: stack.profileConnections,
          activeProfile: stack.active,
          serverManager: serverManager,
        );
    fixture = _Fixture._(stack, controller, requests, serverManager)..audioLanguage = audioLanguage;
    return fixture;
  }

  Future<void> dispose() async {
    controller.dispose();
    serverManager.dispose();
    await stack.dispose();
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

PlexAuthService _recordingAuth(
  List<http.Request> requests, {
  required String Function() audioLanguage,
  required Future<void>? Function() responseGate,
  required void Function() onRequest,
}) {
  return PlexAuthService.forTesting(
    http: MediaServerHttpClient(
      client: MockClient((request) async {
        requests.add(request);
        final language = audioLanguage();
        final gate = responseGate();
        onRequest();
        await gate;
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
