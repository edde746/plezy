import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../connection/connection_registry.dart';
import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/catalog/catalog_item.dart';
import '../profiles/active_plex_identity.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile_connection_registry.dart';
import '../profiles/profile.dart';
import '../services/base_shared_preferences_service.dart';
import '../services/catalog/catalog_source.dart';
import '../services/catalog/anilist_catalog_source.dart';
import '../services/catalog/mal_catalog_source.dart';
import '../services/catalog/plex_catalog_source.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../services/catalog/simkl_catalog_source.dart';
import '../services/catalog/trakt_catalog_source.dart';
import '../services/plex_discover_client.dart';
import '../services/seerr/seerr_client.dart';
import '../services/trackers/anilist/anilist_client.dart';
import '../services/trackers/mal/mal_client.dart';
import '../services/trackers/simkl/simkl_client.dart';
import '../services/trakt/trakt_client.dart';
import 'seerr_account_provider.dart';
import 'trakt_account_provider.dart';
import 'trackers_provider.dart';
import '../utils/app_logger.dart';

typedef PlexDiscoverSessionSupplier = Future<PlexDiscoverSession?> Function();

/// Resolve the active Plex/Home profile credentials used by the cloud
/// Discover provider. Home-user tokens take precedence over the account token
/// so each profile sees and mutates its own universal watchlist.
Future<PlexDiscoverSession?> resolvePlexDiscoverSession({
  required ActiveProfileProvider activeProfile,
  required ConnectionRegistry connections,
  required ProfileConnectionRegistry profileConnections,
}) async {
  final identity = await resolveActivePlexIdentity(
    activeProfile: activeProfile,
    connections: connections,
    profileConnections: profileConnections,
  );
  if (identity == null) return null;

  var token = identity.account.accountToken;
  final profile = activeProfile.active;
  if (profile != null) {
    final profileConnection = await profileConnections.get(profile.id, identity.account.id);
    if (profileConnection?.hasToken ?? false) token = profileConnection!.userToken!;
  }
  final session = PlexDiscoverSession(accessToken: token, clientIdentifier: identity.account.clientIdentifier);
  return session.isUsable ? session : null;
}

/// Owns one client/source pair and applies the shared rebind/dispose contract.
class _CatalogSourceBinding<Client extends Object, Source extends CatalogSource> {
  _CatalogSourceBinding(this._create, {bool Function(Client? previous, Client? next)? equals})
    : _equals = equals ?? ((previous, next) => identical(previous, next));

  final Source Function(Client client) _create;
  final bool Function(Client? previous, Client? next) _equals;
  Client? _client;
  Source? source;

  bool update(Client? next) {
    if (_equals(_client, next)) return false;
    final replacement = next == null ? null : _create(next);
    source?.dispose();
    _client = next;
    source = replacement;
    return true;
  }

  void dispose() {
    source?.dispose();
    source = null;
    _client = null;
  }
}

