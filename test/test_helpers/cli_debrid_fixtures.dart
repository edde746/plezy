import 'package:plezy/models/cli_debrid/cli_debrid_session.dart';
import 'package:plezy/providers/cli_debrid_account_provider.dart';
import 'package:plezy/services/cli_debrid/cli_debrid_session_store.dart';

/// Never touches real SharedPreferences/CredentialVault: most widget tests
/// don't set up `resetSharedPreferencesForTest`, so a real
/// [CliDebridSessionStore] would risk the disk-preflight deadlock
/// `prefs.dart`'s fixtures exist to avoid.
class _NoopCliDebridSessionStore extends CliDebridSessionStore {
  const _NoopCliDebridSessionStore();

  @override
  Future<CliDebridSession?> load(String userUuid) async => null;
}

/// A disconnected, already-hydrated provider for widget trees that don't
/// exercise cli_debrid themselves — they just need one present so the
/// movie/episode/season kind gate in [MediaContextMenu]/`showCatalogItemMenu`
/// (and any other `context.read<CliDebridAccountProvider>()` call) doesn't
/// throw `ProviderNotFoundException`. The caller owns disposal.
Future<CliDebridAccountProvider> testCliDebridAccountProvider() async {
  final provider = CliDebridAccountProvider(store: const _NoopCliDebridSessionStore());
  await provider.onActiveProfileChanged(null);
  return provider;
}
