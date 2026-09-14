import 'dart:async';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../media/media_version.dart';
import 'app_logger.dart';
import 'media_server_timeouts.dart';

/// How much a server-side delete will actually destroy.
enum DeleteImpactScope {
  /// Verified: the delete removes exactly one file and no other library item
  /// is backed by it.
  exclusive,

  /// Verified: the delete removes more than one file, or files that also back
  /// other items (a Plex `S01E01-E03.mkv` multi-episode file).
  broad,

  /// Not established. The confirmation must not claim a scope.
  unverified,
}

/// Why a scope could not be established, which decides whether retrying helps.
enum DeleteImpactUnverifiedReason {
  /// A metadata request failed or timed out. Transient; retrying may work.
  probeFailed,

  /// The server answered but withheld file paths — Plex hides them from
  /// restricted users. Retrying will never help.
  noFileInfo,
}

/// The verified blast radius of deleting one item.
class DeleteImpact {
  final DeleteImpactScope scope;

  /// Unique server-side paths this delete removes. Empty when [scope] is
  /// [DeleteImpactScope.unverified].
  final Set<String> files;

  /// Other library items backed by one of [files], which the server will
  /// destroy alongside the target.
  final List<MediaItem> sharedWith;

  final DeleteImpactUnverifiedReason? reason;

  const DeleteImpact._({required this.scope, required this.files, required this.sharedWith, this.reason});

  const DeleteImpact._unverified(DeleteImpactUnverifiedReason reason)
    : this._(scope: DeleteImpactScope.unverified, files: const {}, sharedWith: const [], reason: reason);

  bool get isUnverified => scope == DeleteImpactScope.unverified;
  bool get isBroad => scope == DeleteImpactScope.broad;
}

/// Every distinct file backing [versions], or null when the list cannot be
/// trusted to be complete.
///
/// Deliberately NOT [MediaItem.allPartFiles]: that getter drops parts whose
/// `file` is null, so a three-part version exposing one path yields a
/// one-entry set that silently understates the delete. Anything a
/// confirmation asserts must survive that case, so a single path-less part
/// invalidates the whole answer. `null` versions, an empty version list, and a
/// version whose parts were synthesized by `PlexMappers.mediaVersion` (which
/// fabricates one file-less part when the payload carried none) all fail here,
/// which is the intent.
Set<String>? completePartFiles(List<MediaVersion> versions) {
  // No early return for an empty list: the `sawPart` gate below already
  // rejects it, and every other "nothing to trust" shape with it.
  final files = <String>{};
  var sawPart = false;
  for (final version in versions) {
    for (final part in version.parts) {
      sawPart = true;
      final file = part.file;
      if (file == null || file.isEmpty) return null;
      files.add(file);
    }
  }
  return sawPart ? files : null;
}

/// Cooperative stop signal. `Future.timeout` completes the future the caller
/// awaits but leaves the work behind it running, so the probe has to be told
/// to stand down explicitly.
class _ProbeCancellation {
  bool isCancelled = false;
}

/// Establish what deleting [item] will destroy, before asking the user.
///
/// Returns [DeleteImpactScope.unverified] rather than guessing whenever any
/// input is missing. Callers must surface that as an explicit danger, never as
/// a normal confirmation: a silent fall-through would let a dialog assert
/// single-file scope on unknown data, which is the failure mode behind #1781.
///
/// Bounded by [timeout] because it runs behind a modal spinner. Expiry also
/// cancels the probe, so a season of thin rows cannot keep walking itself
/// after the confirmation has already given up on it. The request already in
/// flight cannot be recalled — the neutral client exposes no abort handle for
/// item lookups — so exactly one may outlive the deadline, and no further one
/// starts.
Future<DeleteImpact> resolveDeleteImpact({
  required MediaItem item,
  required MediaServerClient client,
  Duration timeout = MediaServerTimeouts.deleteImpactProbe,
}) async {
  final cancellation = _ProbeCancellation();
  try {
    return await _resolve(item, client, cancellation).timeout(
      timeout,
      onTimeout: () {
        cancellation.isCancelled = true;
        appLogger.w('Delete impact probe timed out for ${item.backend.id} item ${item.id}');
        return const DeleteImpact._unverified(DeleteImpactUnverifiedReason.probeFailed);
      },
    );
  } catch (e, st) {
    cancellation.isCancelled = true;
    appLogger.w('Delete impact probe failed for ${item.backend.id} item ${item.id}', error: e, stackTrace: st);
    return const DeleteImpact._unverified(DeleteImpactUnverifiedReason.probeFailed);
  }
}

