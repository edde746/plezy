import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player/widgets/player_prompt_overlays.dart';
import 'package:plezy/services/download_artwork_helpers.dart';
import 'package:plezy/services/download_artwork_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/pip_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';

/// A 1x1 PNG: the resolved still has to decode, not trip the error widget.
const _pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

// Offline, the play-next card paints the next episode's still from the file
// the download side wrote. That writer keys artwork by the thumb path with
// `api_key` stripped, so the reader has to strip it too or a Jellyfin/Emby
// still (whose thumb URL carries the token) never resolves and the card
// silently degrades to text-only.
void main() {
  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late DownloadArtworkService artwork;
  late MediaServerHttpClient http;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    tmpRoot = await Directory.systemTemp.createTemp('player_prompt_overlays_artwork_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
    final settings = await SettingsService.getInstance();
    final storage = DownloadStorageService.instance;
    await storage.initialize(settings);
    http = MediaServerHttpClient(client: FakeHttpClient(200, base64Decode(_pngBase64)));
    artwork = DownloadArtworkService(storageService: storage, http: http);
  });

  tearDown(() async {
    http.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  });

  /// Saves [episode]'s thumb the way the download manager does when it stores
  /// the episode (spec from [buildArtworkSpecs], written by the artwork
  /// service) and returns the file it produced.
  Future<String> downloadThumb(MediaItem episode) async {
    final serverId = ServerId(episode.serverId!);
    final spec = buildArtworkSpecs(episode, (path) => path).single;
    expect(await artwork.downloadSingleArtwork(serverId, spec), isTrue);
    return artwork.localPath(serverId, spec.localKey);
  }

  /// Pumps the visible prompt for [episode] with no reachable server, then
  /// lets the local-file probe complete on the real event loop.
  Future<void> pumpOfflinePrompt(WidgetTester tester, MediaItem episode) async {
    PipService().isPipActive.value = false;
    final chromeController = PlayerChromeController();
    final cancelFocusNode = FocusNode(debugLabel: 'TestCancel');
    final confirmFocusNode = FocusNode(debugLabel: 'TestConfirm');
    final countdown = ValueNotifier<int>(-1);
    addTearDown(chromeController.dispose);
    addTearDown(cancelFocusNode.dispose);
    addTearDown(confirmFocusNode.dispose);
    addTearDown(countdown.dispose);

    await tester.pumpWidget(
      _wrapPrompt(
        VideoPlayerPlayNextOverlay(
          visible: true,
          nextEpisode: episode,
          autoPlayCountdown: countdown,
          cancelFocusNode: cancelFocusNode,
          confirmFocusNode: confirmFocusNode,
          chromeController: chromeController,
          onCancel: () {},
          onPlayNext: () {},
        ),
        servers: testMultiServer().provider,
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }

  testWidgets('offline play-next paints the downloaded still for a token-carrying Jellyfin thumb', (tester) async {
    final episode = _episode(
      backend: MediaBackend.jellyfin,
      thumbPath: 'https://jf.example/Items/episode-2/Images/Primary?tag=abc&api_key=secret',
    );
    final written = (await tester.runAsync(() => downloadThumb(episode)))!;

    await pumpOfflinePrompt(tester, episode);

    expect(_renderedStill(tester), _decodesFrom(written));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('offline play-next paints the downloaded still for a token-free Plex thumb', (tester) async {
    final episode = _episode(backend: MediaBackend.plex, thumbPath: '/library/metadata/episode-2/thumb/1');
    final written = (await tester.runAsync(() => downloadThumb(episode)))!;

    await pumpOfflinePrompt(tester, episode);

    expect(_renderedStill(tester), _decodesFrom(written));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _wrapPrompt(Widget child, {required MultiServerProvider servers}) {
  return ChangeNotifierProvider<MultiServerProvider>.value(
    value: servers,
    child: ChangeNotifierProvider(
      create: (_) => PlaybackStateProvider(),
      child: MaterialApp(
        home: Scaffold(body: Stack(children: [child])),
      ),
    ),
  );
}

MediaItem _episode({required MediaBackend backend, required String thumbPath}) {
  return testMediaItem(
    id: 'episode-2',
    backend: backend,
    kind: MediaKind.episode,
    title: 'Episode 2',
    parentIndex: 1,
    index: 2,
    serverId: 'server-1',
    thumbPath: thumbPath,
  );
}

/// The image source the prompt's still decodes from, or null when no still is
/// painted (the text-only card). Unwraps the decode-bounding [ResizeImage].
ImageProvider? _renderedStill(WidgetTester tester) {
  final images = tester.widgetList<Image>(find.byType(Image));
  if (images.isEmpty) return null;
  final provider = images.single.image;
  return provider is ResizeImage ? provider.imageProvider : provider;
}

/// Offline, the still has to come from the downloaded file rather than a
/// network fetch that cannot succeed.
Matcher _decodesFrom(String path) => isA<FileImage>().having((image) => image.file.path, 'file.path', path);
