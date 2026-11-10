import 'dart:math';

import 'package:flutter/foundation.dart';

/// mpv's built-in `stream-buffer-size` default (128 KiB). Written back for
/// opens that don't qualify for an enlarged ring so a reused player instance
/// never carries one item's tuning into the next.
const mpvDefaultStreamBufferBytes = 128 * 1024;

/// Whether mpv reads the downloaded copy at [uri] straight off the device's
/// own storage, with no demuxer cache in front of it.
///
/// mpv caches a file like a network stream when a network may be behind its
/// filesystem: FUSE, which is Android's shared storage (from Android 11) and
/// every SAF `content://` document, and NFS or SMB mounts elsewhere. Only the
/// app's own data directory is known to be neither, and only on the two
/// platforms where that directory is always on the device: a custom download
/// folder, a memory card and every desktop path answer false. The test is a
/// prefix anchored at the root of the path: `/data/` on Android, the app
/// containers of an iPhone or iPad (`/var/mobile/Containers/Data/Application/`
/// and its `/private` alias) on iOS, so a folder elsewhere that merely
/// contains those names does not qualify.
bool readsUncachedLocalFile(String uri, {required TargetPlatform platform}) => switch (platform) {
  TargetPlatform.android => uri.startsWith('file:///data/'),
  TargetPlatform.iOS => _iosAppContainerPrefixes.any(uri.startsWith),
  _ => false,
};

const _iosAppContainerPrefixes = [
  'file:///var/mobile/Containers/Data/Application/',
  'file:///private/var/mobile/Containers/Data/Application/',
];

/// mpv `demuxer-hysteresis-secs` for an open: half a second for a file mpv
/// reads uncached ([readsUncachedLocalFile]), mpv's default (off) for
/// everything else, and null (leave it alone) when [customMpvConfig] names
/// the option.
///
/// Without it the demuxer thread wakes for every packet the decoders take, to
/// read one more and keep the read-ahead (`demuxer-readahead-secs`, a second
/// for an uncached file) full. With it the thread sleeps until half a second
/// is left and then reads the next half second in one go. The value is
/// absolute, so it stays off wherever mpv caches: there the read-ahead is the
/// cache, which would drain to half a second before every refill. A
/// `cache=yes` line in [customMpvConfig] puts the cache in front of every
/// file, local ones included.
///
/// The custom mpv config is applied when the player is set up, before any
/// open. A line for this option there stays the user's, for every stream, as
/// it was before the app wrote the property at all.
String? demuxerHysteresisSecs({required bool uncachedLocalFile, required Map<String, String> customMpvConfig}) {
  if (customMpvConfig.containsKey('demuxer-hysteresis-secs')) return null;
  final cacheForced = customMpvConfig['cache'] == 'yes';
  return uncachedLocalFile && !cacheForced ? '0.5' : '0';
}

/// QuickTime/MP4 muxer family. Apple capture muxers (iPhone recordings and
/// friends) can store audio packets seconds away from coeval video packets —
/// in bytes, seconds × video byterate — which makes ffmpeg's DTS-ordered
/// reads ping-pong across the file. Over HTTP every ping-pong that escapes
/// mpv's stream ring buffer is a byte seek, and ffmpeg's http layer drops and
/// redials the connection on every seek, collapsing throughput.
const quickTimeFamilyContainers = {'mp4', 'mov', 'm4v', '3gp', '3g2'};

/// Matroska/WebM is normally well-interleaved, but UHD direct-play remuxes can
/// still overrun mpv's tiny 128 KiB default stream ring during normal demuxer
/// read bursts. Only opt in when the server reports a high bitrate so common
/// MKV playback keeps the default memory profile.
const matroskaFamilyContainers = {'mkv', 'matroska', 'webm'};
const _highBitrateMatroskaThresholdKbps = 40 * 1000;

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
  final isQuickTimeFamily = tokens.any(quickTimeFamilyContainers.contains);
  final isMatroskaFamily = tokens.any(matroskaFamilyContainers.contains);
  if (!isQuickTimeFamily && !isMatroskaFamily) return null;

  final cap = max(minStreamRingBytes, min(maxBytes, maxStreamRingBytes));
  if (bitrateKbps == null || bitrateKbps <= 0) {
    return isQuickTimeFamily ? min(unknownBitrateStreamRingBytes, cap) : null;
  }
  if (!isQuickTimeFamily && bitrateKbps < _highBitrateMatroskaThresholdKbps) return null;

  final bytesPerSecond = bitrateKbps * 1000 ~/ 8;
  final ring = nextPowerOfTwo(bytesPerSecond * _streamRingContentSeconds);
  return max(minStreamRingBytes, min(ring, cap));
}
