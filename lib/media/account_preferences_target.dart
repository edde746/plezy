import 'account_ref.dart';
import 'media_backend.dart';

/// One selectable account in the Account preferences section.
///
/// Built from the *active profile's* connections (`ProfileConnectionRegistry`
/// joined with `ConnectionRegistry`), never from every connection on the
/// device: the section edits the signed-in user's own server-side preferences,
/// and another profile's accounts are neither reachable with the active
/// profile's tokens nor the user's business here.
class AccountPreferenceTarget {
  const AccountPreferenceTarget({
    required this.ref,
    required this.label,
    this.subtitle,
    this.isDefaultConnection = false,
  });

  final AccountRef ref;

  /// Primary row label: server name (MediaBrowser) or account label (Plex).
  final String label;

  /// Secondary row label: user · URL (MediaBrowser) or Home user (Plex).
  final String? subtitle;

  /// Whether the profile designated this connection as its picker default.
  /// Presentation only: this does not establish playback authority.
  final bool isDefaultConnection;

  MediaBackend get backend => ref.backend;
}
