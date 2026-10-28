import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/media_capture.dart';

void main() {
  group('MediaCaptureSource', () {
    test('builds a session-only MPV preview request from a discovered screen', () {
      const source = MediaCaptureSource(
        id: 'screen:desktop',
        name: 'Desktop screen',
        kind: MediaCaptureKind.screen,
        inputFormat: 'x11grab',
        input: ':0.0+0,0',
        captureCursor: true,
      );

      final request = source.previewRequest(30);

      expect(request.sourceName, 'Desktop screen');
      expect(request.playerAddress, 'av://x11grab::0.0+0,0');
      expect(request.playerOptions, {'demuxer-lavf-format': 'x11grab', 'demuxer-lavf-o': 'framerate=30,draw_mouse=1'});
      expect(source.inputArguments(30), ['-draw_mouse', '1', '-f', 'x11grab', '-framerate', '30', '-i', ':0.0+0,0']);
    });

    test('omits pointer capture for a camera and preserves the selected frame rate', () {
      const source = MediaCaptureSource(
        id: 'camera:0',
        name: 'Camera',
        kind: MediaCaptureKind.camera,
        inputFormat: 'avfoundation',
        input: '0:none',
      );

      final request = source.previewRequest(60);

      expect(request.playerAddress, 'av://avfoundation:0:none');
      expect(request.playerOptions['demuxer-lavf-o'], 'framerate=60');
      expect(source.inputArguments(60), ['-f', 'avfoundation', '-framerate', '60', '-i', '0:none']);
    });
  });
}
