import '../trackers/tracker_account_store.dart';
import 'trakt_session.dart';

/// Per-Plex-profile persistence of Trakt OAuth sessions.
final TrackerAccountStore<TraktSession> traktAccountStore = TrackerAccountStore<TraktSession>(
  baseKey: 'trakt_session',
  decode: TraktSession.decode,
  encode: (s) => s.encode(),
);
