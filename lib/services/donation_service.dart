import 'package:plezy/utils/platform_detector.dart';

class DonationService {
  static const String donationUrl = 'https://liberapay.com/edde746';

  /// Suppressed inside a packaged (MSIX/Store) install: Microsoft Store policy
  /// treats a link that solicits payment outside the Store as a commerce
  /// mechanism, so the tile is a certification risk there. Every other Windows
  /// build shape and every other platform keeps it.
  static bool get isEnabled {
    return const bool.fromEnvironment('ENABLE_DONATIONS', defaultValue: false) && !PlatformDetector.isPackagedInstall();
  }
}
