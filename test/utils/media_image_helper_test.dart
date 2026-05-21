import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/utils/media_image_helper.dart';

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
}
