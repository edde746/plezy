import '../../media/ids.dart';
import '../../media/media_kind.dart';
import '../../models/livetv_channel.dart';
import '../../profiles/profile.dart';
import '../../screens/video_player/live_tv_session_args.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import '../system_shelf_service.dart';

/// A `plezy://` link. The one grammar for every platform: native code
/// forwards the URL unchanged and only this file reads it.
///
/// ```text
/// plezy://open
/// plezy://play?server=<serverId>&id=<itemId>[&mode=next|shuffle]
/// plezy://play?type=movie|show&tmdb=<n>|tvdb=<n>|imdb=tt<n>|plex=<hash>[&mode=next|shuffle]
/// plezy://play?content_id=plezy_<serverId>_<itemId>      (launcher shelf rows)
/// plezy://live?channel=<channel>[&server=<serverId>][&start=beginning|live]
/// plezy://external-player/<result>/<session>?...           (external player return links)
/// ```
///
/// Every link except the external-player return link may add
/// `profile=<profile>`, matched by [resolveLinkProfile]. The app switches to
/// that profile before acting on the link; a protected profile still asks
/// for its PIN.
///
/// Once a link is written onto an NFC tag or into a home automation it is a
/// contract: parameters may be added, never renamed.
sealed class DeepLink {
  const DeepLink({this.profile});

  static const scheme = 'plezy';

  /// The profile the link names, as written in the link.
  final String? profile;

  /// Parses [link], or returns null when it is not a well-formed Plezy link.
  static DeepLink? tryParse(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || uri.scheme != scheme) return null;
    final Map<String, String> params;
    try {
      params = uri.queryParameters;
    } on FormatException {
      return null;
    }
    final profile = _param(params, 'profile');
    return switch (uri.host.toLowerCase()) {
      OpenLink.host => OpenLink(profile: profile),
      PlayLink.host => PlayLink._parse(params, profile),
      LiveLink.host => LiveLink._parse(params, profile),
      ExternalPlayerReturnLink.host => ExternalPlayerReturnLink(uri),
      _ => null,
    };
  }

  /// This link as a URL. Parsing the result yields an equal link.
  Uri toUri();

  Map<String, String> get _profileParam => {'profile': ?profile};

  static Uri _uri(String host, Map<String, String> params) =>
      Uri(scheme: scheme, host: host, queryParameters: params.isEmpty ? null : params);
}

/// `plezy://open`: bring the app forward, as [profile] when the link names one.
final class OpenLink extends DeepLink {
  const OpenLink({super.profile});

  static const host = 'open';

  @override
  Uri toUri() => DeepLink._uri(host, _profileParam);
}

/// How a link to a show or season picks what to play.
enum PlayMode {
  /// The episode the viewer is on: the On Deck/Next Up episode, otherwise
  /// the first episode.
  next,

  /// Every episode of the show in random order.
  shuffle,
}

/// `plezy://play`: play one title.
final class PlayLink extends DeepLink {
  const PlayLink({required this.target, this.mode = PlayMode.next, super.profile});

  static const host = 'play';

  final PlayTarget target;

  /// Used when the target is a show or season; movies and episodes ignore it.
  final PlayMode mode;

  static PlayLink? _parse(Map<String, String> params, String? profile) {
    final mode = switch (_param(params, 'mode')?.toLowerCase()) {
      null || 'next' => PlayMode.next,
      'shuffle' => PlayMode.shuffle,
      _ => null,
    };
    if (mode == null) return null;
    final target = PlayTarget._parse(params);
    if (target == null) return null;
    return PlayLink(target: target, mode: mode, profile: profile);
  }

  @override
  Uri toUri() =>
      DeepLink._uri(host, {...target._params, if (mode != PlayMode.next) 'mode': mode.name, ..._profileParam});
}

/// What a [PlayLink] names.
sealed class PlayTarget {
  const PlayTarget();

