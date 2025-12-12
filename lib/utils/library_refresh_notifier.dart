import 'dart:async';

/// Types of library refresh events
enum LibraryRefreshType { collections, playlists }

/// Notifier for triggering refreshes of library tabs.
///
/// Singleton pattern with reinitializable state. The controller is lazily
/// created and automatically recreated if disposed and later accessed.
class LibraryRefreshNotifier {
  static final LibraryRefreshNotifier _instance =
      LibraryRefreshNotifier._internal();

  factory LibraryRefreshNotifier() => _instance;

  LibraryRefreshNotifier._internal();

  /// Unified stream controller (lazily created, reinitializable)
  StreamController<LibraryRefreshType>? _controller;

  /// Ensure controller exists (creates if null or closed)
  StreamController<LibraryRefreshType> get _ensureController {
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<LibraryRefreshType>.broadcast();
    }
    return _controller!;
  }

  /// Unified stream of all refresh events
  Stream<LibraryRefreshType> get stream => _ensureController.stream;

  /// Stream for collections tab (backward compatible)
  Stream<void> get collectionsStream =>
      stream.where((t) => t == LibraryRefreshType.collections).map((_) {});

  /// Stream for playlists tab (backward compatible)
  Stream<void> get playlistsStream =>
      stream.where((t) => t == LibraryRefreshType.playlists).map((_) {});

  /// Notify that collections have changed
  void notifyCollectionsChanged() {
    _ensureController.add(LibraryRefreshType.collections);
  }

  /// Notify that playlists have changed
  void notifyPlaylistsChanged() {
    _ensureController.add(LibraryRefreshType.playlists);
  }

  /// Dispose controller (can be reinitialized later by accessing stream)
  void dispose() {
    _controller?.close();
    _controller = null;
  }
}
