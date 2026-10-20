import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/screens/video_player/widgets/player_prompt_overlays.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/external_ids.dart';
import 'package:plezy/watch_together/models/watch_copy.dart';
import 'package:plezy/watch_together/models/watch_notice.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/watch_together/services/library_resolver.dart';
import 'package:plezy/watch_together/services/player_adapter.dart';
import 'package:plezy/watch_together/widgets/watch_together_overlay.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:provider/provider.dart';

import 'fake_owp_relay.dart';
import 'library_lookup.dart';
import 'media_items.dart';
import 'watch_together_fakes.dart';

/// The server the [WatchRoomHarness.host] shares its files from.
const watchHostServerId = 'host-nas';

/// The server a [WatchRoomHarness.guest]'s copies live on.
const watchGuestServerId = 'guest-nas';

/// A movie with one version of [durationMs] on [serverId].
MediaItem watchMovie({
  required String id,
  String serverId = watchHostServerId,
  String title = 'Alien',
  int year = 1979,
  int durationMs = 7020000,
  String version = 'hd',
  MediaKind kind = MediaKind.movie,
}) => testMediaItem(
  id: id,
  kind: kind,
  title: title,
  year: year,
  serverId: serverId,
  serverName: serverId == watchHostServerId ? 'Host NAS' : 'Guest NAS',
  durationMs: durationMs,
  mediaVersions: [
    MediaVersion(
      id: version,
      videoResolution: '1080',
      parts: [MediaPart(id: '$version-p', durationMs: durationMs, sizeBytes: 4000000, file: '/m/$id.mkv')],
    ),
  ],
);

/// The copy a player opens for [item]: its first version.
WatchCopy watchCopyOf(MediaItem item) => WatchCopy.of(item, item.mediaVersions?.first);

/// A server that describes the host's items for sharing: every movie has the
/// same catalogue IDs, so guests find their own copies by them.
final class _HostServer implements MediaServerClient {
  @override
  ServerId get serverId => ServerId(watchHostServerId);

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async => const ExternalIds(imdb: 'tt0078748', tmdb: 348);

