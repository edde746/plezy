import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../connection/connection_registry.dart';
import '../profiles/active_plex_token.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile_connection_registry.dart';
import '../services/plex_auth_service.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import 'iptv_source_repository.dart';

/// Optional account sync for IPTV VOD positions. Source credentials and
/// playback URLs never leave the device; the remote envelope contains only
/// hashed source identities and progress fields.
class IptvVodProgressSyncService {
  IptvVodProgressSyncService._();

  static final IptvVodProgressSyncService instance = IptvVodProgressSyncService._();
  static const settingId = 'plezy_iptv_vod_progress_v1';

  PlexAuthService? _auth;
  bool _syncing = false;

  Future<void> syncActiveProfile(
    BuildContext context, {
    required String profileId,
    required IptvSourceRepository repository,
  }) async {
    if (!SettingsService.instance.read(SettingsService.iptvVodProgressSyncEnabled)) return;
    final active = context.read<ActiveProfileProvider>();
    final profile = active.active;
    if (profile == null || active.activeId != profileId) return;
    final resolved = await resolveActivePlexToken(
      activeProfile: active,
      connections: context.read<ConnectionRegistry>(),
      profileConnections: context.read<ProfileConnectionRegistry>(),
      allowAccountTokenForHomeUser: false,
    );
    if (!context.mounted || active.activeId != profileId || resolved == null) return;
    await sync(
      profileId: profileId,
      profileLabel: profile.displayName,
      plexToken: resolved.token,
      repository: repository,
    );
  }

  Future<void> sync({
    required String profileId,
    required String profileLabel,
    required String plexToken,
    required IptvSourceRepository repository,
  }) async {
    if (_syncing || !SettingsService.instance.read(SettingsService.iptvVodProgressSyncEnabled)) return;
    _syncing = true;
    try {
      final auth = _auth ??= await PlexAuthService.create();
      final entries = await auth.getUserSettings(plexToken);
      final entry = entries.where((value) => value['id'] == settingId).firstOrNull;
      final rawValue = entry?['value'];
      Map<String, dynamic> envelope = const {};
      if (rawValue is String && rawValue.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawValue);
          if (decoded is Map<String, dynamic> && decoded['v'] == 1) envelope = decoded;
        } on Object {
          // A damaged shared value is replaced with the valid local snapshot.
        }
      }
      final profiles = Map<String, dynamic>.from(envelope['profiles'] as Map? ?? const {});
      final scope = sha256.convert(utf8.encode(profileLabel.trim().toLowerCase())).toString();
      final remoteProfile = profiles[scope];
      final remoteRows = remoteProfile is Map && remoteProfile['rows'] is List
          ? List<dynamic>.from(remoteProfile['rows'] as List)
          : const <dynamic>[];

      await repository.mergeVodProgressFromSync(profileId, remoteRows);
      final mergedRows = await repository.exportVodProgressForSync(profileId);
      final mergedEncoded = jsonEncode(mergedRows);
      final remoteEncoded = jsonEncode(remoteRows);
      if (mergedEncoded == remoteEncoded) return;

      // Keep a small number of profile scopes in the account value so one
      // Plex Home user cannot erase another's saved progress.
      profiles[scope] = {'rows': mergedRows};
      while (profiles.length > 8) {
        profiles.remove(profiles.keys.first);
      }
      await auth.putUserSetting(plexToken, settingId, jsonEncode({'v': 1, 'profiles': profiles}));
    } on Object catch (error, stackTrace) {
      appLogger.w('IPTV VOD progress sync failed', error: error, stackTrace: stackTrace);
    } finally {
      _syncing = false;
    }
  }
}
