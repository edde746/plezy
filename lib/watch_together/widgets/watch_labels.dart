import 'package:openwatchparty/openwatchparty.dart' as owp;

import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../media/media_item_labels.dart';
import '../../media/media_version.dart';
import '../../utils/formatters.dart';
import '../models/watch_copy.dart';
import '../models/watch_notice.dart';

/// The user's text for an SDK or relay error [code] (an [owp.ErrorCode]).
/// Codes this app doesn't know get the generic text; the SDK's message never
/// reaches users.
String watchErrorText(String code) => switch (code) {
  owp.ErrorCode.invalidCode => t.watchTogether.errors.invalidCode,
  owp.ErrorCode.roomNotFound => t.watchTogether.errors.roomNotFound,
  owp.ErrorCode.roomFull => t.watchTogether.errors.roomFull,
  owp.ErrorCode.roomLocked => t.watchTogether.errors.roomLocked,
  owp.ErrorCode.relayFull => t.watchTogether.errors.relayFull,
  owp.ErrorCode.unreachable => t.watchTogether.errors.unreachable,
  owp.ErrorCode.rateLimited => t.watchTogether.errors.rateLimited,
  owp.ErrorCode.clientBlocked => t.watchTogether.errors.clientBlocked,
  owp.ErrorCode.forbidden => t.watchTogether.errors.forbidden,
  owp.ErrorCode.notInRoom => t.watchTogether.errors.notInRoom,
  owp.ErrorCode.alreadyInRoom => t.watchTogether.errors.alreadyInRoom,
  owp.ErrorCode.resumeFailed => t.watchTogether.errors.resumeFailed,
  owp.ErrorCode.unsupported => t.watchTogether.errors.unsupported,
  _ => t.watchTogether.errors.generic,
};

/// Why the room ended for this user; null for their own leave.
String? watchEndReasonText(owp.EndReason reason) => switch (reason) {
  owp.EndReason.left => null,
  owp.EndReason.ended => t.watchTogether.ended.ended,
  owp.EndReason.kicked => t.watchTogether.ended.kicked,
  owp.EndReason.expired => t.watchTogether.ended.expired,
  owp.EndReason.replaced => t.watchTogether.ended.replaced,
  owp.EndReason.lost => t.watchTogether.ended.lost,
};

/// The snackbar text for [notice], or null when it shows nothing (an action
/// this app doesn't describe, a host change without a host).
///
/// [media], [host] and [myPeerId] are the room as the notice arrives: a
/// `media` action names the new media, a `host` action the new host.
String? watchNoticeText(WatchNotice notice, {owp.Media? media, owp.Participant? host, String? myPeerId}) {
  final notices = t.watchTogether.notices;
  return switch (notice) {
    ActionNotice(:final kind, :final name, :final positionMs, :final rate) => switch (kind) {
      'play' => name == null ? notices.playbackStarted : notices.pressedPlay(name: name),
      'pause' => name == null ? notices.playbackPaused : notices.paused(name: name),
      'seek' when positionMs != null => _seekText(name, formatDurationTimestamp(Duration(milliseconds: positionMs))),
      'rate' when rate != null => _rateText(name, formatPlaybackRate(rate)),
      'media' => _mediaText(name, media),
      'stall' => name == null ? notices.waitingForSomeone : notices.waitingFor(name: name),
      'ended' => notices.finished,
      'host' when host != null =>
        host.peerId == myPeerId ? notices.youAreNowHost : notices.hostChangedTo(name: host.name),
      _ => null,
    },
    JoinedNotice(:final name) => notices.joined(name: name),
    LeftNotice(:final name) => notices.left(name: name),
    RefusedNotice(:final code) => watchErrorText(code),
    ControlRefusedNotice() => notices.controlRefused,
    SearchFailedNotice() => notices.searchFailed,
    PlayBlockedNotice() => notices.playBlocked,
    EndedNotice(:final reason) => watchEndReasonText(reason),
    ShareFailedNotice() => notices.shareFailed,
    NotSharedNotice() => notices.downloadNotShared,
    OpenFailedNotice() => notices.openFailed,
  };
}

String _seekText(String? name, String position) => name == null
    ? t.watchTogether.notices.roomJumpedTo(position: position)
    : t.watchTogether.notices.jumpedTo(name: name, position: position);

String _rateText(String? name, String speed) => name == null
    ? t.watchTogether.notices.speedChanged(speed: speed)
    : t.watchTogether.notices.changedSpeed(name: name, speed: speed);

