import 'dart:async';

import '../connection/connection.dart';
import '../connection/connection_registry.dart';
import '../models/plex/plex_home_user.dart';
import '../services/storage_service.dart';
import 'plex_home_service.dart';
import 'profile.dart';
import 'profile_connection.dart';
import 'profile_connection_registry.dart';
import 'profile_merge.dart';
import 'profile_registry.dart';

/// Snapshot for picker / manage-profiles UIs: every visible profile
/// (local rows from [ProfileRegistry] + virtual Plex Home profiles built
/// from [PlexHomeService]'s live cache) plus the data needed to render
/// per-profile connection chips.
class ProfilesView {
  final List<Profile> profiles;

  /// Per-profile borrowed connections. Does **not** include the Plex Home
  /// parent — that's implicit via [Profile.parentConnectionId]. Plex Home
  /// profiles can have entries here too (e.g. borrowed Jellyfin servers).
  final Map<String, List<ProfileConnection>> connectionsByProfile;

  final Map<String, Connection> connectionsById;

  const ProfilesView({required this.profiles, required this.connectionsByProfile, required this.connectionsById});

  static const empty = ProfilesView(profiles: [], connectionsByProfile: {}, connectionsById: {});

  int countFor(Profile profile) {
    if (profile.isPlexHome) return profile.parentConnectionId == null ? 0 : 1;
    return connectionsByProfile[profile.id]?.length ?? 0;
  }
}

/// Join-table rows that should be shown as explicit, user-manageable
/// connections for [profile].
///
/// Plex Home profiles own their parent account implicitly through
/// [Profile.parentConnectionId]. A parent [ProfileConnection] row may still
/// exist as a token cache, but UI should not render it as a removable
/// borrowed connection.
List<ProfileConnection> visibleProfileConnections(Profile profile, List<ProfileConnection> pcs) {
  final parentId = profile.parentConnectionId;
  if (!profile.isPlexHome || parentId == null) return pcs;
  return pcs.where((pc) => pc.connectionId != parentId).toList();
}

/// Combine [ProfileRegistry], [ProfileConnectionRegistry],
/// [ConnectionRegistry], and [PlexHomeService] into a single stream.
/// Plex Home profiles are constructed on the fly from the live cache; they
/// are never persisted as Profile rows.
Stream<ProfilesView> watchProfilesView({
  required ProfileRegistry profiles,
  required ProfileConnectionRegistry profileConnections,
  required ConnectionRegistry connections,
  required PlexHomeService plexHome,
  StorageService? storage,
}) {
  return _combineLatest4<
    List<Profile>,
    List<ProfileConnection>,
    List<Connection>,
    Map<String, List<PlexHomeUser>>,
    ProfilesView
  >(
    profiles.watchProfiles(),
    profileConnections.watchAll(),
    connections.watchConnections(),
    plexHome.stream,
    (locals, pcs, conns, homes) => _build(locals: locals, pcs: pcs, conns: conns, homes: homes, storage: storage),
  );
}

ProfilesView _build({
  required List<Profile> locals,
  required List<ProfileConnection> pcs,
  required List<Connection> conns,
  required Map<String, List<PlexHomeUser>> homes,
  required StorageService? storage,
}) {
  final connectionsById = {for (final c in conns) c.id: c};
  final all = mergeLocalWithPlexHome(
    locals: locals,
    plexHomeByConnectionId: homes,
    connectionsById: connectionsById,
    storage: storage,
  );
  return ProfilesView(profiles: all, connectionsByProfile: _groupByProfile(pcs), connectionsById: connectionsById);
}

Map<String, List<ProfileConnection>> _groupByProfile(List<ProfileConnection> pcs) {
  final out = <String, List<ProfileConnection>>{};
  for (final pc in pcs) {
    out.putIfAbsent(pc.profileId, () => []).add(pc);
  }
  return out;
}

/// Lightweight `combineLatest4` — emits the combined value once each input
/// has produced a value, then on every subsequent tick from any input.
Stream<R> _combineLatest4<A, B, C, D, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  R Function(A, B, C, D) combine,
) {
  late StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  StreamSubscription<C>? subC;
  StreamSubscription<D>? subD;
  A? lastA;
  B? lastB;
  C? lastC;
  D? lastD;
  var hasA = false, hasB = false, hasC = false, hasD = false;

  void emit() {
    if (hasA && hasB && hasC && hasD) controller.add(combine(lastA as A, lastB as B, lastC as C, lastD as D));
  }

  controller = StreamController<R>(
    onListen: () {
      subA = a.listen((v) {
        lastA = v;
        hasA = true;
        emit();
      }, onError: controller.addError);
      subB = b.listen((v) {
        lastB = v;
        hasB = true;
        emit();
      }, onError: controller.addError);
      subC = c.listen((v) {
        lastC = v;
        hasC = true;
        emit();
      }, onError: controller.addError);
      subD = d.listen((v) {
        lastD = v;
        hasD = true;
        emit();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
      await subC?.cancel();
      await subD?.cancel();
      await controller.close();
    },
  );
  return controller.stream;
}
