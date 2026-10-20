import 'package:openwatchparty/openwatchparty.dart' as owp;

/// Something that happened in the room, for a snackbar or toast. The UI words
/// each one; [owp.PartyException.message] never reaches users.
sealed class WatchNotice {
  const WatchNotice();
}

/// Another participant played, paused, seeked, changed the rate or media, or
/// the relay reported a stall or the media's end. [kind] is the SDK's action
/// kind; [name] is null for the relay or a participant who left.
class ActionNotice extends WatchNotice {
  const ActionNotice({required this.kind, this.name, this.positionMs, this.rate});

  final String kind;
  final String? name;

  /// For `seek`: where in this user's own file the room went.
  final int? positionMs;

  /// For `rate`: the new rate.
  final double? rate;
}

class JoinedNotice extends WatchNotice {
  const JoinedNotice(this.name);
  final String name;
}

class LeftNotice extends WatchNotice {
  const LeftNotice(this.name);
  final String name;
}

/// The relay or the SDK refused a command; [code] is an [owp.ErrorCode].
class RefusedNotice extends WatchNotice {
  const RefusedNotice(this.code);
  final String code;
}

/// A press this user may not make: the host controls playback.
class ControlRefusedNotice extends WatchNotice {
  const ControlRefusedNotice();
}

/// The library search for the room's media failed on some server.
class SearchFailedNotice extends WatchNotice {
  const SearchFailedNotice();
}

/// The player refused to start; the user has to press play on it.
class PlayBlockedNotice extends WatchNotice {
  const PlayBlockedNotice();
}

/// The room ended for this user, other than by leaving.
class EndedNotice extends WatchNotice {
  const EndedNotice(this.reason);
  final owp.EndReason reason;
}

/// The host's file could not be shared with the room.
class ShareFailedNotice extends WatchNotice {
  const ShareFailedNotice();
}

/// The host plays a file the room can't get (a download).
class NotSharedNotice extends WatchNotice {
  const NotSharedNotice();
}

/// The room's file could not be opened.
class OpenFailedNotice extends WatchNotice {
  const OpenFailedNotice();
}
