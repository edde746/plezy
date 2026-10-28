import '../../sources/source_database.dart';
import '../../sources/source_models.dart';
import 'hardcover_client.dart';

class HardcoverAccountSession {
  const HardcoverAccountSession({required this.token, required this.account});

  final String token;
  final HardcoverAccount account;
}

/// Stores the provider token in the source repository's encrypted,
/// profile-scoped preference table. Deleting the PlezyNG profile removes it
/// through the existing repository lifecycle.
class HardcoverAccountStore {
  static const accountPreferenceKey = 'hardcover-account-v1';
  static const importedLibraryPreferenceKey = 'hardcover-imported-library-v1';
  static const importUndoPreferenceKey = 'hardcover-import-undo-v1';
  static const exportUndoPreferenceKey = 'hardcover-export-undo-v1';

  const HardcoverAccountStore(this.repository);

  final SourceRepository repository;

  Future<HardcoverAccountSession?> load(String profileId) async {
    final value = await repository.privatePreference(profileId, accountPreferenceKey);
    final token = value['token'];
    final account = value['account'];
    if (token is! String || token.trim().isEmpty || account is! Map) return null;
    final parsed = HardcoverAccount.fromJson(sourceMap(account));
    if (parsed.id <= 0 || parsed.username.isEmpty) return null;
    return HardcoverAccountSession(token: token, account: parsed);
  }

  Future<void> save(String profileId, String token, HardcoverAccount account) async {
    if (profileId.isEmpty || account.id <= 0 || account.username.isEmpty) {
      throw const SourceException(SourceFailure.invalidData);
    }
    await repository.savePrivatePreference(profileId, accountPreferenceKey, {
      'token': token.trim(),
      'account': account.toJson(),
    });
  }

  Future<void> clear(String profileId) async {
    await repository.forgetPreference(profileId, accountPreferenceKey);
    await repository.forgetPreference(profileId, importedLibraryPreferenceKey);
    await repository.forgetPreference(profileId, importUndoPreferenceKey);
    await repository.forgetPreference(profileId, exportUndoPreferenceKey);
  }
}
