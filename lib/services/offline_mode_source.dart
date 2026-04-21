import 'package:flutter/foundation.dart';

/// Minimal interface over "something that exposes an offline flag and notifies
/// listeners when it changes". Services depend on this instead of the concrete
/// provider class, keeping services/ free of provider imports.
///
/// `OfflineModeProvider` (in providers/) implements this.
abstract class OfflineModeSource implements Listenable {
  bool get isOffline;
}
