/// Typed identifiers for media-server entities.
///
/// These are zero-cost [extension type] wrappers over [String]. Each
/// `implements String`, so a value flows freely into String-keyed maps, URLs,
/// JSON payloads, and drift columns without unwrapping — while the type system
/// still rejects a bare `String` (or a *different* id type) being passed where a
/// specific id is expected. Construct one with `ServerId('abc')`; it compares,
/// hashes, and interpolates exactly like its underlying string.
library;

/// Identifies a media server: a Plex `machineIdentifier` or a Jellyfin server
/// machine id. This is the key under which a [MediaServerClient] is registered
/// and the left half of a `serverId:ratingKey` global key.
extension type const ServerId(String value) implements String {}

/// Wraps a nullable raw id, preserving `null`. Use at boundaries where a
/// `String?` from a model/storage row crosses into [ServerId]-typed code.
ServerId? serverIdOrNull(String? value) => value == null ? null : ServerId(value);
