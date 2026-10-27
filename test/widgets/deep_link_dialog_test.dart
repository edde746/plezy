import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/services/deep_links/deep_link.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/deep_link_dialog.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../test_helpers/media_items.dart';

/// Answers only the external-id lookup. [gate] holds the answer back so a
/// test can look at the dialog while the link is resolving.
class _ExternalIdsClient implements MediaServerClient {
  _ExternalIdsClient({this.ids = const ExternalIds(), this.error, this.gate});

  final ExternalIds ids;
  final Exception? error;
  final Completer<void>? gate;
  final List<String> calls = [];

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    calls.add(itemId);
    await gate?.future;
    if (error case final error?) throw error;
    return ids;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The profile set [showItemLinkDialog] reads: who is active and how many
/// profiles there are.
class _Profiles extends ChangeNotifier implements ActiveProfileProvider {
  _Profiles(this.profiles) : active = profiles.first;

  @override
  final List<Profile> profiles;

  @override
  final Profile? active;

  @override
  bool get hasMultipleProfiles => profiles.length > 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _movie = testMediaItem(id: 'movie-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'plex-1');
final _show = testMediaItem(id: 'show-1', backend: MediaBackend.plex, kind: MediaKind.show, serverId: 'plex-1');
final _episode = testMediaItem(id: 'ep-1', backend: MediaBackend.plex, kind: MediaKind.episode, serverId: 'plex-1');

final _owner = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026));
final _kid = Profile.plexHome(
  id: 'plex-home-kid',
  displayName: 'Kid',
  plexHomeUserUuid: 'a1b2c3',
  createdAt: DateTime(2026),
);

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  void useViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// A desktop-sized window unless [size] says otherwise.
  Future<void> pumpDialog(WidgetTester tester, Widget dialog, {bool appleTV = false, Size? size}) async {
    useViewport(tester, size ?? const Size(1280, 900));
    TvDetectionService.debugSetAppleTVOverride(appleTV);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: dialog)));
  }

  /// Opens the item dialog the way the context menu does, as [profiles]'
  /// first profile.
  Future<void> openItemDialog(WidgetTester tester, MediaItem item, List<Profile> profiles) async {
    useViewport(tester, const Size(1280, 900));
    TvDetectionService.debugSetAppleTVOverride(false);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    final profileSet = _Profiles(profiles);
    addTearDown(profileSet.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<ActiveProfileProvider>.value(
        value: profileSet,
        child: InputModeTracker(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => unawaited(showItemLinkDialog(context, item)),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('item link', () {
    testWidgets('a show gets its catalogue link and the shuffle hint', (tester) async {
      await pumpDialog(
        tester,
        ItemLinkDialog(
          item: _show,
          client: _ExternalIdsClient(ids: const ExternalIds(tvdb: 81189, tmdb: 1396)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('plezy://play?type=show&tvdb=81189'), findsOneWidget);
      expect(find.text(t.deepLinks.showHint), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('a movie gets its catalogue link and the movie hint', (tester) async {
      await pumpDialog(
        tester,
        ItemLinkDialog(
          item: _movie,
          client: _ExternalIdsClient(ids: const ExternalIds(tmdb: 603, imdb: 'tt0133093')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('plezy://play?type=movie&tmdb=603'), findsOneWidget);
      expect(find.text(t.deepLinks.movieHint), findsOneWidget);
      expect(find.text(t.deepLinks.showHint), findsNothing);
    });

    testWidgets('an episode links to itself on its server without a lookup', (tester) async {
      final client = _ExternalIdsClient(ids: const ExternalIds(tvdb: 81189));
      await pumpDialog(tester, ItemLinkDialog(item: _episode, client: client));
      await tester.pumpAndSettle();

      expect(find.text('plezy://play?server=plex-1&id=ep-1'), findsOneWidget);
      expect(find.text(t.deepLinks.episodeHint), findsOneWidget);
      expect(client.calls, isEmpty);
    });

    testWidgets('shows the server link when the id lookup fails', (tester) async {
      await pumpDialog(
        tester,
        ItemLinkDialog(
          item: _movie,
          client: _ExternalIdsClient(
            ids: const ExternalIds(tmdb: 603),
            error: MediaServerHttpException(type: MediaServerHttpErrorType.connectionError, message: 'unreachable'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('plezy://play?server=plex-1&id=movie-1'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('shows the server link at once when the server has no client', (tester) async {
      await pumpDialog(tester, ItemLinkDialog(item: _movie, client: null));
      await tester.pump();

      expect(find.text('plezy://play?server=plex-1&id=movie-1'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('keeps its size while the link resolves', (tester) async {
      final gate = Completer<void>();
      await pumpDialog(
        tester,
        ItemLinkDialog(
          item: _movie,
          client: _ExternalIdsClient(ids: const ExternalIds(tmdb: 603), gate: gate),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, t.deepLinks.copy)).onPressed, isNull);
      final resolvingSize = tester.getSize(find.byType(AlertDialog));

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('plezy://play?type=movie&tmdb=603'), findsOneWidget);
      expect(tester.getSize(find.byType(AlertDialog)), resolvingSize);
    });

    testWidgets('scales a long link onto one line on a wide screen', (tester) async {
      final longId = testMediaItem(
        id: '1234567890',
        backend: MediaBackend.plex,
        kind: MediaKind.episode,
        serverId: '0123456789abcdef0123456789abcdef01234567',
      );
      await pumpDialog(tester, ItemLinkDialog(item: longId, client: null));
      await tester.pump();

      final link = find.text('plezy://play?server=0123456789abcdef0123456789abcdef01234567&id=1234567890');
      expect(find.ancestor(of: link, matching: find.byType(FittedBox)), findsOneWidget);
    });

    testWidgets('wraps the link on a phone', (tester) async {
      await pumpDialog(tester, ItemLinkDialog(item: _episode, client: null), size: const Size(390, 844));
      await tester.pump();

      final link = find.text('plezy://play?server=plex-1&id=ep-1');
      expect(link, findsOneWidget);
      expect(find.ancestor(of: link, matching: find.byType(FittedBox)), findsNothing);
    });
  });

  group('copy', () {
    testWidgets('Copy puts the link on the clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await pumpDialog(
        tester,
        ItemLinkDialog(
          item: _show,
          client: _ExternalIdsClient(ids: const ExternalIds(tvdb: 81189)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.deepLinks.copy));
      await tester.pumpAndSettle();

      expect(copied, 'plezy://play?type=show&tvdb=81189');
      expect(find.text(t.deepLinks.copied), findsOneWidget);
    });

    testWidgets('hides Copy on Apple TV, which has no clipboard, and still shows the QR code', (tester) async {
      await pumpDialog(tester, ItemLinkDialog(item: _movie, client: null), appleTV: true);
      await tester.pump();

      expect(find.text(t.deepLinks.copy), findsNothing);
      expect(find.text(t.common.close), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });

  group('open as profile', () {
    testWidgets('the switch starts off and appends the profile', (tester) async {
      await pumpDialog(
        tester,
        ItemLinkDialog(
          item: _movie,
          client: _ExternalIdsClient(ids: const ExternalIds(tmdb: 603)),
          profile: _kid,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('plezy://play?type=movie&tmdb=603'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);

      await tester.tap(find.text(t.deepLinks.openAsProfile(name: 'Kid')));
      await tester.pumpAndSettle();

      const withProfile = 'plezy://play?type=movie&tmdb=603&profile=a1b2c3';
      expect(find.text(withProfile), findsOneWidget);
      final parsed = DeepLink.tryParse(withProfile)! as PlayLink;
      expect(parsed.target, const CatalogPlayTarget(kind: MediaKind.movie, ids: ExternalIds(tmdb: 603)));
      expect(resolveLinkProfile([_owner, _kid], parsed.profile!), _kid);

      await tester.tap(find.text(t.deepLinks.openAsProfile(name: 'Kid')));
      await tester.pumpAndSettle();

      expect(find.text('plezy://play?type=movie&tmdb=603'), findsOneWidget);
    });

    testWidgets('appends the profile to a server link too', (tester) async {
      await pumpDialog(tester, ItemLinkDialog(item: _show, client: null, profile: _owner));
      await tester.pump();
      await tester.tap(find.text(t.deepLinks.openAsProfile(name: 'Owner')));
      await tester.pump();

      expect(find.text('plezy://play?server=plex-1&id=show-1&profile=local-owner'), findsOneWidget);
    });

    testWidgets('is not offered with a single profile', (tester) async {
      await openItemDialog(tester, _movie, [_owner]);

      expect(find.byType(ItemLinkDialog), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
    });

    testWidgets('names the active profile when there are several', (tester) async {
      await openItemDialog(tester, _movie, [_kid, _owner]);

      expect(find.text(t.deepLinks.openAsProfile(name: 'Kid')), findsOneWidget);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    });
  });

  group('focus', () {
    testWidgets('Close has focus when the dialog opens', (tester) async {
      await openItemDialog(tester, _movie, [_owner, _kid]);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byType(ItemLinkDialog), findsNothing);
    });

    testWidgets('D-pad up reaches the profile switch and select toggles it', (tester) async {
      await openItemDialog(tester, _movie, [_owner, _kid]);
      final switchTitle = find.text(t.deepLinks.openAsProfile(name: 'Owner'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(Focus.of(tester.element(switchTitle)).hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
      expect(find.text('plezy://play?server=plex-1&id=movie-1&profile=local-owner'), findsOneWidget);
    });
  });

  group('profile link', () {
    testWidgets('a local profile links by its id', (tester) async {
      await pumpDialog(tester, ProfileLinkDialog(profile: _owner));

      const link = 'plezy://open?profile=local-owner';
      expect(find.text(link), findsOneWidget);
      expect(find.text(t.deepLinks.profileHint), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
      final parsed = DeepLink.tryParse(link);
      expect(parsed, isA<OpenLink>());
      expect(resolveLinkProfile([_owner, _kid], parsed!.profile!), _owner);
    });

    testWidgets('a Plex Home profile links by its user UUID', (tester) async {
      await pumpDialog(tester, ProfileLinkDialog(profile: _kid));

      expect(find.text('plezy://open?profile=a1b2c3'), findsOneWidget);
    });

    testWidgets('opens through showProfileLinkDialog and closes', (tester) async {
      useViewport(tester, const Size(1280, 900));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => unawaited(showProfileLinkDialog(context, _owner)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileLinkDialog), findsOneWidget);

      await tester.tap(find.text(t.common.close));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileLinkDialog), findsNothing);
    });
  });
}