/// The value every abandoned path returns. Nothing reads it — the caller's
/// future has already completed — it only has to stop the walk.
const _abandoned = DeleteImpact._unverified(DeleteImpactUnverifiedReason.probeFailed);

Future<DeleteImpact> _resolve(MediaItem item, MediaServerClient client, _ProbeCancellation cancellation) async {
  final own = await _completeFilesFor(item, client);
  // Cancelled while the item's own lookup was outstanding: stop before asking
  // the server for the season's children.
  if (cancellation.isCancelled) return _abandoned;
  final ownFiles = own.$1;
  if (ownFiles == null) return DeleteImpact._unverified(own.$2!);

  // Only an episode can be one of several items sharing a file. A movie's
  // blast radius is its own part list.
  final parentId = item.kind == MediaKind.episode ? item.parentId : null;
  if (parentId == null) return _verified(ownFiles, const []);

  final siblings = (await client.fetchChildren(parentId)).where((sibling) => sibling.id != item.id).toList();

  // Resolved one sibling at a time, bailing on the first whose paths stay
  // unknown. Both backends normally carry paths on browse rows (Plex
  // `/children` includes `Part.file`; Jellyfin episode rows request
  // `MediaSources`), so a detail refetch here is the degraded path — but on a
  // thin season it is the rule, and `Future.wait` would then fan out one
  // request per episode. Rows that already carry paths cost no request at all.
  final shared = <MediaItem>[];
  for (final sibling in siblings) {
    // Re-checked every iteration, because the deadline may have expired while
    // the previous sibling's lookup was outstanding. This is the gate that
    // keeps an abandoned probe from walking the rest of the season; a check
    // after the await would only skip discarded bookkeeping.
    if (cancellation.isCancelled) return _abandoned;
    final (files, reason) = await _completeFilesFor(sibling, client);
    // A sibling whose paths stayed unknown could be backed by this very file.
    // Absence of evidence is not evidence of absence.
    if (files == null) return DeleteImpact._unverified(reason!);
    if (files.intersection(ownFiles).isNotEmpty) shared.add(sibling);
  }

  return _verified(ownFiles, shared);
}

/// Every file backing [item], or the reason the list could not be trusted.
///
/// Deliberately not `resolveMediaVersions`: that helper returns inline
/// versions without ever consulting the detail endpoint, so a thin browse row
/// — including the single file-less part `PlexMappers.mediaVersion`
/// fabricates when a payload carried none — would be mistaken for a server
/// that withholds paths. It also flattens fetch failures into an empty list,
/// erasing the transient-vs-permanent distinction the confirmation copy needs.
Future<(Set<String>?, DeleteImpactUnverifiedReason?)> _completeFilesFor(
  MediaItem item,
  MediaServerClient client,
) async {
  final inline = completePartFiles(item.mediaVersions ?? const <MediaVersion>[]);
  if (inline != null) return (inline, null);

  final MediaItem? full;
  try {
    full = await client.fetchItem(item.id);
  } catch (e, st) {
    appLogger.w('Delete impact: failed to resolve files for item ${item.id}', error: e, stackTrace: st);
    return (null, DeleteImpactUnverifiedReason.probeFailed);
  }
  if (full == null) return (null, DeleteImpactUnverifiedReason.probeFailed);

  final resolved = completePartFiles(full.mediaVersions ?? const <MediaVersion>[]);
  return resolved != null ? (resolved, null) : (null, DeleteImpactUnverifiedReason.noFileInfo);
}

DeleteImpact _verified(Set<String> files, List<MediaItem> shared) => DeleteImpact._(
  scope: files.length > 1 || shared.isNotEmpty ? DeleteImpactScope.broad : DeleteImpactScope.exclusive,
  files: files,
  sharedWith: shared,
);
