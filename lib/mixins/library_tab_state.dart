import 'package:flutter/material.dart';
import '../models/plex_library.dart';
import '../models/plex_metadata.dart';

/// Mixin providing common state management for library tab screens
/// Standardizes loading, error handling, and lifecycle management
mixin LibraryTabStateMixin<T extends StatefulWidget> on State<T> {
  /// The list of items to display
  List<PlexMetadata> get items;
  set items(List<PlexMetadata> value);

  /// Whether data is currently loading
  bool get isLoading;
  set isLoading(bool value);

  /// Error message if loading failed
  String? get errorMessage;
  set errorMessage(String? value);

  /// The library being displayed
  PlexLibrary get library;

  /// Load or reload the content
  Future<void> loadContent();

  /// Common lifecycle: reload if library changed
  @mustCallSuper
  void didUpdateLibrary(PlexLibrary oldLibrary) {
    if (oldLibrary.key != library.key) {
      loadContent();
    }
  }

  /// Helper to set loading state
  void setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  /// Helper to set error state
  void setErrorState(String? error) {
    if (mounted) {
      setState(() {
        errorMessage = error;
        isLoading = false;
      });
    }
  }

  /// Helper to set success state with items
  void setSuccessState(List<PlexMetadata> newItems) {
    if (mounted) {
      setState(() {
        items = newItems;
        isLoading = false;
        errorMessage = null;
      });
    }
  }
}
