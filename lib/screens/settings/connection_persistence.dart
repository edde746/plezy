import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../profiles/profile_connection.dart';
import '../../profiles/profile_connection_registry.dart';
import '../../providers/libraries_provider.dart';
import '../../providers/multi_server_provider.dart';

/// Persist a freshly-authenticated [connection] and (optionally) wire it into
/// the active session.
///
/// Steps, all guarded by `context.mounted`:
///
/// 1. Upsert [connection] into [ConnectionRegistry] — always.
/// 2. If [bindToProfile] is non-null, upsert a [ProfileConnection] join row
///    so the target profile owns the connection on next activation.
/// 3. If [addToManager] is non-null, invoke it to register the runtime client
///    with [MultiServerProvider]. When the manager reports success and
///    [visibleServerId] is set, extend the visibility filter so the new
///    server shows up immediately. On success the helper kicks off
///    [LibrariesProvider.loadLibraries] (fire-and-forget).
///
/// Returns whether the manager accepted the connection — callers use this to
/// branch their follow-up navigation. The helper itself does not navigate.
Future<bool> persistAndBindConnection({
  required BuildContext context,
  required Connection connection,
  required ProfileConnection? bindToProfile,
  required Future<bool> Function()? addToManager,
  String? visibleServerId,
}) async {
  await context.read<ConnectionRegistry>().upsert(connection);

  if (!context.mounted) return false;
  if (bindToProfile != null) {
    await context.read<ProfileConnectionRegistry>().upsert(bindToProfile);
  }

  if (!context.mounted || addToManager == null) return false;
  final added = await addToManager();
  if (!context.mounted || !added) return added;

  final mp = context.read<MultiServerProvider>();
  if (visibleServerId != null) {
    mp.addToVisibleServerIds(visibleServerId);
  }
  unawaited(context.read<LibrariesProvider>().loadLibraries());
  return true;
}
