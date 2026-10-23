import 'package:openwatchparty/openwatchparty.dart' as owp;

import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../media/media_version.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import '../models/watch_copy.dart';

/// Plezy's `ext` member (SPEC.md §10): reverse-DNS, owned by Plezy. It names
/// the server, item and version the host shared, so a guest who reaches the
/// same server opens that exact file. Other apps ignore it.
const String plezyExtName = 'app.plezy';

/// How a Plezy item is described to a room. Movies and episodes carry their
/// catalogue identity and match on any server and in any OWP app; every other
/// video (Plex clips, home videos, Jellyfin/Emby `Video` items) goes out as a
/// `video` without IDs, which only participants on the same server, or with a
/// file of the same size and name, find.
owp.MediaKind roomKindOf(MediaKind kind) => switch (kind) {
  MediaKind.movie => owp.MediaKind.movie,
  MediaKind.episode => owp.MediaKind.episode,
  _ => owp.MediaKind.video,
};

/// Why a file could not be described for a room.
enum DescribeFailure {
  /// Neither the server nor the player knows the file's length.
  noDuration,

  /// The descriptor breaks a rule the relay checks (logged).
  invalid,
}

/// Builds the media descriptor (SPEC.md §10) for [copy] from its item, the
/// catalogue IDs [client] knows for it and its show, and the version's length
/// ([playerDurationMs] when the server reports none).
///
/// Lookups that fail leave their part out: a movie the server can't map stays
/// a `movie` without IDs. Returns the descriptor or the reason there is none.
Future<({owp.Media? media, DescribeFailure? failure})> describeCopy(
  WatchCopy copy, {
  required MediaServerClient client,
  int? playerDurationMs,
}) async {
  final item = copy.item!;
  final durationMs = copy.durationMs ?? (playerDurationMs != null && playerDurationMs > 0 ? playerDurationMs : null);
  if (durationMs == null) return (media: null, failure: DescribeFailure.noDuration);

  final kind = roomKindOf(item.kind);
  final ids = kind == owp.MediaKind.video ? const <String, String>{} : await _idsOf(client, item.id, guid: item.guid);
  owp.Series? series;
  if (kind == owp.MediaKind.episode) series = await _seriesOf(client, item);

  final ext = <String, Object?>{
    plezyExtName: {
      'server': copy.serverId,
      'item': copy.itemId,
      if (copy.versionId.isNotEmpty) 'version': copy.versionId,
    },
  };
  final file = _fileHints(copy.version);
  var media = owp.Media(
    kind: kind,
    title: _titleOf(item),
    year: kind == owp.MediaKind.episode ? null : item.year,
    ids: ids,
    series: series,
    season: kind == owp.MediaKind.episode ? _number(item.parentIndex) : null,
    episode: kind == owp.MediaKind.episode ? _number(item.index) : null,
    durationMs: durationMs,
    file: file,
    ext: ext,
  );
  var problem = owp.checkMedia(media);
  if (problem != null && file?.name != null) {
    // A file name the relay refuses is only a hint: send the rest.
    media = _withFile(media, file!.sizeBytes == null ? null : owp.MediaFile(sizeBytes: file.sizeBytes));
    problem = owp.checkMedia(media);
  }
  if (problem != null) {
    appLogger.w('WatchTogether: ${copy.serverId}:${copy.itemId} has no valid descriptor: $problem');
    return (media: null, failure: DescribeFailure.invalid);
  }
  return (media: media, failure: null);
}

/// [text] as protocol text (SPEC.md §2): line breaks and tabs become spaces,
/// other control and bidi-control characters (direction marks are common in
/// Hebrew and Arabic titles) and unpaired surrogates are dropped, and runs of
/// spaces fold. Null when nothing is left.
String? descriptorText(String? text) {
  if (text == null) return null;
  final out = StringBuffer();
  var space = false;
  for (final rune in text.runes) {
    final blank = rune == 0x09 || rune == 0x0A || rune == 0x0B || rune == 0x0C || rune == 0x0D || rune == 0x20;
    if (blank) {
      space = out.isNotEmpty;
      continue;
    }
    if (_forbidden(rune)) continue;
    if (space) out.write(' ');
    space = false;
    out.writeCharCode(rune);
  }
  final result = out.toString();
  return result.isEmpty ? null : result;
}

