import 'package:flutter/widgets.dart';

import '../utils/platform_detector.dart';
import 'car_ux_restrictions_service.dart';

/// Android Automotive OS driver-distraction gating for Plezy's `video` app
/// category (car app quality `DD-2` / `DD-3`).
///
/// Two obligations follow from `DD-2`, and this single predicate serves both:
/// audio must stop when driving starts, and it must not be resumable while
/// driving. The second obligation covers every path that can start audio, not
/// just OS media-session commands — a gapless track transition or queue
/// auto-advance landing just after driving starts must fail closed too.
///
/// Authority is the vehicle's own user-experience restrictions on the driver
/// display ([CarUxRestrictionsService]), which is the mechanism the platform
/// documents for apps that must separate "driving" from "not in the
/// foreground". Lifecycle state cannot make that distinction: the app is
/// equally not-resumed when the system covers it for driving and when a parked
/// driver opens navigation, so deriving authority from lifecycle alone silenced
/// parked background audio — something `DD-2` never asked for.
///
/// Where the vehicle cannot answer ([CarUxRestrictionState.unknown] — an older
/// head unit, a car service that failed to connect, or a driver display that
/// could not be resolved) the previous lifecycle rule still applies, including
/// its fail-closed treatment of a null state: a command arriving before the
/// first lifecycle message is denied, and nothing is playing that early, so the
/// strictness costs nothing.
bool automotivePlaybackAllowed({
  required bool isAutomotive,
  required AppLifecycleState? state,
  CarUxRestrictionState restrictions = CarUxRestrictionState.unknown,
}) {
  if (!isAutomotive) return true;
  return switch (restrictions) {
    CarUxRestrictionState.restricted => false,
    CarUxRestrictionState.unrestricted => true,
    CarUxRestrictionState.unknown => state == AppLifecycleState.resumed,
  };
}

/// [automotivePlaybackAllowed] against the ambient form factor, vehicle state
/// and lifecycle, for owners that hold no injected state of their own.
///
/// Short-circuits before reading [WidgetsBinding.instance] so this stays usable
/// from plain `test()` suites, where the binding is not initialized and the
/// `instance` getter throws.
bool automotivePlaybackAllowedNow() {
  if (!PlatformDetector.isAutomotive()) return true;
  final restrictions = CarUxRestrictionsService.instance.state;
  return automotivePlaybackAllowed(
    isAutomotive: true,
    state: restrictions == CarUxRestrictionState.unknown ? WidgetsBinding.instance.lifecycleState : null,
    restrictions: restrictions,
  );
}
