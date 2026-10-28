import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/media/playback_copy_ranking.dart';
import 'package:plezy/models/transcode_quality_preset.dart';

import '../test_helpers/media_items.dart';

void main() {
  const hd = MediaVersion(id: 'hd', height: 1080, videoCodec: 'h264', bitrate: 6000);
  const uhd = MediaVersion(id: 'uhd', height: 2160, videoCodec: 'hevc', bitrate: 18000);
  final available = testMediaItem(id: 'hd', serverId: 'online', mediaVersions: [hd]);
  final remote = testMediaItem(id: '4k', serverId: 'offline', mediaVersions: [uhd]);

  test('a reachable complete copy outranks an unreachable higher resolution', () {
    final ranked = rankPlaybackCopies([remote, available], onlineServerIds: {'online'});
    expect(ranked.first.item, same(available));
    expect(ranked.last.reason, PlaybackCopyReason.unavailable);
  });

  test('verified offline availability survives an unreachable server', () {
    final ranked = rankPlaybackCopies(
      [available, remote],
      onlineServerIds: {'online'},
      verifiedOfflineKeys: {remote.globalKey},
    );
    expect(ranked.first.item, same(remote));
    expect(ranked.first.reason, PlaybackCopyReason.offline);
  });

  test('known decoder limitations select a usable encoding without hiding alternatives', () {
    final hevc = testMediaItem(id: 'hevc', serverId: 'online', mediaVersions: [uhd]);
    final ranked = rankPlaybackCopies([hevc, available], onlineServerIds: {'online'}, refusedVideoCodecs: {'hevc'});
    expect(ranked.first.item, same(available));
    expect(ranked.last.reason, PlaybackCopyReason.decodeFallback);
    final multi = testMediaItem(id: 'multi', serverId: 'online', mediaVersions: [uhd, hd]);
    expect(
      rankPlaybackCopies([multi], onlineServerIds: {'online'}, refusedVideoCodecs: {'hevc'}).single.version,
      same(hd),
    );
    expect(multi.mediaVersions!.first, same(uhd));
  });

  test('quality limits consider resolution as well as bitrate', () {
    const compact4k = MediaVersion(id: '4k', height: 2160, videoCodec: 'h264', bitrate: 4000);
    final over = testMediaItem(id: '4k', serverId: 'online', mediaVersions: [compact4k]);
    final ranked = rankPlaybackCopies(
      [over, available],
      onlineServerIds: {'online'},
      quality: TranscodeQualityPreset.p1080_8mbps,
    );
    expect(ranked.first.item, same(available));
    expect(ranked.last.reason, PlaybackCopyReason.qualityLimit);
  });

  test('per-server startup limits can differ between local and remote copies', () {
    final local = testMediaItem(id: 'local-4k', serverId: 'lan', mediaVersions: [uhd]);
    final remote = testMediaItem(id: 'remote-4k', serverId: 'wan', mediaVersions: [uhd]);
    final ranked = rankPlaybackCopies(
      [remote, local],
      onlineServerIds: {'lan', 'wan'},
      qualityForItem: (item) =>
          item.serverId == 'wan' ? TranscodeQualityPreset.p1080_8mbps : TranscodeQualityPreset.original,
    );
    expect(ranked.first.item, same(local));
    expect(ranked.last.reason, PlaybackCopyReason.qualityLimit);
  });

  test('a missing second part cannot win on resolution', () {
    final broken = testMediaItem(
      id: 'broken',
      serverId: 'online',
      mediaVersions: const [
        MediaVersion(
          id: 'split',
          height: 2160,
          parts: [
            MediaPart(id: 'one'),
            MediaPart(id: 'two', exists: false),
          ],
        ),
      ],
    );
    final ranked = rankPlaybackCopies([broken, available], onlineServerIds: {'online'});
    expect(ranked.first.item, same(available));
    expect(ranked.last.reason, PlaybackCopyReason.missingParts);
  });

  test('unknown version metadata remains available and ordering is deterministic', () {
    final unknown = testMediaItem(id: 'unknown', serverId: 'online');
    final first = rankPlaybackCopies([unknown, available], onlineServerIds: {'online'});
    final second = rankPlaybackCopies([available, unknown], onlineServerIds: {'online'});
    expect(first.map((rank) => rank.item.globalKey), second.map((rank) => rank.item.globalKey));
    expect(first.last.reason, PlaybackCopyReason.unknown);
  });
}
