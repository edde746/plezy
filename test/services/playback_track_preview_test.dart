import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_server_user_profile.dart';
import 'package:plezy/media/media_stream.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/playback_track_preview.dart';

class _JapaneseAudioProfile implements MediaServerUserProfile {
  @override
  bool get autoSelectAudio => true;
  @override
  String? get defaultAudioLanguage => 'jpn';
  @override
  String? get defaultSubtitleLanguage => null;
  @override
  SubtitlePlaybackMode? get subtitleMode => null;
}

void main() {
  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  const english = MediaStream(
    id: '101',
    kind: MediaStreamKind.audio,
    index: 1,
    codec: 'truehd',
    language: 'English',
    languageCode: 'eng',
    channels: 8,
    selected: true,
  );
  const japanese = MediaStream(
    id: '102',
    kind: MediaStreamKind.audio,
    index: 2,
    codec: 'aac',
    language: 'Japanese',
    languageCode: 'jpn',
    channels: 2,
  );
  const englishForced = MediaStream(
    id: '201',
    kind: MediaStreamKind.subtitle,
    index: 3,
    codec: 'srt',
    language: 'English',
    languageCode: 'eng',
    forced: true,
  );
  const englishFull = MediaStream(
    id: '202',
    kind: MediaStreamKind.subtitle,
    index: 4,
    codec: 'ass',
    language: 'English',
    languageCode: 'eng',
    title: 'Full',
  );

  MediaItem plexEpisode(List<MediaStream> streams) => MediaItem.plex(
    id: 'episode_1',
    kind: MediaKind.episode,
    title: 'Pilot',
    mediaVersions: [
      MediaVersion(
        id: 'v1',
        videoResolution: '1080',
        videoCodec: 'hevc',
        parts: [MediaPart(id: 'p1', streams: streams)],
      ),
    ],
  );

  test('follows the server-selected audio and keeps subtitles off when Plex selected none', () {
    final preview = previewPlaybackTracks(plexEpisode([english, japanese, englishForced, englishFull]))!;

    expect(preview.audio?.id, 101);
    expect(preview.audio?.label.joined, 'English · TrueHD · 7.1');
    expect(preview.subtitle, isNull);
    expect(preview.source.subtitleTracks.map((row) => row.id), [201, 202]);
  });

  test('a Plex-selected subtitle row is the prediction', () {
    const selectedFull = MediaStream(
      id: '202',
      kind: MediaStreamKind.subtitle,
      index: 4,
      codec: 'ass',
      language: 'English',
      languageCode: 'eng',
      title: 'Full',
      selected: true,
    );
    final preview = previewPlaybackTracks(plexEpisode([english, japanese, englishForced, selectedFull]))!;

    expect(preview.subtitle?.id, 202);
  });

  test('the server pick outranks the container default, which outranks the first row', () {
    const defaultJapanese = MediaStream(
      id: '102',
      kind: MediaStreamKind.audio,
      index: 2,
      codec: 'opus',
      languageCode: 'jpn',
      channels: 2,
      isDefault: true,
    );
    const selectedEnglish = MediaStream(
      id: '101',
      kind: MediaStreamKind.audio,
      index: 1,
      codec: 'opus',
      languageCode: 'eng',
      channels: 6,
      selected: true,
    );
    const plainEnglish = MediaStream(
      id: '101',
      kind: MediaStreamKind.audio,
      index: 1,
      codec: 'opus',
      languageCode: 'eng',
      channels: 6,
    );

    // Plex: the account's pick (English) wins although Japanese is the
    // container default — what the player's server-selected tier does.
    expect(previewPlaybackTracks(plexEpisode([selectedEnglish, defaultJapanese]))!.audio?.id, 101);
    // No pick: the container default wins over row order.
    expect(previewPlaybackTracks(plexEpisode([plainEnglish, defaultJapanese]))!.audio?.id, 102);
  });

  test('an explicit choice outranks the server selection and comes back as the picked rows', () {
    final item = plexEpisode([english, japanese, englishForced, englishFull]);
    final baseline = previewPlaybackTracks(item)!;
    final chooseJapanese = PlaybackTrackChoice(
      itemId: item.id,
      audio: const AudioTrack(id: 'source:102', language: 'jpn', codec: 'aac', channels: 2),
      subtitle: const SubtitleTrack(id: 'source:202', language: 'eng', codec: 'ass', title: 'Full'),
    );

    final preview = previewPlaybackTracks(item, choice: chooseJapanese)!;

    expect(baseline.audio?.id, 101);
    expect(preview.audio?.id, 102);
    expect(preview.subtitle?.id, 202);
    // The descriptors Play hands over point at exactly those rows.
    expect(preview.audioTrack?.id, 'source:102');
    expect(preview.subtitleTrack.id, 'source:202');

    // Off is a choice too, and wins over a server-selected row.
    final offPreview = previewPlaybackTracks(
      item,
      choice: PlaybackTrackChoice(itemId: item.id, subtitle: SubtitleTrack.off),
    )!;
    expect(offPreview.subtitle, isNull);
    expect(offPreview.subtitleTrack, SubtitleTrack.off);
  });

  test('a choice made on another episode carries its semantics, forced-ness included', () {
    // Same show, next episode: different stream ids, same track layout.
    const nextEnglish = MediaStream(
      id: '301',
      kind: MediaStreamKind.audio,
      index: 1,
      codec: 'truehd',
      languageCode: 'eng',
      channels: 8,
      selected: true,
    );
    const nextJapanese = MediaStream(
      id: '302',
      kind: MediaStreamKind.audio,
      index: 2,
      codec: 'aac',
      languageCode: 'jpn',
      channels: 2,
    );
    const nextForced = MediaStream(
      id: '401',
      kind: MediaStreamKind.subtitle,
      index: 3,
      codec: 'srt',
      languageCode: 'eng',
      forced: true,
    );
    const nextFull = MediaStream(
      id: '402',
      kind: MediaStreamKind.subtitle,
      index: 4,
      codec: 'ass',
      languageCode: 'eng',
    );
    // What the chooser stored on episode 1: Japanese audio, the forced track.
    final carried = PlaybackTrackChoice(
      itemId: 'episode_1',
      audio: const AudioTrack(id: 'source:102', language: 'jpn', codec: 'aac', channels: 2),
      subtitle: const SubtitleTrack(id: 'source:201', language: 'eng', codec: 'srt', isForced: true),
    );
    final nextEpisode = MediaItem.plex(
      id: 'episode_2',
      kind: MediaKind.episode,
      title: 'Next',
      mediaVersions: const [
        MediaVersion(
          id: 'v2',
          parts: [
            MediaPart(id: 'p2', streams: [nextEnglish, nextJapanese, nextForced, nextFull]),
          ],
        ),
      ],
    );

    final preview = previewPlaybackTracks(nextEpisode, choice: carried)!;

    expect(preview.audio?.id, 302);
    // Not the first English row (402): the forced class is a hard requirement.
    expect(preview.subtitle?.id, 401);
    expect(preview.subtitleTrack.id, 'source:401');
  });

  test('profile language preference applies when the server selected nothing', () {
    const unselectedEnglish = MediaStream(
      id: '101',
      kind: MediaStreamKind.audio,
      index: 1,
      codec: 'truehd',
      languageCode: 'eng',
      channels: 8,
    );
    final preview = previewPlaybackTracks(
      plexEpisode([unselectedEnglish, japanese]),
      profile: _JapaneseAudioProfile(),
    )!;

    expect(preview.audio?.id, 102);
  });

  test('a container summary without stream rows yields no preview', () {
    // What a Plex listing carries when it only knows `Media.audioCodec`.
    const synthetic = MediaStream(
      id: '55:audio',
      kind: MediaStreamKind.audio,
      codec: 'aac',
      channels: 2,
      selected: true,
    );

    expect(previewPlaybackTracks(plexEpisode([synthetic])), isNull);
    expect(previewPlaybackTracks(const MediaItem.plex(id: 'bare', kind: MediaKind.movie, title: 'Bare')), isNull);
  });
}