  @override
  Future<MediaItem?> fetchItem(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A player with a file open, as the player screen hands it to the provider.
typedef WatchTestPlayer = ({PlezyPlayerAdapter adapter, FakeSyncPlayer player});

/// A player with [copy] open. While [refusePlay] answers true its play command
/// throws, as a player that refuses to start does.
WatchTestPlayer watchTestPlayer(WatchCopy copy, {bool Function()? refusePlay}) {
  final player = FakeSyncPlayer(hasRenderedFrame: true, duration: Duration(milliseconds: copy.durationMs ?? 0));
  final adapter = PlezyPlayerAdapter(
    player: player,
    copy: copy,
    commands: PlayerCommands(
      play: () => (refusePlay?.call() ?? false) ? Future.error(StateError('playback refused')) : player.play(),
      pause: player.pause,
      seek: player.seek,
      setRate: player.setRate,
    ),
  );
  return (adapter: adapter, player: player);
}

/// The player screen the app opens for the room: it opens the room's file
/// when asked, registers its hooks and reports the player.
final class WatchTestScreen {
  WatchTestScreen(this.provider, {this.refusePlay = false}) {
    provider.navigatorOpener = open;
  }

  final WatchTogetherProvider provider;
  final List<WatchTestPlayer> players = [];
  bool refusePlay;

  Future<bool> open(WatchCopy copy) async {
    // A route push: the player reports back after the room's update.
    await Future<void>.delayed(Duration.zero);
    final opened = watchTestPlayer(copy, refusePlay: () => refusePlay);
    players.add(opened);
    provider.registerPlayer(this, WatchPlayerHooks(openInPlace: open, exitPlayer: () {}));
    provider.playerOpened(opened.adapter, shareable: true, roomLaunch: true);
    return true;
  }
}

/// Participants of one [FakeOwpRelay] room in widget-test time: providers made
/// as the app makes them, the host sharing files from a player, guests with
/// their own copies.
final class WatchRoomHarness {
  WatchRoomHarness(this.tester);

  final WidgetTester tester;
  final relay = FakeOwpRelay();
  final List<WatchTogetherProvider> _providers = [];

  /// A participant named [name]. [relayBaseUrl] is the relay setting (null:
  /// the public relays); the room is on [relay] either way.
  WatchTogetherProvider member(
    String name, {
    String? profileId,
    String? relayBaseUrl,
    ServerClientLookup? clientFor,
    TitleCopyFinder? findCopies,
  }) {
    final provider = WatchTogetherProvider(
      partyFactory: relay.party,
      clientName: () async => 'Plezy/1.0',
      displayName: () => name,
      profileId: () => profileId,
      customRelayBaseUrl: () => relayBaseUrl,
      clientFor: clientFor,
      findCopies: findCopies,
    );
    _providers.add(provider);
    return provider;
  }

  /// A participant who shares files of [watchHostServerId].
  WatchTogetherProvider host({String name = 'Anna', String? profileId, String? relayBaseUrl}) {
    final server = _HostServer();
    return member(
      name,
      profileId: profileId,
      relayBaseUrl: relayBaseUrl,
      clientFor: (serverId) => serverId == watchHostServerId ? server : null,
    );
  }

  /// A participant whose libraries hold [copies]: a search for a title finds
  /// the copies with that title. [copies] is read at each search.
  WatchTogetherProvider guest({String name = 'Ben', String? profileId, List<MediaItem> Function()? copies}) => member(
    name,
    profileId: profileId,
    findCopies: (query, {abort}) async => libraryLookupResult(
      [
        for (final item in copies?.call() ?? const <MediaItem>[])
          if (item.title == query.title) item,
      ],
      succeeded: {watchGuestServerId},
    ),
  );

  Future<void> wait(Duration duration) => tester.pump(duration);

  Future<void> until(bool Function() check, String what) async {
    for (var i = 0; i < 500; i++) {
      if (check()) return;
      await wait(const Duration(milliseconds: 20));
    }
    fail('timed out waiting until $what');
  }

  /// [future], with time running until it completes.
  Future<T> settle<T>(Future<T> future) async {
    var done = false;
    unawaited(future.then<void>((_) => done = true, onError: (Object _) => done = true));
    await until(() => done, 'the call completed');
    return future;
  }

  /// [host] creates the room and [guests] join it; completes once everyone
  /// sees everyone.
  Future<void> together(WatchTogetherProvider host, List<WatchTogetherProvider> guests) async {
    if (!host.isConnected) await settle(host.createRoom());
    for (final guest in guests) {
      await settle(guest.joinRoom(host.roomCode!));
    }
    final everyone = [host, ...guests];
    await until(
      () => everyone.every((p) => p.participantCount == everyone.length),
      'everyone sees ${everyone.length} participants',
    );
  }

  /// [host] opens [item] in its player; completes once the room plays it.
  Future<WatchTestPlayer> hostPlays(WatchTogetherProvider host, MediaItem item) async {
    final opened = watchTestPlayer(watchCopyOf(item));
    host.playerOpened(opened.adapter, shareable: true, roomLaunch: false);
    await until(() => host.roomCopy?.ref == opened.adapter.copy && host.media != null, 'the room plays the host file');
    return opened;
  }

  /// Disposes of every provider and lets their parties close. Unmount the
  /// widgets that listen to them first.
  Future<void> close() async {
    for (final provider in _providers) {
      provider.dispose();
    }
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Every notice [provider] gives from now on.
List<WatchNotice> recordWatchNotices(WatchTogetherProvider provider) {
  final notices = <WatchNotice>[];
  final subscription = provider.notices.listen(notices.add);
  // Not awaiting the cancel: a broadcast subscription's cancel future belongs
  // to the root zone, which widget-test time never runs.
  addTearDown(() => unawaited(subscription.cancel()));
  return notices;
}

/// Mocks the platform clipboard: it holds [contents], and every text the app
/// copies lands in the returned list.
List<String> mockWatchClipboard({String? contents}) {
  final copied = <String>[];
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    switch (call.method) {
      case 'Clipboard.setData':
        copied.add((call.arguments as Map<Object?, Object?>)['text']! as String);
      case 'Clipboard.getData':
        return contents == null ? null : <String, Object?>{'text': contents};
    }
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return copied;
}

/// The texts inside the control with primary focus, and its node, for
/// assertions and their failure messages.
String describeWatchFocus() {
  final node = FocusManager.instance.primaryFocus;
  final context = node?.context;
  final texts = <String>[];
  if (context is Element) {
    void visit(Element element) {
      final widget = element.widget;
      if (widget is Text && widget.data != null) texts.add(widget.data!);
      element.visitChildren(visit);
    }

    context.visitChildren(visit);
  }
  return '${node?.runtimeType}(${node?.debugLabel}) $texts';
}

/// Whether primary focus is on one control (not a whole scope) that shows
/// [text].
bool watchFocusIsOn(String text) {
  final node = FocusManager.instance.primaryFocus;
  final context = node?.context;
  if (node == null || node is FocusScopeNode || context is! Element) return false;
  var found = false;
  void visit(Element element) {
    final widget = element.widget;
    if (widget is Text && widget.data == text) found = true;
    if (!found) element.visitChildren(visit);
  }

  context.visitChildren(visit);
  return found;
}

void expectWatchFocus(String text) =>
    expect(watchFocusIsOn(text), isTrue, reason: 'expected focus on "$text", is on ${describeWatchFocus()}');

/// Presses [key] and lets the frames it starts run: focus moves, sheets and
/// dialogs open or close, a page transition ends.
Future<void> pressWatchKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await settleWatchFrames(tester);
}

/// Lets a sheet, dialog or route transition finish (a page pop takes the
/// longest, about 600 ms) without waiting for spinners to stop (they never
/// do).
Future<void> settleWatchFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// The app's layers around [home]: translations, input modes, [provider], the
/// app's remote and gamepad shortcuts (select/A activate, back/B dismiss), and
/// a navigator that suppresses a back key's stray key-up after a pop, as the
/// app's navigators do.
Widget watchTestApp(
  WatchTogetherProvider provider, {
  required Widget home,
  TransitionBuilder? builder,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return TranslationProvider(
    child: InputModeTracker(
      child: ChangeNotifierProvider<WatchTogetherProvider>.value(
        value: provider,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: monoTheme(MonoPalette.dark),
          navigatorObservers: [BackKeySuppressorObserver()],
          shortcuts: <ShortcutActivator, Intent>{
            ...WidgetsApp.defaultShortcuts,
            const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
            const SingleActivator(LogicalKeyboardKey.gameButtonA): const ActivateIntent(),
            const SingleActivator(LogicalKeyboardKey.goBack): const DismissIntent(),
            const SingleActivator(LogicalKeyboardKey.browserBack): const DismissIntent(),
            const SingleActivator(LogicalKeyboardKey.gameButtonB): const DismissIntent(),
          },
          builder: builder,
          home: home,
        ),
      ),
    ),
  );
}

/// A home page whose button pushes [screen], so Back has a route to return to.
class WatchTestLauncher extends StatelessWidget {
  const WatchTestLauncher({super.key, required this.screen});

  static const label = 'Open screen';

  final Widget screen;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        autofocus: true,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen)),
        child: const Text(label),
      ),
    ),
  );
}

/// The player screen's room surfaces in its sheet host: the header's room
/// pill, and the room overlays over the video (reconnecting pill, mismatch
/// prompt, play-blocked prompt). Back with no sheet open leaves it, as it
/// leaves the player.
class WatchTestPlayerPage extends StatelessWidget {
  const WatchTestPlayerPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => handleBackKeyNavigation<void>(context, event),
      child: const OverlaySheetHost(
        canPop: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(padding: EdgeInsets.all(16), child: WatchTogetherSessionIndicator()),
            ),
            VideoPlayerWatchTogetherOverlays(),
          ],
        ),
      ),
    ),
  );
}