/// Enumerates the connected [CatalogSource]s for the active profile and owns
/// which one the Explore tab shows.
///
/// Profile-scoped. Plex Discover credentials hydrate with the active profile;
/// tracker/Seerr sources are rebuilt through the proxy-provider update hook so
/// every source appears and disappears with its owning account connection
/// (which also drives the Explore tab's visibility).
class CatalogSourcesProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  CatalogSourcesProvider({this.plexSessionSupplier});

  final PlexDiscoverSessionSupplier? plexSessionSupplier;
  final _CatalogSourceBinding<PlexDiscoverSession, PlexCatalogSource> _plex = _CatalogSourceBinding(
    (session) => PlexCatalogSource(PlexDiscoverClient(session)),
    equals: (previous, next) => previous == next,
  );
  final _CatalogSourceBinding<TraktClient, TraktCatalogSource> _trakt = _CatalogSourceBinding(TraktCatalogSource.new);
  final _CatalogSourceBinding<MalClient, MalCatalogSource> _mal = _CatalogSourceBinding(MalCatalogSource.new);
  final _CatalogSourceBinding<AnilistClient, AnilistCatalogSource> _anilist = _CatalogSourceBinding(
    AnilistCatalogSource.new,
  );
  final _CatalogSourceBinding<SimklClient, SimklCatalogSource> _simkl = _CatalogSourceBinding(SimklCatalogSource.new);
  final _CatalogSourceBinding<SeerrClient, SeerrCatalogSource> _seerr = _CatalogSourceBinding(SeerrCatalogSource.new);
  int _profileBindingGeneration = 0;
  int _plexSessionGeneration = 0;
  bool? _lastProfileBindingState;
  static const String _activeSourceBaseKey = 'catalog_active_source';
  CatalogSourceId? _preferredSourceId;
  String _activeUserUuid = '';

  List<CatalogSource> get connectedSources => [
    ?_trakt.source,
    ?_mal.source,
    ?_anilist.source,
    ?_simkl.source,
    ?_plex.source,
    ?_seerr.source,
  ];

  bool get hasAnySource => connectedSources.isNotEmpty;

  /// The connected Seerr source, for the request surfaces (detail-screen
  /// Request action and sheet) that need Seerr's client beyond the
  /// [CatalogSource] interface.
  SeerrCatalogSource? get seerrSource => _seerr.source;

  /// The source whose rows the Explore tab shows: the user's persisted pick
  /// when it is still connected, otherwise the first connected source.
  CatalogSource? get activeSource {
    final sources = connectedSources;
    return sources.firstWhereOrNull((s) => s.id == _preferredSourceId) ?? sources.firstOrNull;
  }

  /// The source backing watchlist membership/mutation surfaces (media-detail
  /// action). Independent of [activeSource] so switching the Explore tab to a
  /// watchlist-less source (e.g. a future Seerr) keeps the action alive.
  CatalogSource? get watchlistCapableSource => connectedSources.firstWhereOrNull((s) => s.supportsWatchlist);

  /// All connected sources whose watchlist can be read and mutated, for
  /// surfaces that offer a choice (media-detail bookmark with several
  /// providers connected).
  List<CatalogSource> get watchlistCapableSources => [...connectedSources.where((source) => source.supportsWatchlist)];

  /// The watchlist source catalog-item surfaces (detail screen, card menu)
  /// must bind to: the item's OWN source — a MAL card toggles the MAL Plan to
  /// Watch, never another provider's list. An item whose source is connected
  /// but has no watchlist (Seerr) gets none at all — no falling back to
  /// another provider's list. The fallback exists only for items whose
  /// source got disconnected mid-session.
  CatalogSource? watchlistSourceFor(CatalogItem item) {
    final own = connectedSources.firstWhereOrNull((s) => s.id == item.source);
    if (own != null) return own.supportsWatchlist ? own : null;
    return watchlistCapableSource;
  }

  /// Hydrate the per-profile active-source preference and Plex session.
  Future<void> onActiveProfileChanged(String? userUuid) async {
    final generation = ++_profileBindingGeneration;
    _activeUserUuid = userUuid ?? '';
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final raw = prefs.getString(profileScopedPrefsKey(_activeUserUuid, _activeSourceBaseKey));
    if (isDisposed || generation != _profileBindingGeneration) return;

    _preferredSourceId = CatalogSourceId.values.asNameMap()[raw];
    safeNotifyListeners();
    await _refreshPlexSession(profileGeneration: generation, clearOnFailure: true);
  }

  /// Refresh Plex Discover credentials after a same-profile server rebind.
  /// The active-profile binder announces start/finish even when the profile id
  /// stays unchanged, which is the connection-add/remove seam.
  Future<void> onProfileBindingStateChanged(bool isBinding) async {
    final previous = _lastProfileBindingState;
    _lastProfileBindingState = isBinding;
    if (isBinding && previous != true) _plexSessionGeneration++;
    if (previous == true && !isBinding) await _refreshPlexSession();
  }

  Future<void> _refreshPlexSession({int? profileGeneration, bool clearOnFailure = false}) async {
    final expectedProfileGeneration = profileGeneration ?? _profileBindingGeneration;
    final sessionGeneration = ++_plexSessionGeneration;
    PlexDiscoverSession? session;
    try {
      session = await plexSessionSupplier?.call();
    } catch (error, stackTrace) {
      appLogger.w('Plex Discover session hydrate failed', error: error, stackTrace: stackTrace);
      if (clearOnFailure &&
          !isDisposed &&
          expectedProfileGeneration == _profileBindingGeneration &&
          sessionGeneration == _plexSessionGeneration &&
          _plex.update(null)) {
        safeNotifyListeners();
      }
      return;
    }
    if (isDisposed ||
        expectedProfileGeneration != _profileBindingGeneration ||
        sessionGeneration != _plexSessionGeneration) {
      return;
    }
    if (_plex.update(session)) safeNotifyListeners();
  }

  Future<void> setActiveSource(CatalogSourceId id) async {
    if (_preferredSourceId == id) return;
    _preferredSourceId = id;
    safeNotifyListeners();
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setString(profileScopedPrefsKey(_activeUserUuid, _activeSourceBaseKey), id.name);
  }

  /// Proxy-provider update hook: rebuild a source when its catalog client
  /// was rebound (connect/disconnect/profile switch).
  void update(TraktAccountProvider trakt, TrackersProvider trackers, SeerrAccountProvider seerr) {
    var changed = false;
    changed = _trakt.update(trakt.catalogClient) || changed;
    changed = _mal.update(trackers.malCatalogClient) || changed;
    changed = _anilist.update(trackers.anilistCatalogClient) || changed;
    changed = _simkl.update(trackers.simklCatalogClient) || changed;
    changed = _seerr.update(seerr.catalogClient) || changed;
    if (changed) safeNotifyListeners();
  }

  @override
  void dispose() {
    _plex.dispose();
    _trakt.dispose();
    _mal.dispose();
    _anilist.dispose();
    _simkl.dispose();
    _seerr.dispose();
    super.dispose();
  }
}
