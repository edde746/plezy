import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/catalog/catalog_item.dart';
import '../profiles/profile.dart';
import '../services/base_shared_preferences_service.dart';
import '../services/catalog/catalog_source.dart';
import '../services/catalog/mal_catalog_source.dart';
import '../services/catalog/seerr_catalog_source.dart';
import '../services/catalog/trakt_catalog_source.dart';
import '../services/seerr/seerr_client.dart';
import '../services/trackers/mal/mal_client.dart';
import '../services/trakt/trakt_client.dart';
import 'seerr_account_provider.dart';
import 'trakt_account_provider.dart';
import 'trackers_provider.dart';

/// Enumerates the connected [CatalogSource]s for the active profile and owns
/// which one the Explore tab shows.
///
/// Profile-scoped; rebuilt through a `ChangeNotifierProxyProvider3` on
/// [TraktAccountProvider], [TrackersProvider] (MAL), and
/// [SeerrAccountProvider] so sources appear and
/// disappear live when a provider is connected or disconnected mid-session
/// (which also drives the Explore tab's visibility).
class CatalogSourcesProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  static const String _activeSourceBaseKey = 'catalog_active_source';

  TraktCatalogSource? _trakt;
  TraktClient? _lastTraktClient;
  MalCatalogSource? _mal;
  MalClient? _lastMalClient;
  SeerrCatalogSource? _seerr;
  SeerrClient? _lastSeerrClient;
  CatalogSourceId? _preferredSourceId;
  String _activeUserUuid = '';

  List<CatalogSource> get connectedSources => [?_trakt, ?_mal, ?_seerr];

  bool get hasAnySource => _trakt != null || _mal != null || _seerr != null;

  /// The connected Seerr source, for the request surfaces (detail-screen
  /// Request action and sheet) that need Seerr's client beyond the
  /// [CatalogSource] interface.
  SeerrCatalogSource? get seerrSource => _seerr;

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

  /// Hydrate the per-profile active-source preference.
  Future<void> onActiveProfileChanged(String? userUuid) async {
    _activeUserUuid = userUuid ?? '';
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final raw = prefs.getString(profileScopedPrefsKey(_activeUserUuid, _activeSourceBaseKey));
    if (isDisposed) return;
    _preferredSourceId = CatalogSourceId.values.asNameMap()[raw];
    safeNotifyListeners();
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

    final traktClient = trakt.catalogClient;
    if (!identical(traktClient, _lastTraktClient)) {
      _lastTraktClient = traktClient;
      _trakt?.dispose();
      _trakt = traktClient == null ? null : TraktCatalogSource(traktClient);
      changed = true;
    }

    final malClient = trackers.malCatalogClient;
    if (!identical(malClient, _lastMalClient)) {
      _lastMalClient = malClient;
      _mal?.dispose();
      _mal = malClient == null ? null : MalCatalogSource(malClient);
      changed = true;
    }

    final seerrClient = seerr.catalogClient;
    if (!identical(seerrClient, _lastSeerrClient)) {
      _lastSeerrClient = seerrClient;
      _seerr?.dispose();
      _seerr = seerrClient == null ? null : SeerrCatalogSource(seerrClient);
      changed = true;
    }

    if (changed) safeNotifyListeners();
  }

  @override
  void dispose() {
    _trakt?.dispose();
    _trakt = null;
    _mal?.dispose();
    _mal = null;
    _seerr?.dispose();
    _seerr = null;
    super.dispose();
  }
}
