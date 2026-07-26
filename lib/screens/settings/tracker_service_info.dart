import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/catalog/catalog_item.dart';
import '../../providers/trackers_provider.dart';
import '../../providers/trakt_account_provider.dart';
import '../../services/trackers/anilist/anilist_tracker.dart';
import '../../services/trackers/mal/mal_tracker.dart';
import '../../services/trackers/simkl/simkl_tracker.dart';
import '../../services/trackers/tracker.dart';
import '../../services/trackers/tracker_constants.dart';
import '../../services/trakt/trakt_scrobble_service.dart';
import 'tracker_settings_screen.dart';
import 'trakt_settings_screen.dart';

/// One watch tracker, described once for every place that lists services: the
/// services hub, the rating sheet, and the settings summary line.
///
/// [isConnected] and [username] take a [BuildContext] because each service
/// keeps its account state on a different provider; they read it with `watch`,
/// so the calling element rebuilds exactly like the per-service `Consumer`
/// these entries replaced.
class TrackerServiceInfo {
  final TrackerService service;
  final String displayName;

  /// Which brand mark to draw; the asset path itself lives only in
  /// `CatalogSourceLogo`.
  final CatalogSourceId logoSource;

  final TrackerRatingSource ratingSource;
  final bool Function(BuildContext) isConnected;
  final String? Function(BuildContext) username;
  final Future<void> Function(BuildContext) startConnection;
  final Widget Function() buildSettingsScreen;

  const TrackerServiceInfo({
    required this.service,
    required this.displayName,
    required this.logoSource,
    required this.ratingSource,
    required this.isConnected,
    required this.username,
    required this.startConnection,
    required this.buildSettingsScreen,
  });

  /// Entry for a service that shares [TrackerSettingsScreen]: [config] already
  /// carries the name and the [TrackersProvider] accessors.
  TrackerServiceInfo.shared(
    TrackerConfig config, {
    required this.logoSource,
    required this.ratingSource,
    required this.startConnection,
  }) : service = config.service,
       displayName = config.displayName,
       isConnected = ((context) => config.isConnected(context.watch<TrackersProvider>())),
       username = ((context) => config.username(context.watch<TrackersProvider>())),
       buildSettingsScreen = (() => TrackerSettingsScreen(config: config));

  /// Display order shared by every list. Built per call because [displayName]
  /// reads the active locale.
  static List<TrackerServiceInfo> get all => [
    TrackerServiceInfo(
      service: TrackerService.trakt,
      displayName: t.trakt.title,
      logoSource: CatalogSourceId.trakt,
      ratingSource: TraktScrobbleService.instance,
      isConnected: (context) => context.watch<TraktAccountProvider>().isConnected,
      username: (context) => context.watch<TraktAccountProvider>().username,
      startConnection: startTraktConnection,
      buildSettingsScreen: () => const TraktSettingsScreen(),
    ),
    TrackerServiceInfo.shared(
      TrackerConfig.mal(),
      logoSource: CatalogSourceId.mal,
      ratingSource: MalTracker.instance,
      startConnection: startMalConnection,
    ),
    TrackerServiceInfo.shared(
      TrackerConfig.anilist(),
      logoSource: CatalogSourceId.anilist,
      ratingSource: AnilistTracker.instance,
      startConnection: startAnilistConnection,
    ),
    TrackerServiceInfo.shared(
      TrackerConfig.simkl(),
      logoSource: CatalogSourceId.simkl,
      ratingSource: SimklTracker.instance,
      startConnection: startSimklConnection,
    ),
  ];
}
