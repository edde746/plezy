import 'package:flutter/foundation.dart' show kIsWeb;

/// Performance optimization utilities for webOS TV.
///
/// TV hardware has limited CPU/GPU compared to desktop/mobile.
/// These helpers reduce animation complexity and memory usage.
class WebOSPerformance {
  WebOSPerformance._();

  /// Whether to use reduced animations (simpler transitions on TV).
  static bool get useReducedAnimations => kIsWeb;

  /// Recommended animation duration for TV (slower for readability).
  static Duration get defaultAnimationDuration =>
      kIsWeb ? const Duration(milliseconds: 200) : const Duration(milliseconds: 300);

  /// Maximum number of concurrent image loads on TV.
  static int get maxConcurrentImageLoads => kIsWeb ? 4 : 8;

  /// Whether to disable blur effects (expensive on TV GPU).
  static bool get disableBlurEffects => kIsWeb;

  /// Whether to disable shadow effects (expensive on TV GPU).
  static bool get disableShadowEffects => false; // Shadows are usually OK

  /// Maximum image cache size in bytes for the platform.
  static int get imageCacheSize => kIsWeb ? 100 * 1024 * 1024 : 200 * 1024 * 1024;

  /// Whether to lazy-load off-screen content aggressively.
  static bool get aggressiveLazyLoading => kIsWeb;
}
