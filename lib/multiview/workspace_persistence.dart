import 'dart:convert';

import '../services/storage_service.dart';
import 'workspace_models.dart';

/// Persistence boundary for profile-local workspace preferences.
///
/// It stores only versioned, non-secret descriptors and normalized layout.
/// Live routes, playback instances, credentials and native resources always
/// come from their normal owners after startup.
abstract interface class WorkspaceSnapshotPersistence {
  Future<WorkspaceSnapshot?> read(String profileId);
  Future<void> write(String profileId, WorkspaceSnapshot snapshot);
}

class SharedPreferencesWorkspaceSnapshotPersistence implements WorkspaceSnapshotPersistence {
  const SharedPreferencesWorkspaceSnapshotPersistence();

  static const String _keySuffix = 'multiview_workspace_v2';

  @override
  Future<WorkspaceSnapshot?> read(String profileId) async {
    final storage = await StorageService.getInstance();
    final key = 'user_${storage.userScopeForProfileId(profileId)}_$_keySuffix';
    final serialized = storage.prefs.getString(key);
    if (serialized == null || serialized.isEmpty) return null;
    final decoded = jsonDecode(serialized);
    if (decoded is! Map) throw const FormatException('Invalid stored Multiview snapshot');
    return WorkspaceSnapshot.fromJson(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> write(String profileId, WorkspaceSnapshot snapshot) async {
    final storage = await StorageService.getInstance();
    final key = 'user_${storage.userScopeForProfileId(profileId)}_$_keySuffix';
    await storage.prefs.setString(key, jsonEncode(snapshot.toJson()));
  }
}
