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
/// Optional lifetime checks let an explicit settings mutation stop before a
/// stale async resolution commits crypto or starts a replacement session.
Future<bool> ensureCompanionRemoteCryptoFromContext(BuildContext context, {void Function()? checkCurrent}) async {
  checkCurrent?.call();
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
  checkCurrent?.call();
  final home = identity == null ? null : await plexHome.materializePlexHomeForConnection(identity.account.id);
  checkCurrent?.call();
  return companionRemote.ensureCryptoReady(
    home,
    connections: connections,
    activeProfile: activeProfile,
    profileConnections: profileConnections,
    identity: identity,
    plexHomeForConnection: plexHome.materializePlexHomeForConnection,
    checkCurrent: checkCurrent,
  );
}

Future<bool> startCompanionRemoteHost(BuildContext context, {void Function()? checkCurrent}) async {
  checkCurrent?.call();
  final companionRemote = context.read<CompanionRemoteProvider>();
  if (companionRemote.isHostServerRunning) return true;

  try {
    if (!await ensureCompanionRemoteCryptoFromContext(context, checkCurrent: checkCurrent)) return false;
    checkCurrent?.call();

    await companionRemote.startHostServer(checkCurrent: checkCurrent);
    checkCurrent?.call();
    return companionRemote.isHostServerRunning;
  } catch (e) {
    checkCurrent?.call();
    appLogger.e('CompanionRemote: Failed to start server', error: e);
    return false;
  }
}

Future<bool> applyCompanionRemoteServerSetting(
  BuildContext context,
  bool enabled, {
  void Function()? checkCurrent,
}) async {
  checkCurrent?.call();
  final companionRemote = context.read<CompanionRemoteProvider>();
  if (!enabled) {
    await companionRemote.stopHostServer(checkCurrent: checkCurrent);
    checkCurrent?.call();
    return !companionRemote.isHostServerRunning;
  }

  return startCompanionRemoteHost(context, checkCurrent: checkCurrent);
}