  static PlayTarget? _parse(Map<String, String> params) {
    final contentId = _param(params, 'content_id');
    if (contentId != null) {
      final parsed = SystemShelfService.parseContentId(contentId);
      if (parsed == null) return null;
      return ItemPlayTarget(serverId: parsed.$1, itemId: parsed.$2);
    }

    final server = _param(params, 'server');
    final id = _param(params, 'id');
    if (server != null || id != null) {
      // Item ids are per server, so an id means nothing without its server.
      if (server == null || id == null) return null;
      return ItemPlayTarget(serverId: ServerId(server), itemId: id);
    }

    final kind = switch (_param(params, 'type')?.toLowerCase()) {
      'movie' => MediaKind.movie,
      'show' => MediaKind.show,
      _ => null,
    };
    if (kind == null) return null;
    final tmdb = _param(params, 'tmdb');
    final tvdb = _param(params, 'tvdb');
    final imdb = _param(params, 'imdb');
    final plex = _param(params, 'plex');
    if (tmdb != null && !_number.hasMatch(tmdb)) return null;
    if (tvdb != null && !_number.hasMatch(tvdb)) return null;
    if (imdb != null && !_imdbId.hasMatch(imdb)) return null;
    if (plex != null && !_plexHash.hasMatch(plex)) return null;
    final tmdbId = tmdb == null ? null : int.tryParse(tmdb);
    final tvdbId = tvdb == null ? null : int.tryParse(tvdb);
    if ((tmdb != null && tmdbId == null) || (tvdb != null && tvdbId == null)) return null;
    final ids = ExternalIds(tmdb: tmdbId, tvdb: tvdbId, imdb: imdb?.toLowerCase());
    if (!ids.hasCatalogIds && plex == null) return null;
    return CatalogPlayTarget(kind: kind, ids: ids, plexHash: plex);
  }

  Map<String, String> get _params;
}

/// One item on one server, of any backend.
final class ItemPlayTarget extends PlayTarget {
  const ItemPlayTarget({required this.serverId, required this.itemId});

  final ServerId serverId;
  final String itemId;

  @override
  Map<String, String> get _params => {'server': serverId, 'id': itemId};

  @override
  bool operator ==(Object other) => other is ItemPlayTarget && other.serverId == serverId && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(serverId, itemId);
}

/// A movie or show by catalogue identity: every copy on every server of
/// every backend that knows one of the ids.
final class CatalogPlayTarget extends PlayTarget {
  const CatalogPlayTarget({required this.kind, this.ids = const ExternalIds(), this.plexHash})
    : assert(kind == MediaKind.movie || kind == MediaKind.show);

  /// [MediaKind.movie] or [MediaKind.show].
  final MediaKind kind;
  final ExternalIds ids;

  /// The Plex GUID after `plex://movie/` or `plex://show/`. Only Plex
  /// servers can match it.
  final String? plexHash;

  /// The full Plex GUID, or null when the link has none.
  String? get plexGuid => plexHash == null ? null : 'plex://${kind.id}/$plexHash';

  @override
  Map<String, String> get _params => {
    'type': kind.id,
    if (ids.tmdb case final tmdb?) 'tmdb': '$tmdb',
    if (ids.tvdb case final tvdb?) 'tvdb': '$tvdb',
    'imdb': ?ids.imdb,
    'plex': ?plexHash,
  };

  @override
  bool operator ==(Object other) =>
      other is CatalogPlayTarget &&
      other.kind == kind &&
      other.ids.tmdb == ids.tmdb &&
      other.ids.tvdb == ids.tvdb &&
      other.ids.imdb == ids.imdb &&
      other.plexHash == plexHash;

  @override
  int get hashCode => Object.hash(kind, ids.tmdb, ids.tvdb, ids.imdb, plexHash);
}

/// `plezy://live`: tune a live TV channel.
final class LiveLink extends DeepLink {
  const LiveLink({required this.channel, this.serverId, this.startPosition = LiveTvStartPosition.ask, super.profile});

  static const host = 'live';

  /// Matched against the channel key, identifier, number and call sign, in
  /// that order; see [selectChannel].
  final String channel;

