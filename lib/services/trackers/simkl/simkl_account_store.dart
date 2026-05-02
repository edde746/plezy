import '../tracker_account_store.dart';
import 'simkl_session.dart';

final TrackerAccountStore<SimklSession> simklAccountStore = createTrackerAccountStore<SimklSession>(
  baseKey: 'simkl_session',
  decode: SimklSession.decode,
);
