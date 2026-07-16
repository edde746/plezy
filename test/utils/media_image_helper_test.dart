import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/device_performance.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/media_image_helper.dart';

import '../test_helpers/media_items.dart';

/// Only [thumbnailUrl] is exercised; everything else throws via noSuchMethod.
class _SizedUrlFakeClient implements MediaServerClient {
  @override
  String thumbnailUrl(String? path, {int? width, int? height}) =>
      (width == null && height == null) ? 'unsized:$path' : 'sized:$path?w=$width&h=$height';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _item(MediaKind kind) => testMediaItem(kind: kind);

void main() {
  group('MediaImageHelper.getOptimizedImageUrl', () {
    test('adds size hints to absolute Jellyfin artwork URLs', () {
      final url = MediaImageHelper.getOptimizedImageUrl(
        thumbPath: 'https://jf.example/Items/item-1/Images/Primary?tag=abc&api_key=token',
        maxWidth: 120,
        maxHeight: 180,
        devicePixelRatio: 2,
      );

      final uri = Uri.parse(url);
      expect(uri.queryParameters['tag'], 'abc');
      expect(uri.queryParameters['api_key'], 'token');
      expect(uri.queryParameters['maxWidth'], '240');
      expect(uri.queryParameters['maxHeight'], '360');
    });

    test('preserves existing Jellyfin size hints and fills missing dimension', () {
      final url = MediaImageHelper.getOptimizedImageUrl(
        thumbPath: 'https://jf.example/Items/item-1/Images/Primary?api_key=token&maxWidth=100',
        maxWidth: 120,
        maxHeight: 180,
        devicePixelRatio: 2,
      );

      final uri = Uri.parse(url);
      expect(uri.queryParameters['api_key'], 'token');
      expect(uri.queryParameters['maxWidth'], '100');
      expect(uri.queryParameters['maxHeight'], '360');
    });

    test('leaves non-Jellyfin external URLs unchanged without a proxy client', () {
      const original = 'https://images.example/poster.jpg';

      final url = MediaImageHelper.getOptimizedImageUrl(
        thumbPath: original,
        maxWidth: 120,
        maxHeight: 180,
        devicePixelRatio: 2,
      );

      expect(url, original);
    });

    test('leaves Jellyfin artwork unchanged when transcoding is disabled', () {
      const original = 'https://jf.example/Items/item-1/Images/Primary?tag=abc&api_key=token';

      final url = MediaImageHelper.getOptimizedImageUrl(
        thumbPath: original,
        maxWidth: 120,
        maxHeight: 180,
        devicePixelRatio: 2,
        enableTranscoding: false,
      );

      expect(url, original);
    });
  });

  group('MediaImageHelper.getOptimizedImageUrl sized transcodes', () {
    // Unsized URLs hand the full original to the decoder — a multi-megapixel
    // original behind a tiny slot is the decode spike that OOMs low-RAM
    // devices, so every card-sized request must carry dimensions.
    final client = _SizedUrlFakeClient();

    test('tiny slots still request a sized transcode (min bucket)', () {
      final url = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: '/library/metadata/1/thumb/2',
        maxWidth: 40,
        maxHeight: 60,
        devicePixelRatio: 1,
      );

      expect(url, startsWith('sized:'));
      expect(url, contains('w=160'));
      expect(url, contains('h=240'));
    });

    test('regular slots request DPR-scaled dimensions', () {
      final url = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: '/library/metadata/1/thumb/2',
        maxWidth: 200,
        maxHeight: 300,
        devicePixelRatio: 2,
      );

      expect(url, 'sized:/library/metadata/1/thumb/2?w=400&h=600');
    });
  });

  group('MediaImageHelper.getMemCacheDimensions tier caps', () {
    tearDown(DevicePerformance.debugReset);

    test('full tier caps thumb and poster decodes', () {
      DevicePerformance.debugReset(autoReduced: false, override: VisualEffectsSetting.auto);
      expect(
        MediaImageHelper.getMemCacheDimensions(displayWidth: 4000, displayHeight: 4000, imageType: ImageType.thumb),
        (960, 540),
      );
      expect(
        MediaImageHelper.getMemCacheDimensions(displayWidth: 4000, displayHeight: 4000, imageType: ImageType.poster),
        (720, 1080),
      );
    });

    test('reduced tier tightens thumb and poster caps', () {
      DevicePerformance.debugReset(autoReduced: true, override: VisualEffectsSetting.auto);
      expect(
        MediaImageHelper.getMemCacheDimensions(displayWidth: 4000, displayHeight: 4000, imageType: ImageType.thumb),
        (640, 360),
      );
      expect(
        MediaImageHelper.getMemCacheDimensions(displayWidth: 4000, displayHeight: 4000, imageType: ImageType.poster),
        (480, 720),
      );
    });
  });

  group('MediaImageHelper image type budgets', () {
    tearDown(DevicePerformance.debugReset);

    test('hero logos get a larger budget without changing ordinary logos', () {
      DevicePerformance.debugReset(autoReduced: false, override: VisualEffectsSetting.auto);

      expect(
        MediaImageHelper.getMemCacheDimensions(displayWidth: 4000, displayHeight: 4000, imageType: ImageType.logo),
        (600, 300),
      );
      expect(
        MediaImageHelper.getMemCacheDimensions(displayWidth: 4000, displayHeight: 4000, imageType: ImageType.heroLogo),
        (1000, 500),
      );
    });

    test('card artwork follows square, wide, and poster media shapes', () {
      for (final kind in [MediaKind.artist, MediaKind.album, MediaKind.track]) {
        expect(
          MediaImageHelper.cardImageType(_item(kind), EpisodePosterMode.episodeThumbnail),
          ImageType.square,
          reason: '${kind.id} artwork must keep its square music cache budget',
        );
      }

      expect(
        MediaImageHelper.cardImageType(_item(MediaKind.episode), EpisodePosterMode.episodeThumbnail),
        ImageType.thumb,
      );
      expect(
        MediaImageHelper.cardImageType(_item(MediaKind.episode), EpisodePosterMode.seriesPoster),
        ImageType.poster,
      );
      expect(
        MediaImageHelper.cardImageType(_item(MediaKind.movie), EpisodePosterMode.episodeThumbnail),
        ImageType.poster,
      );
    });
  });

  group('MediaImageHelper.serverArtworkProvider', () {
    test('reuses cache identity and disk key while bounding both decode axes', () {
      const url = 'https://example.invalid/library/poster.jpg';

      final first = MediaImageHelper.serverArtworkProvider(imageUrl: url, memWidth: 640, memHeight: 360) as ResizeImage;
      final second =
          MediaImageHelper.serverArtworkProvider(imageUrl: url, memWidth: 640, memHeight: 360) as ResizeImage;
      final firstCached = first.imageProvider as CachedNetworkImageProvider;
      final secondCached = second.imageProvider as CachedNetworkImageProvider;

      expect(firstCached, secondCached);
      expect(first.width, second.width);
      expect(first.width, 640);
      expect(first.height, second.height);
      expect(first.height, 360);
      expect(first.policy, second.policy);
      expect(first.policy, ResizeImagePolicy.fit);
      expect(first.allowUpscaling, second.allowUpscaling);
      expect(first.allowUpscaling, isFalse);
      expect(firstCached.url, secondCached.url);
      expect(firstCached.url, url);
      expect(firstCached.headers, secondCached.headers);
      expect(firstCached.headers, const {'User-Agent': 'Plezy'});
      expect(firstCached.cacheKey, secondCached.cacheKey);
      expect(firstCached.cacheKey, isNotNull);
      expect(firstCached.maxWidth, secondCached.maxWidth);
      expect(firstCached.maxWidth, isNull);
      expect(firstCached.maxHeight, secondCached.maxHeight);
      expect(firstCached.maxHeight, isNull);
    });
  });

  group('MediaImageHelper.boundedDecode', () {
    test('bounds both axes with fit policy (no distortion, no upscale)', () {
      const base = NetworkImage('https://example/img');
      final bounded = MediaImageHelper.boundedDecode(base, memWidth: 640, memHeight: 360);

      expect(bounded, isA<ResizeImage>());
      final resize = bounded as ResizeImage;
      expect(resize.width, 640);
      expect(resize.height, 360);
      expect(resize.policy, ResizeImagePolicy.fit);
      expect(resize.allowUpscaling, isFalse);
    });

    test('passes the provider through when no bound is known', () {
      const base = NetworkImage('https://example/img');
      expect(MediaImageHelper.boundedDecode(base, memWidth: 0, memHeight: 0), same(base));
    });
  });
}
