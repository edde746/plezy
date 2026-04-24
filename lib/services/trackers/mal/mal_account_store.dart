import '../tracker_account_store.dart';
import 'mal_session.dart';

final TrackerAccountStore<MalSession> malAccountStore = TrackerAccountStore<MalSession>(
  baseKey: 'mal_session',
  decode: MalSession.decode,
  encode: (s) => s.encode(),
);
