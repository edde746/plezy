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
    this.isActiveProfileAccount = false,
  });

  final AccountRef ref;

  /// Primary row label: server name (MediaBrowser) or account label (Plex).
  final String label;

  /// Secondary row label: user · URL (MediaBrowser) or Home user (Plex).
  final String? subtitle;

  /// Whether this is the account the active profile is currently browsing
  /// with. Used to order the picker; not a permission.
  final bool isActiveProfileAccount;

  MediaBackend get backend => ref.backend;
}
