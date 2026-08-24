import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/media_image_helper.dart';

import '../test_helpers/backend_client_fixtures.dart';

void main() {
  late AppDatabase db;
  late PlexClient client;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    client = testPlexClient();
  });

  tearDown(() async {
    client.close();
    await db.close();
  });

  // Verified against PMS 1.43: `minSize=1` scales until the smaller axis
  // reaches the request and returns the whole image, while `minSize=0` fits
  // the longer axis inside the box (a 4313x1035 logo asked for at 1200x360
  // comes back 1200x288). Neither crops. `upscale=0` caps the scale at 1.0 on
  // both paths: downscale output is byte-identical to `upscale=1`, and a
  // request larger than the source returns the native image instead of a
  // server-side enlargement (#1975 — 4K-budget art requests genuinely
  // upscaled every 1920x1080 source at real transcoder cost).
  group('PlexClient transcode sizing flags', () {
    test('slot-filling artwork covers the box without server upscaling', () {
      final url = client.thumbnailUrl('/library/metadata/1/thumb/2', width: 400, height: 600);

      expect(url, contains('minSize=1'));
      expect(url, contains('upscale=0'));
    });

    test('contain artwork fits inside the requested box', () {
      final url = client.thumbnailUrl('/library/metadata/1/clearLogo', width: 1200, height: 360, cover: false);

      expect(url, contains('minSize=0'));
      expect(url, contains('upscale=0'));
      expect(url, contains('width=1200'));
      expect(url, contains('height=360'));
    });

    test('proxied external images honour the same flags', () {
      final covering = client.externalImageUrl('https://epg.example/logo.png', width: 200, height: 200);
      final fitting = client.externalImageUrl('https://epg.example/logo.png', width: 200, height: 200, cover: false);

      expect(covering, contains('minSize=1'));
      expect(covering, contains('upscale=0'));
      expect(fitting, contains('minSize=0'));
      expect(fitting, contains('upscale=0'));
    });

    test('logo slots reach the client as fitting requests', () {
      final url = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: '/library/metadata/1/clearLogo',
        maxWidth: 400,
        maxHeight: 120,
        devicePixelRatio: 3,
        imageType: ImageType.heroLogo,
      );

      expect(url, contains('minSize=0'));
      expect(url, contains('upscale=0'));
    });

    test('poster slots stay covering, never-upscaling requests', () {
      final url = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: '/library/metadata/1/thumb/2',
        maxWidth: 200,
        maxHeight: 300,
        devicePixelRatio: 2,
        imageType: ImageType.poster,
      );

      expect(url, contains('minSize=1'));
      expect(url, contains('upscale=0'));
    });
  });
}
