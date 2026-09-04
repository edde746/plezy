import 'package:connectivity_plus/connectivity_plus.dart';

/// Link-type predicates over a `connectivity_plus` snapshot.
///
/// One definition of "metered connection" for every consumer — the cellular
/// playback-quality default, the download WiFi-only gate and the sync-rule
/// cooldown — so the three cannot drift apart.
///
/// Deliberately *not* a home for "is there any network at all": callers
/// disagree on whether an empty snapshot counts as connected, so unifying that
/// one would silently change behavior.
extension ConnectivityLinkType on List<ConnectivityResult> {
  /// Whether a WiFi or Ethernet link is present. Treated as unmetered
  /// throughout the app, which a metered WiFi hotspot violates; no platform
  /// API distinguishes the two, so the approximation is intentional.
  bool get hasWifiOrEthernet => contains(ConnectivityResult.wifi) || contains(ConnectivityResult.ethernet);

  /// Whether cellular is the only link. An empty or not-yet-emitted snapshot
  /// reads as false, so callers keep their unmetered behavior until the
  /// connection type is actually known.
  bool get isCellularOnly => contains(ConnectivityResult.mobile) && !hasWifiOrEthernet;
}
