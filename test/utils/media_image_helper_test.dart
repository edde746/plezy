import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/device_performance.dart';
import 'package:plezy/utils/media_image_helper.dart';

/// Only [thumbnailUrl] is exercised; everything else throws via noSuchMethod.
class _SizedUrlFakeClient implements MediaServerClient {
  @override
  String thumbnailUrl(String? path, {int? width, int? height}) =>
      (width == null && height == null) ? 'unsized:$path' : 'sized:$path?w=$width&h=$height';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

    test('near-minimum slots request a sized transcode', () {
      final url = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: '/library/metadata/1/thumb/2',
        maxWidth: 96,
        maxHeight: 144,
        devicePixelRatio: 1,
      );

      expect(url, startsWith('sized:'));
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
