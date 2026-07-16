import 'dart:async';
import 'package:plezy/media/ids.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/download_resolution.dart';
import 'package:plezy/media/media_backend.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/download_artwork_helpers.dart';
import 'package:plezy/services/download_artwork_service.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/media_items.dart';

class _DelayedCountingHttpClient extends http.BaseClient {
  _DelayedCountingHttpClient(this.body);

  final List<int> body;
  final release = Completer<void>();
  int sends = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sends++;
    await release.future;
    return http.StreamedResponse(Stream<List<int>>.value(body), 200, request: request);
  }
}

void main() {
  late Directory tmpRoot;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    tmpRoot = await Directory.systemTemp.createTemp('download_artwork_service_test_');
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
  });

  tearDown(() async {
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    if (await tmpRoot.exists()) await tmpRoot.delete(recursive: true);
  });

  test('buildArtworkSpecs includes all standard artwork with sanitized local keys', () {
    final item = testMediaItem(
      id: 'item-1',
      backend: MediaBackend.jellyfin,
      kind: MediaKind.movie,
      serverId: 'srv',
      thumbPath: 'https://jf/Items/1/Images/Primary?tag=p&api_key=secret',
      clearLogoPath: 'https://jf/Items/1/Images/Logo?tag=l&api_key=secret',
      artPath: 'https://jf/Items/1/Images/Backdrop/0?tag=b&api_key=secret',
      backgroundSquarePath: 'https://jf/Items/1/Images/Thumb?tag=s&api_key=secret',
    );

    final specs = buildArtworkSpecs(item, (path) => path);

    expect(specs, hasLength(4));
    expect(specs.map((spec) => spec.localKey), everyElement(isNot(contains('api_key'))));
    expect(specs.map((spec) => spec.url), everyElement(contains('api_key=secret')));
  });

  test('local paths normalize tokenized Jellyfin URLs', () async {
    final settings = await SettingsService.getInstance();
    final storage = DownloadStorageService.instance;
    await storage.initialize(settings);
    final service = DownloadArtworkService(
      storageService: storage,
      http: MediaServerHttpClient(client: FakeHttpClient(200, utf8.encode('image'))),
    );

    const tokenized = 'https://jf/Items/1/Images/Logo?tag=abc&api_key=secret';
    const sanitized = 'https://jf/Items/1/Images/Logo?tag=abc';

    expect(await service.localPath(ServerId('srv'), tokenized), await service.localPath(ServerId('srv'), sanitized));
  });

  test('downloadFile rejects non-success responses without leaving final files', () async {
    final file = File(p.join(tmpRoot.path, 'art.jpg'));
    final httpClient = MediaServerHttpClient(client: FakeHttpClient(404, utf8.encode('not found')));

    await expectLater(
      httpClient.downloadFile('https://example.test/art.jpg', file.path),
      throwsA(isA<MediaServerHttpException>()),
    );

    expect(file.existsSync(), isFalse);
    expect(File('${file.path}.download').existsSync(), isFalse);
  });

  test('downloadSingleArtwork replaces unusable existing files', () async {
    final settings = await SettingsService.getInstance();
    final storage = DownloadStorageService.instance;
    await storage.initialize(settings);
    final body = utf8.encode('valid image bytes');
    final service = DownloadArtworkService(
      storageService: storage,
      http: MediaServerHttpClient(client: FakeHttpClient(200, body)),
    );

    const rawPath = 'https://jf/Items/1/Images/Logo?tag=abc&api_key=secret';
    final filePath = await service.localPath(ServerId('srv'), rawPath);
    await File(filePath).writeAsString('<html>not an image</html>');

    await service.downloadSingleArtwork(
      ServerId('srv'),
      DownloadArtworkSpec(localKey: artworkStorageKey(rawPath), url: 'https://example.test/logo.png'),
    );

    expect(await File(filePath).readAsBytes(), body);
    expect(await service.existsUsable(ServerId('srv'), rawPath), isTrue);
  });

  test('downloadSingleArtwork serializes duplicate writes to the same local file', () async {
    final settings = await SettingsService.getInstance();
    final storage = DownloadStorageService.instance;
    await storage.initialize(settings);
    final httpClient = _DelayedCountingHttpClient(utf8.encode('valid image bytes'));
    final service = DownloadArtworkService(
      storageService: storage,
      http: MediaServerHttpClient(client: httpClient),
    );
    const rawPath = 'https://jf/Items/1/Images/Logo?tag=abc&api_key=secret';
    final spec = DownloadArtworkSpec(localKey: artworkStorageKey(rawPath), url: 'https://example.test/logo.png');

    final first = service.downloadSingleArtwork(ServerId('srv'), spec);
    await Future<void>.delayed(Duration.zero);
    final second = service.downloadSingleArtwork(ServerId('srv'), spec);
    await Future<void>.delayed(Duration.zero);
    httpClient.release.complete();

    await Future.wait([first, second]);

    expect(httpClient.sends, 1);
    expect(await service.existsUsable(ServerId('srv'), rawPath), isTrue);
  });
}
