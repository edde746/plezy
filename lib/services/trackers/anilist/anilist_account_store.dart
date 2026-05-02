import '../tracker_account_store.dart';
import 'anilist_session.dart';

final TrackerAccountStore<AnilistSession> anilistAccountStore = createTrackerAccountStore<AnilistSession>(
  baseKey: 'anilist_session',
  decode: AnilistSession.decode,
);