  /// Restricts the lookup to one server. Without it every Live TV server is
  /// searched.
  final ServerId? serverId;

  /// Answers the "watch from start" prompt shown when the channel is being
  /// recorded; [LiveTvStartPosition.ask] shows the prompt.
  final LiveTvStartPosition startPosition;

  static LiveLink? _parse(Map<String, String> params, String? profile) {
    final channel = _param(params, 'channel');
    if (channel == null) return null;
    final start = switch (_param(params, 'start')?.toLowerCase()) {
      null => LiveTvStartPosition.ask,
      'beginning' || 'start' => LiveTvStartPosition.beginning,
      'live' || 'now' => LiveTvStartPosition.live,
      _ => null,
    };
    if (start == null) return null;
    return LiveLink(
      channel: channel,
      serverId: serverIdOrNull(_param(params, 'server')),
      startPosition: start,
      profile: profile,
    );
  }

  /// The channel this link names in [channels]: the first rule that matches
  /// exactly one channel wins. Null when nothing matches or a rule matches
  /// several channels.
  LiveTvChannel? selectChannel(List<LiveTvChannel> channels) {
    final wanted = channel.toLowerCase();
    final rules = <bool Function(LiveTvChannel)>[
      (c) => c.key == channel,
      (c) => c.identifier == channel,
      (c) => c.number == channel,
      (c) => c.callSign?.toLowerCase() == wanted,
    ];
    for (final rule in rules) {
      final matches = channels.where(rule).toList(growable: false);
      if (matches.length == 1) return matches.single;
      if (matches.length > 1) {
        appLogger.w('Live link: channel "$channel" is ambiguous (${matches.length} matches)');
        return null;
      }
    }
    return null;
  }

  @override
  Uri toUri() => DeepLink._uri(host, {
    'channel': channel,
    'server': ?serverId,
    ...switch (startPosition) {
      LiveTvStartPosition.ask => const <String, String>{},
      LiveTvStartPosition.beginning => const {'start': 'beginning'},
      LiveTvStartPosition.live => const {'start': 'live'},
    },
    ..._profileParam,
  });
}

/// `plezy://external-player/<result>/<session>`: an external player handing
/// control back to Plezy (x-callback-url). The player appends its own query
/// parameters, so the whole [uri] is kept for `ExternalPlayerService`.
final class ExternalPlayerReturnLink extends DeepLink {
  const ExternalPlayerReturnLink(this.uri);

  static const host = 'external-player';

  final Uri uri;

  @override
  Uri toUri() => uri;
}

/// The profile [ref] names: a profile id, else the one Plex Home user with
/// that UUID, else the one profile with that display name (ignoring case).
/// Null when nothing matches or a rule matches several profiles.
Profile? resolveLinkProfile(List<Profile> profiles, String ref) {
  for (final profile in profiles) {
    if (profile.id == ref) return profile;
  }
  final wanted = ref.trim().toLowerCase();
  final rules = <bool Function(Profile)>[
    (p) => p.plexHomeUserUuid?.toLowerCase() == wanted,
    (p) => p.displayName.trim().toLowerCase() == wanted,
  ];
  for (final rule in rules) {
    final matches = profiles.where(rule).toList(growable: false);
    if (matches.length == 1) return matches.single;
    if (matches.length > 1) {
      appLogger.w('Deep link: profile "$ref" is ambiguous (${matches.length} matches)');
      return null;
    }
  }
  return null;
}

/// The `profile` value a generated link uses for [profile]: the Plex Home
/// user UUID, which survives signing the account in again, else the
/// profile id.
String linkProfileRef(Profile profile) => profile.plexHomeUserUuid ?? profile.id;

final _number = RegExp(r'^\d+$');
final _imdbId = RegExp(r'^tt\d+$', caseSensitive: false);
final _plexHash = RegExp(r'^[0-9a-zA-Z]+$');

/// The trimmed value of [name], or null when absent or blank.
String? _param(Map<String, String> params, String name) {
  final value = params[name]?.trim();
  return value == null || value.isEmpty ? null : value;
}
