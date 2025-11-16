import 'dart:async';

/// Notifier for triggering refreshes of library tabs
/// Singleton pattern for global access
class LibraryRefreshNotifier {
  static final LibraryRefreshNotifier _instance = LibraryRefreshNotifier._internal();

  factory LibraryRefreshNotifier() => _instance;

  LibraryRefreshNotifier._internal();

  // Stream controllers for different tab types
  final _collectionsController = StreamController<void>.broadcast();
  final _playlistsController = StreamController<void>.broadcast();

  // Streams that tabs can listen to
  Stream<void> get collectionsStream => _collectionsController.stream;
  Stream<void> get playlistsStream => _playlistsController.stream;

  // Methods to trigger refreshes
  void notifyCollectionsChanged() {
    if (!_collectionsController.isClosed) {
      _collectionsController.add(null);
    }
  }

  void notifyPlaylistsChanged() {
    if (!_playlistsController.isClosed) {
      _playlistsController.add(null);
    }
  }

  // Cleanup
  void dispose() {
    _collectionsController.close();
    _playlistsController.close();
  }
}
