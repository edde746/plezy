import '../tracker_account_store.dart';
import 'anilist_session.dart';

final TrackerAccountStore<AnilistSession> anilistAccountStore = TrackerAccountStore<AnilistSession>(
  baseKey: 'anilist_session',
  decode: AnilistSession.decode,
  encode: (s) => s.encode(),
);
