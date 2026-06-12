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

  group('networkStreamRingBytes', () {
    test('sizes the iPhone 4K60 HDR10 repro file to 64MiB', () {
      // 69140 kbps total → 8.6 MB/s × 6s ≈ 52MB → pow2 64MiB; the guaranteed
      // seek-back half (32MiB) covers the measured ~24MB interleave gap.
      expect(networkStreamRingBytes(container: 'mov', bitrateKbps: 69140), 64 * 1024 * 1024);
    });

    test('returns null for well-interleaved or unknown containers', () {
      expect(networkStreamRingBytes(container: 'mkv', bitrateKbps: 69140), isNull);
      expect(networkStreamRingBytes(container: 'avi', bitrateKbps: 69140), isNull);
      expect(networkStreamRingBytes(container: null, bitrateKbps: 69140), isNull);
      expect(networkStreamRingBytes(container: '', bitrateKbps: 69140), isNull);
    });

    test('matches QuickTime-family containers case-insensitively', () {
      expect(networkStreamRingBytes(container: 'MOV', bitrateKbps: 69140), 64 * 1024 * 1024);
      expect(networkStreamRingBytes(container: 'mp4', bitrateKbps: 69140), 64 * 1024 * 1024);
    });

    test('matches ffmpeg demuxer alias lists from Jellyfin', () {
      expect(networkStreamRingBytes(container: 'mov,mp4,m4a,3gp,3g2,mj2', bitrateKbps: 69140), 64 * 1024 * 1024);
      expect(networkStreamRingBytes(container: 'matroska,webm', bitrateKbps: 69140), isNull);
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
