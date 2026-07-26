import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../connection/connection_registry.dart';
import '../../profiles/active_plex_identity.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/plex_home_service.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../providers/companion_remote_provider.dart';
import '../../utils/app_logger.dart';

/// Resolves the active profile's Plex identity and primes companion-remote
/// crypto with it, returning whether crypto ended up ready.
///
/// Crypto is an app-level service, not bound to any one widget: everything the
/// bootstrap needs is captured up front, so an unmount mid-await must not abort
/// work the user asked for. Hence no `context.mounted` guards below.
Future<bool> ensureCompanionRemoteCryptoFromContext(BuildContext context) async {
  final companionRemote = context.read<CompanionRemoteProvider>();
  final connections = context.read<ConnectionRegistry>();
  final activeProfile = context.read<ActiveProfileProvider>();
  final profileConnections = context.read<ProfileConnectionRegistry>();
  final plexHome = context.read<PlexHomeService>();
  final identity = await resolveActivePlexIdentity(
    activeProfile: activeProfile,
    connections: connections,
    profileConnections: profileConnections,
  );
  final home = identity == null ? null : await plexHome.materializePlexHomeForConnection(identity.account.id);
  return companionRemote.ensureCryptoReady(
    home,
    connections: connections,
    activeProfile: activeProfile,
    profileConnections: profileConnections,
    identity: identity,
    plexHomeForConnection: plexHome.materializePlexHomeForConnection,
  );
}

Future<bool> startCompanionRemoteHost(BuildContext context) async {
  final companionRemote = context.read<CompanionRemoteProvider>();
  if (companionRemote.isHostServerRunning) return true;

  try {
    if (!await ensureCompanionRemoteCryptoFromContext(context)) return false;

    await companionRemote.startHostServer();
    return companionRemote.isHostServerRunning;
  } catch (e) {
    appLogger.e('CompanionRemote: Failed to start server', error: e);
    return false;
  }
}

Future<void> applyCompanionRemoteServerSetting(BuildContext context, bool enabled) async {
  final companionRemote = context.read<CompanionRemoteProvider>();
  if (!enabled) {
    await companionRemote.stopHostServer();
    return;
  }

  await startCompanionRemoteHost(context);
}
