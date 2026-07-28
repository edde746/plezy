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

  // Verified against PMS 1.43: `minSize=1&upscale=1` scales until the smaller
  // axis reaches the request and returns the whole image (a 4313x1035 logo
  // asked for at 1200x360 comes back 1500x360), while `minSize=0&upscale=0`
  // fits the longer axis inside the box (1200x288). Neither crops, so this is
  // purely about not fetching pixels that BoxFit.contain will discard.
  group('PlexClient transcode sizing flags', () {
    test('slot-filling artwork covers the requested box', () {
      final url = client.thumbnailUrl('/library/metadata/1/thumb/2', width: 400, height: 600);

      expect(url, contains('minSize=1'));
      expect(url, contains('upscale=1'));
    });

    test('contain artwork fits inside the requested box', () {
      final url = client.thumbnailUrl('/library/metadata/1/clearLogo', width: 1200, height: 360, cover: false);

      expect(url, contains('minSize=0'));
      expect(url, contains('upscale=0'));
      expect(url, contains('width=1200'));
      expect(url, contains('height=360'));
    });

    test('proxied external images honour the same flag', () {
      final covering = client.externalImageUrl('https://epg.example/logo.png', width: 200, height: 200);
      final fitting = client.externalImageUrl('https://epg.example/logo.png', width: 200, height: 200, cover: false);

      expect(covering, contains('minSize=1'));
      expect(fitting, contains('minSize=0'));
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

    test('poster slots stay covering requests', () {
      final url = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: '/library/metadata/1/thumb/2',
        maxWidth: 200,
        maxHeight: 300,
        devicePixelRatio: 2,
        imageType: ImageType.poster,
      );

      expect(url, contains('minSize=1'));
      expect(url, contains('upscale=1'));
    });
  });
}
