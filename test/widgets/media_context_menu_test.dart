import '../test_helpers/paged_fakes.dart';
import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/navigation/profile_navigation_scope.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_file_info.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/metadata_edit/metadata_edit_adapters.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/models/catalog/catalog_item.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/providers/download_provider.dart';
import 'package:plezy/providers/catalog_sources_provider.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/offline_mode_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/music/album_detail_screen.dart';
import 'package:plezy/screens/music/artist_detail_screen.dart';
import 'package:plezy/services/download_manager_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/catalog/catalog_source.dart';
import 'package:plezy/utils/deletion_notifier.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/media_server_timeouts.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/file_info_bottom_sheet.dart';
import 'package:plezy/widgets/media_context_menu.dart';
import 'package:provider/provider.dart';
import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/multi_server_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';
import '../test_helpers/stub_music_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isAdminActionAllowedForMediaItem', () {
    test('blocks non-admin Plex Home users on Plex items', () {
      final profile = Profile.virtualPlexHome(connectionId: 'plex-1', homeUser: _homeUser(admin: false));

      expect(
        isAdminActionAllowedForMediaItem(isOwnerOrAdmin: true, itemBackend: MediaBackend.plex, activeProfile: profile),
        isFalse,
      );
    });

    test('does not apply Plex Home role to Jellyfin items', () {
      final profile = Profile.virtualPlexHome(connectionId: 'plex-1', homeUser: _homeUser(admin: false));

      expect(
        isAdminActionAllowedForMediaItem(
          isOwnerOrAdmin: true,
          itemBackend: MediaBackend.jellyfin,
          activeProfile: profile,
        ),
        isTrue,
      );
    });

    test('allows Plex admin Home users on Plex items', () {
      final profile = Profile.virtualPlexHome(connectionId: 'plex-1', homeUser: _homeUser(admin: true));

      expect(
        isAdminActionAllowedForMediaItem(isOwnerOrAdmin: true, itemBackend: MediaBackend.plex, activeProfile: profile),
        isTrue,
      );
    });
  });

  group('isMediaDeletionAllowed', () {
    test('Jellyfin follows the server answer, not the admin bit', () {
      // Jellyfin's own check (`BaseItem.IsAuthorizedToDelete`) never consults
      // `IsAdministrator` for library items, and only the first user created on
      // a server gets `EnableContentDeletion` for free.
      expect(
        isMediaDeletionAllowed(
          itemBackend: MediaBackend.jellyfin,
          resolvedItemPermission: false,
          isAdminActionAllowed: true,
        ),
        isFalse,
      );
      expect(
        isMediaDeletionAllowed(
          itemBackend: MediaBackend.jellyfin,
          resolvedItemPermission: true,
          isAdminActionAllowed: false,
        ),
        isTrue,
      );
    });

    test('Jellyfin fails closed when the permission is unknown', () {
      expect(
        isMediaDeletionAllowed(
          itemBackend: MediaBackend.jellyfin,
          resolvedItemPermission: null,
          isAdminActionAllowed: true,
        ),
        isFalse,
      );
    });

    test('Emby follows the server answer, not the admin bit', () {
      expect(
        isMediaDeletionAllowed(
          itemBackend: MediaBackend.emby,
          resolvedItemPermission: false,
          isAdminActionAllowed: true,
        ),
        isFalse,
      );
      expect(
        isMediaDeletionAllowed(
          itemBackend: MediaBackend.emby,
          resolvedItemPermission: true,
          isAdminActionAllowed: false,
        ),
        isTrue,
      );
    });

    test('Emby fails closed when the permission is unknown', () {
      expect(
        isMediaDeletionAllowed(
          itemBackend: MediaBackend.emby,
          resolvedItemPermission: null,
          isAdminActionAllowed: true,
        ),
        isFalse,
      );
    });

    test('Plex keeps its account-level gate', () {
      expect(
        isMediaDeletionAllowed(
          itemBackend: MediaBackend.plex,
          resolvedItemPermission: null,
          isAdminActionAllowed: true,
        ),
        isTrue,
      );
      expect(
        isMediaDeletionAllowed(
          itemBackend: MediaBackend.plex,
          resolvedItemPermission: null,
          isAdminActionAllowed: false,
        ),
        isFalse,
      );
    });

    test('an item with no backend marker is never deletable', () {
      expect(
        isMediaDeletionAllowed(itemBackend: null, resolvedItemPermission: true, isAdminActionAllowed: true),
        isFalse,
      );
    });
  });

  group('MediaContextMenu delete gate', () {
    testWidgets('hides delete for an administrator the server refuses (issue #1749)', (tester) async {
      final menuKey = await _pumpJellyfinMovieMenu(
        tester,
        isAdministrator: true,
        handler: (_) async => _canDeleteResponse('movie-1', false),
      );

      await _openMenu(tester, menuKey);

      expect(find.text(t.mediaMenu.deleteMovieFromServer), findsNothing);
    });

    testWidgets('shows delete for a non-admin the server permits', (tester) async {
      final requests = <Uri>[];
      final menuKey = await _pumpJellyfinMovieMenu(
        tester,
        isAdministrator: false,
        requests: requests,
        handler: (_) async => _canDeleteResponse('movie-1', true),
      );

      await _openMenu(tester, menuKey);

      expect(find.text(t.mediaMenu.deleteMovieFromServer), findsOneWidget);
      final probes = requests.where((uri) => uri.queryParameters['Fields'] == 'CanDelete').toList();
      expect(probes, hasLength(1));
      expect(probes.single.queryParameters['ids'], 'movie-1');
    });

    testWidgets('shows delete for a library-granted user inside the grant', (tester) async {
      final menuKey = await _pumpJellyfinMovieMenu(
        tester,
        isAdministrator: false,
        itemId: 'movie-in-grant',
        handler: _libraryGrantedToOneMovie,
      );

      await _openMenu(tester, menuKey);

      expect(find.text(t.mediaMenu.deleteMovieFromServer), findsOneWidget);
    });

    testWidgets('hides delete for a library-granted user outside the grant', (tester) async {
      final menuKey = await _pumpJellyfinMovieMenu(
        tester,
        isAdministrator: false,
        itemId: 'movie-outside-grant',
        handler: _libraryGrantedToOneMovie,
      );

      await _openMenu(tester, menuKey);

      expect(find.text(t.mediaMenu.deleteMovieFromServer), findsNothing);
    });

    testWidgets('hides delete when the permission probe fails', (tester) async {
      final menuKey = await _pumpJellyfinMovieMenu(
        tester,
        isAdministrator: true,
        handler: (_) async => http.Response('boom', 500),
      );

      await _openMenu(tester, menuKey);

      expect(find.text(t.mediaMenu.deleteMovieFromServer), findsNothing);
      expect(tester.takeException(), isNull);
      // The menu itself still opened; only the destructive entry is missing.
      expect(find.text(t.mediaMenu.fileInfo), findsOneWidget);
    });

    testWidgets('hides delete without probing while the item server is offline', (tester) async {
      final requests = <Uri>[];
      final menuKey = await _pumpJellyfinMovieMenu(
        tester,
        isAdministrator: true,
        serverOnline: false,
        requests: requests,
        handler: (_) async => _canDeleteResponse('movie-1', true),
      );

      await _openMenu(tester, menuKey);

      expect(find.text(t.mediaMenu.deleteMovieFromServer), findsNothing);
      expect(requests.where((uri) => uri.queryParameters['Fields'] == 'CanDelete'), isEmpty);
    });

    testWidgets('still opens the menu, without delete, when the probe hangs', (tester) async {
      final menuKey = await _pumpJellyfinMovieMenu(
        tester,
        isAdministrator: true,
        handler: (_) => Completer<http.Response>().future,
      );

      menuKey.currentState!.showContextMenu(tester.element(find.text('delete target')));
      await tester.pump();
      expect(find.text(t.mediaMenu.fileInfo), findsNothing, reason: 'the menu waits for the permission answer');

      await tester.pump(MediaServerTimeouts.jellyfinDeletePermission + const Duration(milliseconds: 1));
      await tester.pumpAndSettle();

      expect(find.text(t.mediaMenu.fileInfo), findsOneWidget);
      expect(find.text(t.mediaMenu.deleteMovieFromServer), findsNothing);
    });
  });

  group('MediaContextMenu delete confirmation', () {
    testWidgets('names the episode, never the show, at every step (issue #1781)', (tester) async {
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(id: 'ep-2', index: 2, file: '/tv/bb/S01E02.mkv'),
        handler: _deleteFlowHandler(
          episodes: [_episodeJson(id: 'ep-2', index: 2, path: '/tv/bb/S01E02.mkv')],
        ),
      );

      await _openMenu(tester, menuKey);
      expect(find.text(t.mediaMenu.deleteEpisodeFromServer), findsOneWidget);
      expect(find.text(t.mediaMenu.deleteShowFromServer), findsNothing);

      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(find.descendant(of: dialog, matching: find.text(t.mediaMenu.deleteEpisodeTitle)), findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(t.mediaMenu.confirmDeleteTarget(title: 'Breaking Bad · S1 E2 · Cat in the Bag')),
        ),
        findsOneWidget,
        reason: 'the confirmation must name the episode; displayTitle would render only "Breaking Bad"',
      );
      expect(find.descendant(of: dialog, matching: find.text(t.mediaMenu.deleteEpisodeConfirm)), findsOneWidget);
      expect(find.text(t.mediaMenu.deleteMultipleWarning), findsNothing);
    });

    testWidgets('a show delete says so and states the episode count', (tester) async {
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: testMediaItem(
          id: 'show-1',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.show,
          title: 'Breaking Bad',
          serverId: 'srv-1',
          leafCount: 62,
        ),
        handler: _deleteFlowHandler(episodes: const []),
      );

      await _openMenu(tester, menuKey);
      expect(find.text(t.mediaMenu.deleteShowFromServer), findsOneWidget);
      expect(find.text(t.mediaMenu.deleteEpisodeFromServer), findsNothing);

      await tester.tap(find.text(t.mediaMenu.deleteShowFromServer));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(find.descendant(of: dialog, matching: find.text(t.mediaMenu.deleteShowTitle)), findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text(t.mediaMenu.deleteEpisodeCountWarning(n: 62))),
        findsOneWidget,
      );
      expect(find.descendant(of: dialog, matching: find.text(t.mediaMenu.deleteShowConfirm)), findsOneWidget);
    });

    testWidgets('cancelling issues no delete request', (tester) async {
      final requests = <Uri>[];
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        requests: requests,
        item: _episode(id: 'ep-2', index: 2, file: '/tv/bb/S01E02.mkv'),
        handler: _deleteFlowHandler(
          episodes: [_episodeJson(id: 'ep-2', index: 2, path: '/tv/bb/S01E02.mkv')],
        ),
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(requests.where((uri) => uri.path.contains('/Items/ep-2')), isEmpty);
    });

    testWidgets('confirming deletes exactly the focused episode', (tester) async {
      final deleted = <String>[];
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(id: 'ep-2', index: 2, file: '/tv/bb/S01E02.mkv'),
        handler: _deleteFlowHandler(
          episodes: [
            _episodeJson(id: 'ep-1', index: 1, path: '/tv/bb/S01E01.mkv'),
            _episodeJson(id: 'ep-2', index: 2, path: '/tv/bb/S01E02.mkv'),
            _episodeJson(id: 'ep-3', index: 3, path: '/tv/bb/S01E03.mkv'),
          ],
          onDelete: deleted.add,
        ),
      );

      await _confirmDelete(tester, menuKey, t.mediaMenu.deleteEpisodeConfirm);

      expect(deleted, ['ep-2'], reason: 'siblings in the same folder must be untouched');
    });

    testWidgets('warns about episodes sharing the file and reports them deleted', (tester) async {
      const sharedFile = '/tv/bb/S01E02-E03.mkv';
      final events = <String>[];
      final subscription = DeletionNotifier().stream.listen((event) => events.add(event.itemId));
      addTearDown(subscription.cancel);

      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(id: 'ep-2', index: 2, file: sharedFile),
        handler: _deleteFlowHandler(
          episodes: [
            _episodeJson(id: 'ep-1', index: 1, path: '/tv/bb/S01E01.mkv'),
            _episodeJson(id: 'ep-2', index: 2, path: sharedFile),
            _episodeJson(id: 'ep-3', index: 3, path: sharedFile),
          ],
        ),
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();

      expect(find.textContaining(t.mediaMenu.deleteSharedFileHeading(n: 1)), findsOneWidget);
      expect(find.textContaining('S1 E3'), findsOneWidget);

      await tester.tap(find.text(t.mediaMenu.deleteEpisodeConfirm));
      await tester.pumpAndSettle();

      expect(events, containsAll(<String>['ep-2', 'ep-3']));
      expect(events, isNot(contains('ep-1')));
    });

    testWidgets('a long shared-file list scrolls instead of overflowing a phone dialog', (tester) async {
      const sharedFile = '/tv/bb/S01E01-E08.mkv';
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(id: 'ep-1', index: 1, file: sharedFile),
        handler: _deleteFlowHandler(
          episodes: [for (var i = 1; i <= 8; i++) _episodeJson(id: 'ep-$i', index: i, path: sharedFile)],
        ),
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();

      expect(find.textContaining(t.mediaMenu.deleteSharedFileHeading(n: 7)), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'the warning block must scroll, not overflow');
    });

    testWidgets('system back during the impact probe keeps the spinner and the screen', (tester) async {
      // The spinner is documented non-dismissible, but barrierDismissible
      // alone does not stop system back. If back popped it, the probe's
      // cleanup would pop the screen underneath instead.
      final gate = Completer<void>();
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        onPushedRoute: true,
        item: _episode(id: 'ep-2', index: 2, file: '/tv/bb/S01E02.mkv'),
        handler: (request) async {
          if (request.url.queryParameters.containsKey('ParentId')) {
            await gate.future;
            return jsonResponse({
              'Items': [_episodeJson(id: 'ep-2', index: 2, path: '/tv/bb/S01E02.mkv')],
              'TotalRecordCount': 1,
            });
          }
          if (request.url.queryParameters['Fields'] == 'CanDelete') {
            return _canDeleteResponse(request.url.queryParameters['ids'] ?? '', true);
          }
          if (request.url.path.contains('/Seasons')) return jsonResponse({'Items': <Object?>[]});
          return jsonResponse({'Items': <Object?>[]});
        },
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.binding.handlePopRoute();
      // Bounded pumps only: pumpAndSettle would run the fake clock past
      // MediaServerTimeouts.deleteImpactProbe and close the spinner by
      // timeout, hiding whatever back actually did.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'the spinner is non-dismissible');
      expect(find.text('home screen'), findsNothing, reason: 'the screen under the spinner must survive back');

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('home screen'), findsNothing);
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text(t.mediaMenu.deleteEpisodeConfirm)),
        findsOneWidget,
      );
    });

    testWidgets('warns when the episode is split across several files', (tester) async {
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(
          id: 'ep-2',
          index: 2,
          versions: [
            MediaVersion(
              id: 'v-1',
              parts: const [
                MediaPart(id: 'p-1', file: '/tv/bb/S01E02-cd1.mkv'),
                MediaPart(id: 'p-2', file: '/tv/bb/S01E02-cd2.mkv'),
              ],
            ),
          ],
        ),
        handler: _deleteFlowHandler(
          episodes: [_episodeJson(id: 'ep-2', index: 2, path: '/tv/bb/S01E02-cd1.mkv')],
        ),
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();

      expect(find.textContaining(t.mediaMenu.deleteMultiPartWarning(n: 2)), findsOneWidget);
    });

    testWidgets('refuses to imply single-file scope when the server withholds paths', (tester) async {
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(
          id: 'ep-2',
          index: 2,
          versions: const [
            MediaVersion(
              id: 'v-1',
              parts: [MediaPart(id: 'p-1')],
            ),
          ],
        ),
        handler: _deleteFlowHandler(
          episodes: [_episodeJson(id: 'ep-2', index: 2, path: null)],
          details: {'ep-2': _episodeJson(id: 'ep-2', index: 2, path: null)},
        ),
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text(t.mediaMenu.deleteScopeUnverifiedNoFileInfo)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text(t.mediaMenu.deleteAnyway)),
        findsOneWidget,
        reason: 'an unverified scope must not offer the confident per-kind confirm label',
      );
      expect(find.text(t.mediaMenu.deleteEpisodeConfirm), findsNothing);
    });

    testWidgets('recovers scope from the detail endpoint when the browse row omitted paths', (tester) async {
      // PlexMappers synthesizes a single file-less part for a thin row, and
      // Jellyfin resume rows can arrive without MediaSources. Treating that as
      // "server withholds paths" would make the danger warning the default
      // even though the detail endpoint answers.
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(
          id: 'ep-2',
          index: 2,
          versions: const [
            MediaVersion(
              id: 'v-1',
              parts: [MediaPart(id: 'p-1')],
            ),
          ],
        ),
        handler: _deleteFlowHandler(
          episodes: [
            _episodeJson(id: 'ep-1', index: 1, path: '/tv/bb/S01E01.mkv'),
            _episodeJson(id: 'ep-2', index: 2, path: '/tv/bb/S01E02.mkv'),
          ],
          details: {'ep-2': _episodeJson(id: 'ep-2', index: 2, path: '/tv/bb/S01E02.mkv')},
        ),
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(find.descendant(of: dialog, matching: find.text(t.mediaMenu.deleteEpisodeConfirm)), findsOneWidget);
      expect(find.text(t.mediaMenu.deleteAnyway), findsNothing);
      expect(find.text(t.mediaMenu.deleteScopeUnverifiedNoFileInfo), findsNothing);
      expect(find.text(t.mediaMenu.deleteScopeUnverifiedProbeFailed), findsNothing);
    });

    testWidgets('resolves a path-less sibling row before ruling out a shared file', (tester) async {
      // The sibling browse row carries no path. Trusting it would report the
      // delete as exclusive while the server destroys ep-3 along with it.
      const sharedFile = '/tv/bb/S01E02-E03.mkv';
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(id: 'ep-2', index: 2, file: sharedFile),
        handler: _deleteFlowHandler(
          episodes: [
            _episodeJson(id: 'ep-2', index: 2, path: sharedFile),
            _episodeJson(id: 'ep-3', index: 3, path: null),
          ],
          details: {'ep-3': _episodeJson(id: 'ep-3', index: 3, path: sharedFile)},
        ),
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();

      expect(find.textContaining(t.mediaMenu.deleteSharedFileHeading(n: 1)), findsOneWidget);
      expect(find.textContaining('S1 E3'), findsOneWidget);
    });

    testWidgets('flags an unverified scope when the sibling lookup fails, and still deletes', (tester) async {
      final deleted = <String>[];
      final menuKey = await _pumpJellyfinItemMenu(
        tester,
        isAdministrator: true,
        item: _episode(id: 'ep-2', index: 2, file: '/tv/bb/S01E02.mkv'),
        handler: _deleteFlowHandler(episodes: null, onDelete: deleted.add),
      );

      await _openMenu(tester, menuKey);
      await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
      await tester.pumpAndSettle();

      expect(find.text(t.mediaMenu.deleteScopeUnverifiedProbeFailed), findsOneWidget);

      await tester.tap(find.text(t.mediaMenu.deleteAnyway));
      await tester.pumpAndSettle();

      expect(deleted, ['ep-2']);
    });
  });

  group('supportsMetadataEdit', () {
    test('allows Jellyfin video metadata edit through capability gate', () {
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection(),
        httpClient: MockClient((_) async => http.Response('', 204)),
      );
      addTearDown(client.close);

      expect(supportsMetadataEdit(client, MediaKind.movie), isTrue);
      expect(supportsMetadataEdit(client, MediaKind.show), isTrue);
      expect(supportsMetadataEdit(client, MediaKind.track), isFalse);
    });
  });

  group('MediaContextMenu actions', () {
    testWidgets('audio playlist play and shuffle actions use music playback', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

      final tracks = [
        testMediaItem(
          id: 'track-1',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.track,
          title: 'Track One',
          serverId: 'srv-1',
        ),
        testMediaItem(
          id: 'track-2',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.track,
          title: 'Track Two',
          serverId: 'srv-1',
        ),
      ];
      final client = _AudioPlaylistClient(tracks);
      final music = _RecordingMusicPlaybackService();
      final manager = MultiServerManager()..debugRegisterClientForTesting(client);
      final multiServerProvider = testMultiServerProvider(manager);
      final stack = await ProfileStack.create(withStorage: false);
      addTearDown(() async {
        await stack.dispose();
        music.dispose();
        multiServerProvider.dispose();
        manager.dispose();
      });

      final menuKey = GlobalKey<MediaContextMenuState>();
      const playlist = MediaPlaylist(
        id: 'playlist-1',
        backend: MediaBackend.jellyfin,
        title: 'Road Trip',
        playlistType: 'audio',
        serverId: 'srv-1',
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
              ChangeNotifierProvider<MusicPlaybackService>.value(value: music),
            ],
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(
                body: Center(
                  child: MediaContextMenu(
                    key: menuKey,
                    item: playlist,
                    child: const SizedBox(width: 120, height: 80, child: Text('audio target')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      menuKey.currentState!.showContextMenu(tester.element(find.text('audio target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.play));
      await tester.pumpAndSettle();

      expect(music.playedTracks, tracks);
      expect(music.playedContext?.title, playlist.title);
      expect(music.playedContext?.kind, MusicPlayContextKind.playlist);
      expect(music.shuffle, isFalse);

      menuKey.currentState!.showContextMenu(tester.element(find.text('audio target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.mediaMenu.shufflePlay));
      await tester.pumpAndSettle();

      expect(music.callCount, 2);
      expect(music.playedTracks, tracks);
      expect(music.shuffle, isTrue);

      final staleFetchGate = Completer<void>();
      client.fetchGate = staleFetchGate;
      menuKey.currentState!.showContextMenu(tester.element(find.text('audio target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.play));
      await tester.pump();

      final newerTrack = testMediaItem(
        id: 'newer-track',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Newer Track',
        serverId: 'srv-1',
      );
      await music.playFromList(
        tracks: [newerTrack],
        playContext: const MusicPlayContext(title: 'Newer Queue', kind: MusicPlayContextKind.tracks),
      );
      staleFetchGate.complete();
      await tester.pumpAndSettle();

      expect(music.callCount, 3, reason: 'the stale playlist fetch must not start a fourth queue');
      expect(music.playedTracks, [newerTrack]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Jellyfin video playlist context Play exposes cancellable loading', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

      final client = _AudioPlaylistClient([
        testMediaItem(
          id: 'movie-1',
          backend: MediaBackend.jellyfin,
          kind: MediaKind.movie,
          title: 'Movie',
          serverId: 'srv-1',
        ),
      ])..blockWithAbort = true;
      final playback = PlaybackStateProvider();
      final manager = MultiServerManager()..debugRegisterClientForTesting(client);
      final multiServerProvider = testMultiServerProvider(manager);
      final stack = await ProfileStack.create(withStorage: false);
      addTearDown(() async {
        playback.dispose();
        await stack.dispose();
        multiServerProvider.dispose();
        manager.dispose();
      });

      final menuKey = GlobalKey<MediaContextMenuState>();
      const playlist = MediaPlaylist(
        id: 'playlist-video',
        backend: MediaBackend.jellyfin,
        title: 'Video Playlist',
        playlistType: 'video',
        serverId: 'srv-1',
      );
      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
              ChangeNotifierProvider<PlaybackStateProvider>.value(value: playback),
            ],
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(
                body: Center(
                  child: MediaContextMenu(
                    key: menuKey,
                    item: playlist,
                    child: const SizedBox(width: 120, height: 80, child: Text('video target')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      menuKey.currentState!.showContextMenu(tester.element(find.text('video target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.play));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(t.common.cancel), findsOneWidget);
      expect(client.activeAbort, isNotNull);
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(client.activeAbort!.isAborted, isTrue);
      expect(playback.isQueueActive, isFalse);
      expect(find.text('video target'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('file info client resolution failure shows an error without popping another route', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

      final manager = MultiServerManager();
      final multiServerProvider = testMultiServerProvider(manager);
      final stack = await ProfileStack.create(withStorage: false);
      addTearDown(() async {
        await stack.dispose();
        multiServerProvider.dispose();
        manager.dispose();
      });

      final menuKey = GlobalKey<MediaContextMenuState>();
      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: 'missing-server',
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
            ],
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(
                body: Center(
                  child: MediaContextMenu(
                    key: menuKey,
                    item: item,
                    child: const SizedBox(width: 120, height: 80, child: Text('target')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      menuKey.currentState!.showContextMenu(tester.element(find.text('target')));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.mediaMenu.fileInfo));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('target'), findsOneWidget);
    });

    testWidgets('file info spinner is dismissed when the launching card unmounts mid-fetch', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      TvDetectionService.debugSetAppleTVOverride(true);
      addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

      // Gate the item detail fetch so the launching card can be unmounted
      // while getFileInfo is still pending.
      final gate = Completer<void>();
      final client = JellyfinClient.forTesting(
        connection: testJellyfinConnection(isAdministrator: false),
        httpClient: MockClient((request) async {
          if (request.url.queryParameters['Fields'] == 'CanDelete') {
            return _canDeleteResponse(request.url.queryParameters['ids'] ?? '', false);
          }
          await gate.future;
          return jsonResponse({'Id': 'movie-1', 'Name': 'Movie', 'Type': 'Movie'});
        }),
      );
      final manager = MultiServerManager()..debugRegisterJellyfinClientForTesting(client, online: true);
      final multiServerProvider = testMultiServerProvider(manager);
      final offlineMode = OfflineModeProvider(manager);
      final stack = await ProfileStack.create(withStorage: false);
      final showCard = ValueNotifier<bool>(true);
      addTearDown(() async {
        await stack.dispose();
        offlineMode.dispose();
        multiServerProvider.dispose();
        manager.dispose();
        showCard.dispose();
      });

      final menuKey = GlobalKey<MediaContextMenuState>();
      final navigatorKey = GlobalKey<NavigatorState>();
      final item = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        title: 'Movie',
        serverId: 'srv-1',
      );

      await tester.pumpWidget(
        TranslationProvider(
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
              ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
              ChangeNotifierProvider<OfflineModeProvider>.value(value: offlineMode),
            ],
            child: MaterialApp(
              navigatorKey: navigatorKey,
              theme: monoTheme(dark: true),
              home: Scaffold(
                body: Center(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: showCard,
                    builder: (context, visible, child) => visible
                        ? MediaContextMenu(
                            key: menuKey,
                            item: item,
                            child: const SizedBox(width: 120, height: 80, child: Text('file info target')),
                          )
                        : const SizedBox(width: 120, height: 80),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      menuKey.currentState!.showContextMenu(tester.element(find.text('file info target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.mediaMenu.fileInfo));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Unmount the launching card while the fetch is pending — a list refresh
      // dropping the row. The captured card context going stale is exactly what
      // defeated the old `Navigator.pop(context)` cleanup.
      showCard.value = false;
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'the fetch is still pending');

      gate.complete();
      await tester.pumpAndSettle();

      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'the finally must dismiss the spinner through the dialog route, not the dead card context',
      );
      expect(find.byType(FileInfoBottomSheet), findsNothing);
      expect(navigatorKey.currentState!.canPop(), isFalse, reason: 'no modal route may remain stuck above the screen');
      expect(tester.takeException(), isNull);
    });

    testWidgets('playlist picker filters playlists by title', (tester) async {
      final playlists = [
        for (var i = 0; i < 10; i++) (id: '$i', title: 'Alpha $i'),
        (id: 'gamma', title: 'Gamma Nights'),
      ];
      final menuKey = await _pumpPlexMovieMenu(tester, playlists);

      await _openPlaylistPicker(tester, menuKey);
      final textField = tester.widget<TextField>(find.byType(TextField));
      textField.controller!.text = 'gamma';
      textField.onChanged!('gamma');
      await tester.pumpAndSettle();

      expect(find.text('Gamma Nights'), findsOneWidget);
      expect(find.text('Alpha 0'), findsNothing);
      expect(find.text(t.common.createNew), findsOneWidget);
    });

    testWidgets('playlist picker wires TV focus, D-pad down, and back', (tester) async {
      final playlists = [for (var i = 0; i < 10; i++) (id: '$i', title: 'Playlist $i')];
      final menuKey = await _pumpPlexMovieMenu(tester, playlists);

      await _openPlaylistPicker(tester, menuKey);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode!.hasFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(Focus.of(tester.element(find.text(t.common.createNew))).hasFocus, isTrue);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text(t.playlists.selectPlaylist), findsNothing);
      expect(find.text('picker target'), findsOneWidget);
    });

    testWidgets('the music menu gives Instant Mix an icon it shares with no sibling row', (tester) async {
      final track = testMediaItem(
        id: 'track-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Track',
        parentId: 'album-1',
        parentTitle: 'Album',
        grandparentId: 'artist-1',
        grandparentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: track, relatedItems: const []);

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('mini-player menu target')));
      await tester.pumpAndSettle();

      expect(find.text(t.music.instantMix), findsOneWidget);
      expect(find.byIcon(Symbols.wand_stars_rounded), findsOneWidget);

      // #1629: the fader glyph reads as an equalizer, and the neighbouring
      // rows must stay tellable apart at a glance on a TV.
      expect(find.byIcon(Symbols.instant_mix_rounded), findsNothing);
      expect(find.byIcon(Symbols.tune_rounded), findsNothing);
      final musicIcons = tester
          .widgetList<Icon>(find.byType(Icon))
          .map((icon) => icon.icon)
          .whereType<IconData>()
          .toList();
      expect(
        musicIcons.where((icon) => icon == Symbols.wand_stars_rounded),
        hasLength(1),
        reason: 'Instant Mix must not reuse the glyph of Play, Play next, Add to queue, or Go to artist',
      );
    });

    testWidgets('track album action uses the profile navigator from the sibling menu overlay', (tester) async {
      final track = testMediaItem(
        id: 'track-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Track',
        parentId: 'album-1',
        parentTitle: 'Album',
        grandparentId: 'artist-1',
        grandparentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.album,
        title: 'Album',
        parentId: 'artist-1',
        parentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: track, relatedItems: [album]);

      await _selectSiblingMusicMenuAction(tester, harness, t.music.goToAlbum);

      expect(find.byType(AlbumDetailScreen), findsOneWidget);
      expect(harness.profileNavigatorKey.currentState!.canPop(), isTrue);
      expect(harness.rootNavigatorKey.currentState!.canPop(), isFalse);
      expect(
        Provider.of<MusicPlaybackService>(tester.element(find.byType(AlbumDetailScreen)), listen: false),
        same(harness.music),
      );
    });

    testWidgets('album artist action uses the profile navigator from the sibling menu overlay', (tester) async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.album,
        title: 'Album',
        parentId: 'artist-1',
        parentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final artist = testMediaItem(
        id: 'artist-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.artist,
        title: 'Artist',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: album, relatedItems: [artist]);

      await _selectSiblingMusicMenuAction(tester, harness, t.music.goToArtist);

      expect(find.byType(ArtistDetailScreen), findsOneWidget);
      expect(harness.profileNavigatorKey.currentState!.canPop(), isTrue);
      expect(harness.rootNavigatorKey.currentState!.canPop(), isFalse);
      expect(
        Provider.of<MusicPlaybackService>(tester.element(find.byType(ArtistDetailScreen)), listen: false),
        same(harness.music),
      );
    });

    testWidgets('track artist action uses the profile navigator from the sibling menu overlay', (tester) async {
      final track = testMediaItem(
        id: 'track-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Track',
        parentId: 'album-1',
        parentTitle: 'Album',
        grandparentId: 'artist-1',
        grandparentTitle: 'Artist',
        serverId: 'srv-1',
      );
      final artist = testMediaItem(
        id: 'artist-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.artist,
        title: 'Artist',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: track, relatedItems: [artist]);

      await _selectSiblingMusicMenuAction(tester, harness, t.music.goToArtist);

      expect(find.byType(ArtistDetailScreen), findsOneWidget);
      expect(harness.profileNavigatorKey.currentState!.canPop(), isTrue);
      expect(harness.rootNavigatorKey.currentState!.canPop(), isFalse);
      expect(
        Provider.of<MusicPlaybackService>(tester.element(find.byType(ArtistDetailScreen)), listen: false),
        same(harness.music),
      );
    });

    testWidgets('a slow music enqueue does not append to a newer queue session', (tester) async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.album,
        title: 'Album',
        serverId: 'srv-1',
      );
      final albumTrack = testMediaItem(
        id: 'album-track',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Album Track',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: album, relatedItems: [albumTrack]);
      final fetchGate = Completer<void>();
      harness.client.albumTracksGate = fetchGate;

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('mini-player menu target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.music.playNext));
      await tester.pump();

      final newerTrack = testMediaItem(
        id: 'newer-track',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Newer Track',
        serverId: 'srv-1',
      );
      await harness.music.playFromList(
        tracks: [newerTrack],
        playContext: const MusicPlayContext(title: 'Newer Queue', kind: MusicPlayContextKind.tracks),
      );
      fetchGate.complete();
      await tester.pumpAndSettle();

      expect(harness.music.addedNext, isEmpty);
      expect(harness.music.playedTracks, [newerTrack]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('track file info fetches the tapped track and renders its audio-only sheet', (tester) async {
      const trackPath = '/music/Boards of Canada/Geogaddi/01 Ready Lets Go.flac';
      final track = testMediaItem(
        id: 'track-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.track,
        title: 'Ready Lets Go',
        parentId: 'album-1',
        parentTitle: 'Geogaddi',
        grandparentId: 'artist-1',
        grandparentTitle: 'Boards of Canada',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: track, relatedItems: const []);
      harness.client.fileInfo = const MediaFileInfo(
        versions: [
          MediaFileVersion(
            container: 'flac',
            parts: [
              MediaFilePart(
                filePath: trackPath,
                fileSize: 35651584,
                streams: [MediaStreamDetails(kind: MediaStreamKind.audio, ordinal: 1, codec: 'flac', channels: 2)],
              ),
            ],
          ),
        ],
      );

      await _selectSiblingMusicMenuAction(tester, harness, t.mediaMenu.fileInfo);

      expect(harness.client.fileInfoRequests, [same(track)]);
      expect(find.byType(FileInfoBottomSheet), findsOneWidget);
      expect(find.text('Ready Lets Go'), findsOneWidget);
      expect(find.text(trackPath), findsOneWidget);
      expect(find.text(t.fileInfo.audio), findsOneWidget);
      expect(find.text(t.fileInfo.video), findsNothing);
      // The loading dialog must be gone and no error snackbar raised.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('album menu omits file info because containers carry no media sources', (tester) async {
      final album = testMediaItem(
        id: 'album-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.album,
        title: 'Geogaddi',
        parentId: 'artist-1',
        parentTitle: 'Boards of Canada',
        serverId: 'srv-1',
      );
      final harness = await _pumpSiblingMusicMenu(tester, item: album, relatedItems: const []);

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('mini-player menu target')));
      await tester.pumpAndSettle();

      expect(find.text(t.music.playNext), findsOneWidget);
      expect(find.text(t.mediaMenu.fileInfo), findsNothing);
      expect(harness.client.fileInfoRequests, isEmpty);
    });
  });

  group('watchlist entry', () {
    testWidgets('cold open offers Add and adds to the single capable source', (tester) async {
      final source = _MenuWatchlistSource(CatalogSourceId.trakt, 'Trakt', resolveTo: const CatalogItemIds(imdb: 'tt1'));
      final harness = await _pumpWatchlistMenu(tester, sources: [source], guids: ['imdb://tt1']);

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('watchlist target')));
      await tester.pumpAndSettle();

      expect(find.text(t.explore.addToWatchlist), findsOneWidget);
      expect(find.text(t.explore.removeFromWatchlist), findsNothing);

      await tester.tap(find.text(t.explore.addToWatchlist));
      await tester.pumpAndSettle();

      expect(source.mutations.map((m) => m.add), [true]);
      expect(source.mutations.single.ids.imdb, 'tt1');
      expect(find.text(t.explore.addedToWatchlist), findsOneWidget);
      // Opening also kicked the membership snapshot load for the next open.
      expect(source.ensureLoadedCalls, greaterThan(0));
    });

    testWidgets('offers Remove once cached membership is known, and removes', (tester) async {
      final source = _MenuWatchlistSource(CatalogSourceId.trakt, 'Trakt', resolveTo: const CatalogItemIds(imdb: 'tt1'))
        ..membership = true;
      final harness = await _pumpWatchlistMenu(tester, sources: [source]);
      await harness.catalogSources.watchlistCandidatesFor(
        harness.item,
        client: _SeedIdsClient(const ExternalIds(imdb: 'tt1')),
      );

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('watchlist target')));
      await tester.pumpAndSettle();

      expect(find.text(t.explore.removeFromWatchlist), findsOneWidget);

      await tester.tap(find.text(t.explore.removeFromWatchlist));
      await tester.pumpAndSettle();

      expect(source.mutations.map((m) => m.add), [false]);
      expect(find.text(t.explore.removedFromWatchlist), findsOneWidget);
    });

    testWidgets('hides the entry when the item resolved in no capable source', (tester) async {
      final source = _MenuWatchlistSource(CatalogSourceId.mal, 'MAL'); // resolves null: out of domain
      final harness = await _pumpWatchlistMenu(tester, sources: [source]);
      await harness.catalogSources.watchlistCandidatesFor(
        harness.item,
        client: _SeedIdsClient(const ExternalIds(imdb: 'tt1')),
      );

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('watchlist target')));
      await tester.pumpAndSettle();

      expect(find.text(t.mediaMenu.markAsWatched), findsOneWidget);
      expect(find.text(t.explore.addToWatchlist), findsNothing);
      expect(find.text(t.explore.removeFromWatchlist), findsNothing);
    });

    testWidgets('reports when the tapped item matches no watchlist', (tester) async {
      final source = _MenuWatchlistSource(CatalogSourceId.trakt, 'Trakt', resolveTo: const CatalogItemIds(imdb: 'tt1'));
      // The metadata answer carries no Guid entries: no external ids.
      final harness = await _pumpWatchlistMenu(tester, sources: [source]);

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('watchlist target')));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.explore.addToWatchlist));
      await tester.pumpAndSettle();

      expect(source.mutations, isEmpty);
      expect(find.text(t.explore.watchlistNoMatch), findsOneWidget);
    });

    testWidgets('several capable sources open a per-source chooser', (tester) async {
      final trakt = _MenuWatchlistSource(CatalogSourceId.trakt, 'Trakt', resolveTo: const CatalogItemIds(imdb: 'tt1'));
      final simkl = _MenuWatchlistSource(CatalogSourceId.simkl, 'Simkl', resolveTo: const CatalogItemIds(imdb: 'tt1'))
        ..membership = true;
      final harness = await _pumpWatchlistMenu(tester, sources: [trakt, simkl]);
      await harness.catalogSources.watchlistCandidatesFor(
        harness.item,
        client: _SeedIdsClient(const ExternalIds(imdb: 'tt1')),
      );

      harness.menuKey.currentState!.showContextMenu(tester.element(find.text('watchlist target')));
      await tester.pumpAndSettle();

      // Membership known-true on one source labels the entry Remove.
      await tester.tap(find.text(t.explore.removeFromWatchlist));
      await tester.pumpAndSettle();

      // The chooser names each source with its own pending action.
      expect(find.text('Trakt'), findsOneWidget);
      expect(find.text('Simkl'), findsOneWidget);
      expect(find.text(t.explore.addToWatchlist), findsOneWidget);
      expect(find.text(t.explore.removeFromWatchlist), findsOneWidget);

      await tester.tap(find.text('Simkl'));
      await tester.pumpAndSettle();

      expect(simkl.mutations.map((m) => m.add), [false]);
      expect(trakt.mutations, isEmpty);
      expect(find.text(t.explore.removedFromWatchlist), findsOneWidget);
    });
  });
}

Future<GlobalKey<MediaContextMenuState>> _pumpPlexMovieMenu(
  WidgetTester tester,
  List<({String id, String title})> playlists,
) async {
  LocaleSettings.setLocaleSync(AppLocale.en);
  TvDetectionService.debugSetAppleTVOverride(true);
  addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  final client = testPlexClient(
    config: PlexConfig(
      baseUrl: 'https://plex.example.com',
      token: 'token',
      clientIdentifier: 'client-id',
      product: 'Plezy',
      version: '1',
    ),
    serverId: ServerId('plex-1'),
    httpClient: MockClient((request) async {
      if (request.url.path != '/playlists') return http.Response('not found', 404);
      return http.Response(
        jsonEncode({
          'MediaContainer': {
            'size': playlists.length,
            'totalSize': playlists.length,
            'Metadata': [
              for (final playlist in playlists)
                {
                  'ratingKey': playlist.id,
                  'key': '/playlists/${playlist.id}/items',
                  'type': 'playlist',
                  'playlistType': 'video',
                  'title': playlist.title,
                  'smart': false,
                },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = testMultiServerProvider(manager);
  final stack = await ProfileStack.create(db: db, withStorage: false);
  addTearDown(() async {
    await stack.dispose();
    multiServerProvider.dispose();
    manager.dispose();
    await db.close();
  });

  final menuKey = GlobalKey<MediaContextMenuState>();
  final item = testMediaItem(
    id: 'movie-1',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    title: 'Movie',
    serverId: 'plex-1',
  );
  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: Center(
              child: MediaContextMenu(
                key: menuKey,
                item: item,
                child: const SizedBox(width: 120, height: 80, child: Text('picker target')),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return menuKey;
}

/// Jellyfin answer for the per-item delete-permission probe.
http.Response _canDeleteResponse(String id, bool canDelete) => jsonResponse({
  'Items': [
    {'Id': id, 'CanDelete': canDelete},
  ],
});

/// A user holding `EnableContentDeletionFromFolders` for one library only: the
/// server answers per item, which is the only way that grant reaches a client.
Future<http.Response> _libraryGrantedToOneMovie(http.Request request) async {
  final id = request.url.queryParameters['ids'] ?? '';
  return _canDeleteResponse(id, id == 'movie-in-grant');
}

/// Jellyfin episode fixture. [file] populates the inline media source so the
/// impact probe resolves without a detail refetch; pass [versions] instead to
/// model a split or path-less item.
MediaItem _episode({required String id, required int index, String? file, List<MediaVersion>? versions}) {
  return testMediaItem(
    id: id,
    backend: MediaBackend.jellyfin,
    kind: MediaKind.episode,
    title: 'Cat in the Bag',
    parentId: 'season-1',
    parentIndex: 1,
    index: index,
    grandparentId: 'show-1',
    grandparentTitle: 'Breaking Bad',
    serverId: 'srv-1',
    mediaVersions:
        versions ??
        [
          MediaVersion(
            id: 'v-$id',
            parts: [MediaPart(id: 'p-$id', file: file)],
          ),
        ],
  );
}

Map<String, Object?> _episodeJson({required String id, required int index, required String? path}) => {
  'Id': id,
  'Name': 'Episode $index',
  'Type': 'Episode',
  'IndexNumber': index,
  'ParentIndexNumber': 1,
  'SeriesId': 'show-1',
  'SeriesName': 'Breaking Bad',
  'SeasonId': 'season-1',
  'MediaSources': [
    {'Id': 'ms-$id', 'Path': ?path},
  ],
};

/// Answers every request the delete flow makes: the CanDelete probe, the
/// season-children lookup, per-item detail refetches, and the DELETE itself.
///
/// A null [episodes] makes the children lookup fail, which is the
/// probe-failure path. [details] is keyed by item id and models the detail
/// endpoint carrying file paths that the browse row omitted.
Future<http.Response> Function(http.Request) _deleteFlowHandler({
  required List<Map<String, Object?>>? episodes,
  Map<String, Map<String, Object?>> details = const {},
  void Function(String id)? onDelete,
}) {
  return (request) async {
    final path = request.url.path;
    final lastSegment = path.split('/').last;
    if (request.method == 'DELETE') {
      onDelete?.call(lastSegment);
      return http.Response('', 204);
    }
    if (request.url.queryParameters['Fields'] == 'CanDelete') {
      return _canDeleteResponse(request.url.queryParameters['ids'] ?? '', true);
    }
    // fetchChildren probes /Shows/{id}/Seasons first and falls through to the
    // generic ParentId query when it comes back empty.
    if (path.contains('/Seasons')) return jsonResponse({'Items': <Object?>[]});
    if (request.url.queryParameters.containsKey('ParentId')) {
      if (episodes == null) return http.Response('boom', 500);
      return jsonResponse({'Items': episodes, 'TotalRecordCount': episodes.length});
    }
    final detail = details[lastSegment];
    if (detail != null) return jsonResponse(detail);
    return jsonResponse({'Items': <Object?>[]});
  };
}

Future<void> _confirmDelete(WidgetTester tester, GlobalKey<MediaContextMenuState> menuKey, String confirmLabel) async {
  await _openMenu(tester, menuKey);
  await tester.tap(find.text(t.mediaMenu.deleteEpisodeFromServer));
  await tester.pumpAndSettle();
  await tester.tap(find.text(confirmLabel));
  await tester.pumpAndSettle();
}

Future<GlobalKey<MediaContextMenuState>> _pumpJellyfinMovieMenu(
  WidgetTester tester, {
  required bool isAdministrator,
  required Future<http.Response> Function(http.Request request) handler,
  String itemId = 'movie-1',
  bool serverOnline = true,
  List<Uri>? requests,
}) {
  return _pumpJellyfinItemMenu(
    tester,
    isAdministrator: isAdministrator,
    handler: handler,
    serverOnline: serverOnline,
    requests: requests,
    item: testMediaItem(
      id: itemId,
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      title: 'Movie',
      serverId: 'srv-1',
    ),
  );
}

Future<GlobalKey<MediaContextMenuState>> _pumpJellyfinItemMenu(
  WidgetTester tester, {
  required bool isAdministrator,
  required Future<http.Response> Function(http.Request request) handler,
  required MediaItem item,
  bool serverOnline = true,
  List<Uri>? requests,

  /// Push the menu onto a route above a home screen, so the navigator has
  /// something below the menu that a stray pop could reach.
  bool onPushedRoute = false,
}) async {
  LocaleSettings.setLocaleSync(AppLocale.en);
  TvDetectionService.debugSetAppleTVOverride(true);
  addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  final client = JellyfinClient.forTesting(
    connection: testJellyfinConnection(isAdministrator: isAdministrator),
    httpClient: MockClient((request) async {
      requests?.add(request.url);
      return handler(request);
    }),
  );
  final manager = MultiServerManager()..debugRegisterJellyfinClientForTesting(client, online: serverOnline);
  final multiServerProvider = testMultiServerProvider(manager);
  final offlineMode = OfflineModeProvider(manager);
  final stack = await ProfileStack.create(withStorage: false);
  addTearDown(() async {
    await stack.dispose();
    offlineMode.dispose();
    multiServerProvider.dispose();
    manager.dispose();
  });

  final menuKey = GlobalKey<MediaContextMenuState>();
  final navigatorKey = GlobalKey<NavigatorState>();
  final menuScreen = Scaffold(
    body: Center(
      child: MediaContextMenu(
        key: menuKey,
        item: item,
        child: const SizedBox(width: 120, height: 80, child: Text('delete target')),
      ),
    ),
  );
  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
          ChangeNotifierProvider<OfflineModeProvider>.value(value: offlineMode),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: monoTheme(dark: true),
          home: onPushedRoute ? const Scaffold(body: Center(child: Text('home screen'))) : menuScreen,
        ),
      ),
    ),
  );
  if (onPushedRoute) {
    unawaited(navigatorKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => menuScreen)));
    await tester.pumpAndSettle();
  }
  return menuKey;
}

Future<void> _openMenu(WidgetTester tester, GlobalKey<MediaContextMenuState> menuKey) async {
  menuKey.currentState!.showContextMenu(tester.element(find.text('delete target')));
  await tester.pumpAndSettle();
}

Future<void> _openPlaylistPicker(WidgetTester tester, GlobalKey<MediaContextMenuState> menuKey) async {
  menuKey.currentState!.showContextMenu(tester.element(find.text('picker target')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.common.addTo));
  await tester.pumpAndSettle();
  await tester.tap(find.text(t.playlists.playlist));
  await tester.pumpAndSettle();
  expect(find.text(t.playlists.selectPlaylist), findsOneWidget);
}

class _AudioPlaylistClient implements MediaServerClient {
  final List<MediaItem> tracks;
  Completer<void>? fetchGate;
  bool blockWithAbort = false;
  AbortController? activeAbort;

  _AudioPlaylistClient(this.tracks);

  @override
  ServerId get serverId => ServerId('srv-1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort}) async {
    if (blockWithAbort) {
      activeAbort = abort;
      if (abort == null) {
        await Completer<void>().future;
      } else {
        await abort.trigger;
        abort.throwIfAborted();
      }
    }
    await fetchGate?.future;
    return fakeLibraryPage(tracks, start: start, size: size);
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingMusicPlaybackService extends StubMusicPlaybackService {
  List<MediaItem>? playedTracks;
  final List<MediaItem> addedNext = [];
  MusicPlayContext? playedContext;
  bool? shuffle;
  int callCount = 0;

  @override
  Future<void> playFromList({
    required List<MediaItem> tracks,
    MediaItem? startTrack,
    required MusicPlayContext playContext,
    bool shuffle = false,
  }) async {
    await super.playFromList(tracks: tracks, startTrack: startTrack, playContext: playContext, shuffle: shuffle);
    callCount++;
    playedTracks = tracks;
    playedContext = playContext;
    this.shuffle = shuffle;
  }

  @override
  void addNext(List<MediaItem> tracks) {
    addedNext.addAll(tracks);
  }
}

class _RelatedMusicClient implements MediaServerClient {
  _RelatedMusicClient(Iterable<MediaItem> items)
    : _items = {for (final item in items) item.id: item},
      albumTracks = items.where((item) => item.kind == MediaKind.track).toList();

  final Map<String, MediaItem> _items;
  final List<MediaItem> albumTracks;
  Completer<void>? albumTracksGate;

  @override
  ServerId get serverId => ServerId('srv-1');

  @override
  String? get serverName => 'Server';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.jellyfin;

  @override
  Future<MediaItem?> fetchItem(String id) async => _items[id];

  @override
  Future<List<MediaItem>> fetchAlbumTracks(String albumId) async {
    await albumTracksGate?.future;
    return albumTracks;
  }

  @override
  Future<List<MediaItem>> fetchArtistAlbums(MediaItem artist) async => const [];

  /// Items the menu asked file info for, in call order — the track menu must
  /// resolve the client for the tapped item, not for whatever is playing.
  final List<MediaItem> fileInfoRequests = [];
  MediaFileInfo? fileInfo;

  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) async {
    fileInfoRequests.add(item);
    return fileInfo;
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SiblingMusicMenuHarness {
  const _SiblingMusicMenuHarness({
    required this.rootNavigatorKey,
    required this.profileNavigatorKey,
    required this.menuKey,
    required this.music,
    required this.client,
  });

  final GlobalKey<NavigatorState> rootNavigatorKey;
  final GlobalKey<NavigatorState> profileNavigatorKey;
  final GlobalKey<MediaContextMenuState> menuKey;
  final _RecordingMusicPlaybackService music;
  final _RelatedMusicClient client;
}

Future<_SiblingMusicMenuHarness> _pumpSiblingMusicMenu(
  WidgetTester tester, {
  required MediaItem item,
  required List<MediaItem> relatedItems,
}) async {
  resetSharedPreferencesForTest();
  SettingsService.resetForTesting();
  await SettingsService.getInstance();
  LocaleSettings.setLocaleSync(AppLocale.en);

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  JellyfinApiCache.initialize(db);
  final downloadManager = DownloadManagerService(
    database: db,
    storageService: DownloadStorageService.instance,
    clientResolver: (serverId, {clientScopeId}) => null,
  );
  downloadManager.recoveryFuture = Future<void>.value();
  final downloadProvider = DownloadProvider.forTesting(downloadManager: downloadManager, database: db);
  await downloadProvider.ensureInitialized();
  final client = _RelatedMusicClient(relatedItems);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = testMultiServerProvider(manager);
  final stack = await ProfileStack.create(db: db, withStorage: false);
  final music = _RecordingMusicPlaybackService();
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final profileNavigatorKey = GlobalKey<NavigatorState>();
  final menuKey = GlobalKey<MediaContextMenuState>();

  addTearDown(() async {
    downloadProvider.dispose();
    downloadManager.dispose();
    await stack.dispose();
    music.dispose();
    multiServerProvider.dispose();
    manager.dispose();
    await db.close();
  });

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.macOS),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
            ChangeNotifierProvider<DownloadProvider>.value(value: downloadProvider),
            ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
            ChangeNotifierProvider<MusicPlaybackService>.value(value: music),
          ],
          child: ProfileNavigationScope(
            navigatorKey: profileNavigatorKey,
            routeObserver: RouteObserver<PageRoute<dynamic>>(),
            mainScaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Navigator(
                  key: profileNavigatorKey,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Center(child: Text('profile content'))),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    child: MediaContextMenu(
                      key: menuKey,
                      item: item,
                      child: const SizedBox(
                        width: 180,
                        height: 64,
                        child: Center(child: Text('mini-player menu target')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  return _SiblingMusicMenuHarness(
    rootNavigatorKey: rootNavigatorKey,
    profileNavigatorKey: profileNavigatorKey,
    menuKey: menuKey,
    music: music,
    client: client,
  );
}

Future<void> _selectSiblingMusicMenuAction(
  WidgetTester tester,
  _SiblingMusicMenuHarness harness,
  String actionLabel,
) async {
  harness.menuKey.currentState!.showContextMenu(tester.element(find.text('mini-player menu target')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabel));
  await tester.pumpAndSettle();
}

PlexHomeUser _homeUser({required bool admin}) {
  return PlexHomeUser(
    id: 0,
    uuid: 'home-user',
    title: 'Home User',
    username: null,
    email: null,
    friendlyName: null,
    thumb: 'https://plex.tv/users/home-user/avatar',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: admin,
    guest: false,
    protected: false,
  );
}

JellyfinConnection _jellyfinConnection() {
  return JellyfinConnection(
    id: 'srv-1/user-1',
    baseUrl: 'https://jf.example.com',
    serverName: 'Home',
    serverMachineId: 'srv-1',
    userId: 'user-1',
    userName: 'edde',
    accessToken: 'tok',
    deviceId: 'dev',
    isAdministrator: true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class _MenuWatchlistSource implements CatalogSource {
  _MenuWatchlistSource(this.id, this.displayName, {this.resolveTo});

  @override
  final CatalogSourceId id;

  @override
  final String displayName;

  final CatalogItemIds? resolveTo;
  bool? membership;
  int ensureLoadedCalls = 0;
  final List<({MediaKind kind, CatalogItemIds ids, bool add})> mutations = [];

  @override
  bool get supportsWatchlist => true;

  @override
  Future<void> ensureWatchlistLoaded() async {
    ensureLoadedCalls++;
  }

  @override
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) => membership;

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async => resolveTo;

  @override
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) async =>
      mutations.add((kind: kind, ids: ids, add: true));

  @override
  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) async =>
      mutations.add((kind: kind, ids: ids, add: false));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WatchlistSourcesProvider extends CatalogSourcesProvider {
  _WatchlistSourcesProvider(this.sources);

  final List<CatalogSource> sources;

  @override
  List<CatalogSource> get connectedSources => sources;
}

class _SeedIdsClient implements MediaServerClient {
  _SeedIdsClient(this.ids);

  final ExternalIds ids;

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async => ids;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pumps a Plex movie's context menu with [sources] connected as catalog
/// sources. The Plex MockClient answers the external-id metadata fetch with
/// [guids] (empty: the item carries no external ids).
Future<({GlobalKey<MediaContextMenuState> menuKey, MediaItem item, CatalogSourcesProvider catalogSources})>
_pumpWatchlistMenu(WidgetTester tester, {required List<CatalogSource> sources, List<String> guids = const []}) async {
  LocaleSettings.setLocaleSync(AppLocale.en);
  TvDetectionService.debugSetAppleTVOverride(true);
  addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  final client = testPlexClient(
    serverId: ServerId('plex-1'),
    httpClient: MockClient((request) async {
      if (request.url.path == '/library/metadata/movie-1') {
        return jsonResponse({
          'MediaContainer': {
            'Metadata': [
              {
                'ratingKey': 'movie-1',
                'type': 'movie',
                'title': 'Movie',
                if (guids.isNotEmpty)
                  'Guid': [
                    for (final guid in guids) {'id': guid},
                  ],
              },
            ],
          },
        });
      }
      return http.Response('not found', 404);
    }),
  );
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final multiServerProvider = testMultiServerProvider(manager);
  final offlineMode = OfflineModeProvider(manager);
  final catalogSources = _WatchlistSourcesProvider(sources);
  final stack = await ProfileStack.create(db: db, withStorage: false);
  addTearDown(() async {
    await stack.dispose();
    catalogSources.dispose();
    offlineMode.dispose();
    multiServerProvider.dispose();
    manager.dispose();
    await db.close();
  });

  final menuKey = GlobalKey<MediaContextMenuState>();
  final item = testMediaItem(id: 'movie-1', kind: MediaKind.movie, title: 'Movie', serverId: 'plex-1');
  await tester.pumpWidget(
    TranslationProvider(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MultiServerProvider>.value(value: multiServerProvider),
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: stack.active),
          ChangeNotifierProvider<OfflineModeProvider>.value(value: offlineMode),
          ChangeNotifierProvider<CatalogSourcesProvider>.value(value: catalogSources),
        ],
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Scaffold(
            body: Center(
              child: MediaContextMenu(
                key: menuKey,
                item: item,
                child: const SizedBox(width: 120, height: 80, child: Text('watchlist target')),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return (menuKey: menuKey, item: item, catalogSources: catalogSources);
}
