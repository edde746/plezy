import 'dart:math';

/// mpv's built-in `stream-buffer-size` default (128 KiB). Written back for
/// opens that don't qualify for an enlarged ring so a reused player instance
/// never carries one item's tuning into the next.
const mpvDefaultStreamBufferBytes = 128 * 1024;

/// QuickTime/MP4 muxer family. Apple capture muxers (iPhone recordings and
/// friends) can store audio packets seconds away from coeval video packets —
/// in bytes, seconds × video byterate — which makes ffmpeg's DTS-ordered
/// reads ping-pong across the file. Over HTTP every ping-pong that escapes
/// mpv's stream ring buffer is a byte seek, and ffmpeg's http layer drops and
/// redials the connection on every seek, collapsing throughput. MKV is
/// interleaved by spec and excluded.
const poorlyInterleavedContainers = {'mp4', 'mov', 'm4v', '3gp', '3g2'};

const minStreamRingBytes = 16 * 1024 * 1024;
const maxStreamRingBytes = 128 * 1024 * 1024;

/// Ring for QuickTime-family content whose bitrate the backend didn't report.
const unknownBitrateStreamRingBytes = 64 * 1024 * 1024;

/// Seconds of content bytes the ring should hold. mpv guarantees only half
/// the ring as seek-back history, so 6s of bytes ⇒ ≥3s of guaranteed
/// interleave-skew coverage (observed iPhone skew ~2.9s) before the
/// power-of-two round-up adds headroom.
const _streamRingContentSeconds = 6;

int nextPowerOfTwo(int value) {
  var result = 1;
  while (result < value) {
    result <<= 1;
  }
  return result;
}

/// Heap-tier cap for the stream ring on Android, mirroring the demuxer
/// auto-scaling tiers in video_player_screen.dart — mpv is the
/// ExoPlayer-fallback engine there, which is exactly where low-RAM TV boxes
/// land.
int androidStreamRingCapBytes(int heapMB) {
  if (heapMB <= 0) return unknownBitrateStreamRingBytes;
  if (heapMB <= 256) return 32 * 1024 * 1024;
  if (heapMB <= 512) return 64 * 1024 * 1024;
  return maxStreamRingBytes;
}

/// mpv `stream-buffer-size` for a network direct play of [container] at
/// [bitrateKbps] total bitrate, or null when mpv's 128 KiB default suffices.
///
/// The ring absorbs the demuxer's audio↔video byte alternation entirely in
/// RAM so the underlying HTTP reads stay linear. The ring is fully allocated
/// (power-of-two rounded) per stream, hence the container gate and bitrate
/// scaling instead of a flat global value.
int? networkStreamRingBytes({
  required String? container,
  required int? bitrateKbps,
  int maxBytes = maxStreamRingBytes,
}) {
  if (container == null) return null;
  // Jellyfin may report ffmpeg demuxer alias lists ('mov,mp4,m4a,3gp,3g2,mj2').
  final tokens = container.toLowerCase().split(',').map((token) => token.trim());
  if (!tokens.any(poorlyInterleavedContainers.contains)) return null;

  final cap = max(minStreamRingBytes, min(maxBytes, maxStreamRingBytes));
  if (bitrateKbps == null || bitrateKbps <= 0) return min(unknownBitrateStreamRingBytes, cap);

  final bytesPerSecond = bitrateKbps * 1000 ~/ 8;
  final ring = nextPowerOfTwo(bytesPerSecond * _streamRingContentSeconds);
  return max(minStreamRingBytes, min(ring, cap));
}
