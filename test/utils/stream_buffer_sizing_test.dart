import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/stream_buffer_sizing.dart';

void main() {
  group('nextPowerOfTwo', () {
    test('rounds up to the next power of two', () {
      expect(nextPowerOfTwo(1), 1);
      expect(nextPowerOfTwo(2), 2);
      expect(nextPowerOfTwo(3), 4);
      expect(nextPowerOfTwo(52 * 1024 * 1024), 64 * 1024 * 1024);
      expect(nextPowerOfTwo(64 * 1024 * 1024), 64 * 1024 * 1024);
      expect(nextPowerOfTwo(64 * 1024 * 1024 + 1), 128 * 1024 * 1024);
    });
  });

  group('readsUncachedLocalFile', () {
    test('is true for a download in the app\'s own data directory on Android and iOS', () {
      expect(
        readsUncachedLocalFile(
          'file:///data/user/0/com.edde746.plezy/app_flutter/downloads/Movie [1a2b3c4d].mkv',
          platform: TargetPlatform.android,
        ),
        isTrue,
      );
      expect(
        readsUncachedLocalFile(
          'file:///var/mobile/Containers/Data/Application/0B1C/Documents/downloads/Movie [1a2b3c4d].mkv',
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
      expect(
        readsUncachedLocalFile(
          'file:///private/var/mobile/Containers/Data/Application/0B1C/Documents/downloads/Movie.mkv',
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
    });

    test('is false where mpv puts its cache in front of the file', () {
      // Android shared storage and memory cards are FUSE, a SAF document is
      // read through a descriptor on it: mpv treats all three as streams.
      expect(
        readsUncachedLocalFile('file:///storage/emulated/0/Movies/Movie.mkv', platform: TargetPlatform.android),
        isFalse,
      );
      expect(
        readsUncachedLocalFile('file:///storage/1A2B-3C4D/Plezy/Movie.mkv', platform: TargetPlatform.android),
        isFalse,
      );
      expect(
        readsUncachedLocalFile(
          'content://com.android.externalstorage.documents/tree/primary%3APlezy/document/primary%3APlezy%2FMovie.mkv',
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
      // A folder outside the app's container may be a network share.
      expect(
        readsUncachedLocalFile(
          'file:///private/var/mobile/Library/LiveFiles/smb/Movie.mkv',
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
      // So may one that only carries the container's names deeper in its path.
      expect(
        readsUncachedLocalFile(
          'file:///private/var/mobile/Library/LiveFiles/smb/Containers/Data/Application/0B1C/Movie.mkv',
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
    });

    test('is false on desktop, where a download folder may be a network mount', () {
      for (final platform in [TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux]) {
        expect(
          readsUncachedLocalFile('file:///home/user/.local/share/plezy/downloads/Movie.mkv', platform: platform),
          isFalse,
        );
      }
    });
  });

  group('demuxerHysteresisSecs', () {
    test('gives an uncached local file half a second of hysteresis', () {
      expect(demuxerHysteresisSecs(uncachedLocalFile: true, customMpvConfig: const {}), '0.5');
    });

    test('leaves mpv\'s default for anything mpv caches', () {
      // The value is absolute: a stream's read-ahead is its cache, and half a
      // second would let that drain before every refill.
      expect(demuxerHysteresisSecs(uncachedLocalFile: false, customMpvConfig: const {}), '0');
    });

    test('leaves mpv\'s default for a local file a cache=yes line puts behind the cache', () {
      expect(demuxerHysteresisSecs(uncachedLocalFile: true, customMpvConfig: const {'cache': 'yes'}), '0');
      expect(demuxerHysteresisSecs(uncachedLocalFile: true, customMpvConfig: const {'cache': 'no'}), '0.5');
    });

    test('leaves the option to a custom mpv config line that names it', () {
      const config = {'demuxer-hysteresis-secs': '0', 'sub-font': 'Netflix Sans'};
      expect(demuxerHysteresisSecs(uncachedLocalFile: true, customMpvConfig: config), isNull);
      expect(demuxerHysteresisSecs(uncachedLocalFile: false, customMpvConfig: config), isNull);
      expect(
        demuxerHysteresisSecs(uncachedLocalFile: true, customMpvConfig: const {'sub-font': 'Netflix Sans'}),
        '0.5',
      );
    });
  });

  group('networkStreamRingBytes', () {
    test('sizes the iPhone 4K60 HDR10 repro file to 64MiB', () {
      // 69140 kbps total → 8.6 MB/s × 6s ≈ 52MB → pow2 64MiB; the guaranteed
      // seek-back half (32MiB) covers the measured ~24MB interleave gap.
      expect(networkStreamRingBytes(container: 'mov', bitrateKbps: 69140), 64 * 1024 * 1024);
    });

    test('returns null for well-interleaved or unknown containers', () {
      expect(networkStreamRingBytes(container: 'avi', bitrateKbps: 69140), isNull);
      expect(networkStreamRingBytes(container: null, bitrateKbps: 69140), isNull);
      expect(networkStreamRingBytes(container: '', bitrateKbps: 69140), isNull);
    });

    test('sizes high-bitrate Matroska direct play to 64MiB', () {
      expect(networkStreamRingBytes(container: 'mkv', bitrateKbps: 69140), 64 * 1024 * 1024);
      expect(networkStreamRingBytes(container: 'matroska', bitrateKbps: 69140), 64 * 1024 * 1024);
    });

    test('keeps ordinary Matroska direct play on the default stream ring', () {
      expect(networkStreamRingBytes(container: 'mkv', bitrateKbps: 39000), isNull);
      expect(networkStreamRingBytes(container: 'mkv', bitrateKbps: null), isNull);
      expect(networkStreamRingBytes(container: 'mkv', bitrateKbps: 0), isNull);
    });

    test('matches QuickTime-family containers case-insensitively', () {
      expect(networkStreamRingBytes(container: 'MOV', bitrateKbps: 69140), 64 * 1024 * 1024);
      expect(networkStreamRingBytes(container: 'mp4', bitrateKbps: 69140), 64 * 1024 * 1024);
    });

    test('matches ffmpeg demuxer alias lists from Jellyfin', () {
      expect(networkStreamRingBytes(container: 'mov,mp4,m4a,3gp,3g2,mj2', bitrateKbps: 69140), 64 * 1024 * 1024);
      expect(networkStreamRingBytes(container: 'matroska,webm', bitrateKbps: 69140), 64 * 1024 * 1024);
    });

    test('falls back to 64MiB when bitrate is unknown', () {
      expect(networkStreamRingBytes(container: 'mov', bitrateKbps: null), 64 * 1024 * 1024);
      expect(networkStreamRingBytes(container: 'mov', bitrateKbps: 0), 64 * 1024 * 1024);
    });

    test('clamps to the 16MiB floor for low bitrates', () {
      expect(networkStreamRingBytes(container: 'mp4', bitrateKbps: 1000), 16 * 1024 * 1024);
    });

    test('clamps to the 128MiB ceiling for very high bitrates', () {
      expect(networkStreamRingBytes(container: 'mov', bitrateKbps: 400000), 128 * 1024 * 1024);
    });

    test('respects a lower Android heap cap, including the unknown-bitrate path', () {
      expect(
        networkStreamRingBytes(container: 'mov', bitrateKbps: 69140, maxBytes: 32 * 1024 * 1024),
        32 * 1024 * 1024,
      );
      expect(networkStreamRingBytes(container: 'mov', bitrateKbps: null, maxBytes: 32 * 1024 * 1024), 32 * 1024 * 1024);
    });
  });

  group('androidStreamRingCapBytes', () {
    test('tiers by device heap with a conservative unknown fallback', () {
      expect(androidStreamRingCapBytes(0), 64 * 1024 * 1024);
      expect(androidStreamRingCapBytes(256), 32 * 1024 * 1024);
      expect(androidStreamRingCapBytes(512), 64 * 1024 * 1024);
      expect(androidStreamRingCapBytes(1024), 128 * 1024 * 1024);
    });
  });
}