String _mediaText(String? name, owp.Media? media) {
  final notices = t.watchTogether.notices;
  if (media == null) return name == null ? notices.mediaStopped : notices.stoppedMedia(name: name);
  final title = watchMediaTitle(media);
  return name == null ? notices.mediaStarted(title: title) : notices.startedMedia(name: name, title: title);
}

/// The room's media in one line: a movie with its year, an episode as series,
/// season/episode and title.
String watchMediaTitle(owp.Media media) {
  switch (media.kind) {
    case owp.MediaKind.episode:
      return toBulletedString([
        ?media.series?.title,
        ?formatSeasonEpisodeLabel(media.season, media.episode),
        if (media.title != media.series?.title) media.title,
      ]);
    case owp.MediaKind.movie:
      return media.year == null ? media.title : '${media.title} (${media.year})';
    case owp.MediaKind.video:
      return media.title;
  }
}

/// A copy's item in one line: title, and series and season/episode for an
/// episode.
String watchCopyTitle(WatchCopy copy) {
  final item = copy.item;
  if (item == null) return t.common.unknown;
  return formatMediaTargetLabel(item);
}

/// The copy's version as its technical label, with the server and length:
/// "1080p H.264 MKV (8.5 Mbps) · Home server · 2h 1m".
String watchCopyDetails(WatchCopy copy) {
  final duration = copy.durationMs;
  return toBulletedString([
    ?watchVersionLabel(copy.item, copy.version),
    ?copy.item?.serverName,
    if (duration != null && duration > 0) formatDurationTextual(duration),
  ]);
}

/// [version]'s label without a name that only restates [item]'s title (with
/// or without its year): Plex and Jellyfin often name a movie's only version
/// after the movie. Null without a version or when nothing else is left.
String? watchVersionLabel(MediaItem? item, MediaVersion? version) {
  if (version == null) return null;
  final label = version.displayLabel;
  final name = version.name;
  if (name == null || name.isEmpty || !_restatesTitle(name, item)) return label;
  final prefix = '$name · ';
  return label.startsWith(prefix) ? label.substring(prefix.length) : null;
}

bool _restatesTitle(String name, MediaItem? item) {
  final title = item?.title;
  if (title == null || title.isEmpty) return false;
  final nameWords = _words(name);
  final titleWords = _words(title);
  if (_sameWords(nameWords, titleWords)) return true;
  final year = item?.year;
  return year != null && _sameWords(nameWords, [...titleWords, '$year']);
}

final _wordPattern = RegExp(r'[\p{L}\p{N}]+', unicode: true);

List<String> _words(String text) => [for (final match in _wordPattern.allMatches(text.toLowerCase())) match[0]!];

bool _sameWords(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// How a file's length compares with the room's: "2m longer", "Same length".
String watchLengthDifference(int? deltaMs) {
  if (deltaMs == null) return t.watchTogether.lengthUnknown;
  final magnitude = deltaMs.abs();
  if (magnitude < 1000) return t.watchTogether.lengthSame;
  final duration = formatDurationTextual(magnitude);
  return deltaMs > 0
      ? t.watchTogether.lengthLonger(duration: duration)
      : t.watchTogether.lengthShorter(duration: duration);
}

/// The app part of a participant's `client` ("Plezy/2.23.0" -> "Plezy").
String watchClientApp(String client) {
  final slash = client.indexOf('/');
  return slash < 0 ? client : client.substring(0, slash);
}

String watchPlayerStateText(owp.PlayerState state) => switch (state) {
  owp.PlayerState.idle => t.watchTogether.playerIdle,
  owp.PlayerState.loading => t.watchTogether.playerLoading,
  owp.PlayerState.ready => t.watchTogether.playerReady,
  owp.PlayerState.buffering => t.watchTogether.playerBuffering,
};

String watchMatchStateText(owp.MatchState state) => switch (state) {
  owp.MatchState.searching => t.watchTogether.matchSearching,
  owp.MatchState.matched => t.watchTogether.matchMatched,
  owp.MatchState.mismatched => t.watchTogether.matchMismatched,
  owp.MatchState.unavailable => t.watchTogether.matchUnavailable,
};

/// A sync offset as the offset controls show it: "+200ms", "-1.5s".
String watchOffsetText(int offsetMs) => formatSyncOffset(offsetMs.toDouble());
