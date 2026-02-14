/// Web TV detection implementation.
///
/// On web, always returns true since the web build targets webOS TV.
library;

/// Detect if running on a TV platform (web).
/// The web build of Plezy is designed for webOS TV.
Future<bool> detectTV() async {
  return true;
}