bool _forbidden(int rune) =>
    rune <= 0x1F ||
    (rune >= 0x7F && rune <= 0x9F) ||
    rune == 0x061C ||
    rune == 0x200E ||
    rune == 0x200F ||
    (rune >= 0x202A && rune <= 0x202E) ||
    (rune >= 0x2066 && rune <= 0x2069) ||
    (rune >= 0xD800 && rune <= 0xDFFF);

String _titleOf(MediaItem item) {
  final title = descriptorText(item.title);
  if (title != null) return title;
  if (item.kind == MediaKind.episode && item.index != null) return t.watchTogether.untitledEpisode(number: item.index!);
  return descriptorText(item.displayTitle) ?? t.common.unknown;
}

int? _number(int? value) => value != null && value >= 0 ? value : null;

Future<owp.Series> _seriesOf(MediaServerClient client, MediaItem episode) async {
  final showId = episode.grandparentId;
  final title = descriptorText(episode.grandparentTitle);
  MediaItem? show;
  if (showId != null && showId.isNotEmpty) {
    try {
      show = await client.fetchItem(showId);
    } catch (error, stackTrace) {
      appLogger.w('WatchTogether: could not read show $showId', error: error, stackTrace: stackTrace);
    }
  }
  final ids = showId == null || showId.isEmpty
      ? const <String, String>{}
      : await _idsOf(client, showId, guid: show?.guid);
  final showTitle = title ?? descriptorText(show?.title) ?? t.common.unknown;
  return owp.Series(title: showTitle, year: show?.year, ids: ids);
}

/// The catalogue IDs [client] maps [itemId] to, as descriptor `ids`, plus a
/// Plex `plex://` GUID when [guid] is one. Empty when the lookup fails.
Future<Map<String, String>> _idsOf(MediaServerClient client, String itemId, {String? guid}) async {
  ExternalIds external;
  try {
    external = await client.fetchExternalIds(itemId);
  } catch (error, stackTrace) {
    appLogger.w('WatchTogether: no external IDs for $itemId', error: error, stackTrace: stackTrace);
    external = const ExternalIds();
  }
  return descriptorIds(external, plexGuid: guid);
}

/// [ids] in the descriptor's namespaces (SPEC.md §10): every value a string.
Map<String, String> descriptorIds(ExternalIds ids, {String? plexGuid}) => {
  if (ids.imdb case final imdb? when imdb.isNotEmpty) 'imdb': imdb,
  if (ids.tmdb case final tmdb?) 'tmdb': '$tmdb',
  if (ids.tvdb case final tvdb?) 'tvdb': '$tvdb',
  if (ids.anidb case final anidb?) 'anidb': '$anidb',
  if (plexGuid != null && plexGuid.startsWith('plex://')) 'plex': plexGuid,
};

/// File hints for [version]: its total size, and its file name when it is one
/// file. Null when neither is known.
owp.MediaFile? _fileHints(MediaVersion? version) {
  final parts = version?.parts ?? const [];
  if (parts.isEmpty) return null;
  final sizes = parts.map((part) => part.sizeBytes).toList();
  final sizeBytes = sizes.every((size) => size != null && size >= 0) ? sizes.fold<int>(0, (a, b) => a + b!) : null;
  final name = parts.length == 1 ? fileBaseName(parts.single.file) : null;
  if (sizeBytes == null && name == null) return null;
  return owp.MediaFile(sizeBytes: sizeBytes, name: name);
}

/// The last segment of a server-side [path], whichever separator it uses.
String? fileBaseName(String? path) {
  if (path == null) return null;
  final name = path.split(RegExp(r'[/\\]')).last.trim();
  return name.isEmpty || name == '.' || name == '..' ? null : name;
}

owp.Media _withFile(owp.Media media, owp.MediaFile? file) => owp.Media(
  kind: media.kind,
  title: media.title,
  year: media.year,
  ids: media.ids,
  series: media.series,
  season: media.season,
  episode: media.episode,
  durationMs: media.durationMs,
  file: file,
  ext: media.ext,
);

/// The `app.plezy` member of a received descriptor, when it is Plezy's shape.
/// Untrusted (SDK.md §9.7): only ever used to look up this user's own servers.
({String server, String item, String? version})? plezyExt(owp.Media media) {
  final member = media.ext?[plezyExtName];
  if (member is! Map) return null;
  final server = member['server'];
  final item = member['item'];
  final version = member['version'];
  if (server is! String || server.isEmpty || item is! String || item.isEmpty) return null;
  return (server: server, item: item, version: version is String && version.isNotEmpty ? version : null);
}
