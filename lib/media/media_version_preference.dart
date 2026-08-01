import 'media_version.dart';

/// A remembered media-version choice for a series or standalone item, stored
/// in `SettingsService.mediaVersionPreferences` (#1492).
///
/// Persisted as `{"id":…,"sig":…,"idx":…,"at":…}`. Values written before the
/// record form existed were bare positional ints; [MediaVersionPreference.fromJson]
/// still accepts those so old preferences keep working.
class MediaVersionPreference {
  /// Backend-opaque [MediaVersion.id] of the chosen version. Exact match only
  /// holds for the item the pick was made on (ids differ per episode).
  final String? versionId;

  /// [MediaVersion.signature] ("res:codec:container") of the chosen version,
  /// for matching the equivalent version on sibling episodes.
  final String? signature;

  /// Positional index into the Media list at pick time. Last-resort fallback
  /// and the only field legacy int values carry.
  final int index;

  /// Epoch ms of the last write; used to evict the oldest entries when the
  /// preference map is pruned. Null on legacy entries (evicted first).
  final int? updatedAt;

  const MediaVersionPreference({this.versionId, this.signature, required this.index, this.updatedAt});

  /// Capture [version] (at [index] in its Media list) as a preference.
  factory MediaVersionPreference.forVersion(MediaVersion version, int index) => MediaVersionPreference(
    versionId: version.id.isEmpty ? null : version.id,
    signature: version.signature,
    index: index,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );

  factory MediaVersionPreference.fromJson(Object? raw) {
    if (raw is int) return MediaVersionPreference(index: raw);
    if (raw is Map) {
      return MediaVersionPreference(
        versionId: raw['id'] as String?,
        signature: raw['sig'] as String?,
        index: raw['idx'] is int ? raw['idx'] as int : 0,
        updatedAt: raw['at'] as int?,
      );
    }
    return const MediaVersionPreference(index: 0);
  }

  Map<String, dynamic> toJson() => {
    if (versionId != null) 'id': versionId,
    if (signature != null) 'sig': signature,
    'idx': index,
    if (updatedAt != null) 'at': updatedAt,
  };

  /// Resolve this preference against an actual version list: exact id match,
  /// then signature match (3-tier, see [MediaVersion.findMatchingIndex]), then
  /// the stored index when still in range. Null when nothing applies.
  int? resolveIndex(List<MediaVersion> versions) {
    if (versions.isEmpty) return null;
    final id = versionId;
    if (id != null && id.isNotEmpty) {
      final byId = versions.indexWhere((v) => v.id == id);
      if (byId >= 0) return byId;
    }
    final sig = signature;
    if (sig != null && sig.isNotEmpty) {
      final bySignature = MediaVersion.findMatchingIndex(versions, {sig});
      if (bySignature != null) return bySignature;
    }
    return index >= 0 && index < versions.length ? index : null;
  }
}
