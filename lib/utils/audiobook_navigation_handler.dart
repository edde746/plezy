import 'package:flutter/material.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../screens/author_books_screen.dart';
import '../screens/audiobook_detail_screen.dart';
import '../utils/audiobook_player_navigation.dart';

/// Handles navigation for audiobook-related content types
///
/// For audiobooks, Plex uses music library types:
/// - type: "artist" = Author (shows list of books by author)
/// - type: "album" = Book (shows book detail with chapters)
/// - type: "track" = Chapter (plays audio)
class AudiobookNavigationHandler {
  /// Handles navigation based on audiobook item type
  ///
  /// Returns true if the item was handled as audiobook content
  static Future<bool> handleAudiobookNavigation({
    required BuildContext context,
    required PlexMetadata item,
    required PlexClient client,
    Function(String)? onRefresh,
  }) async {
    final itemType = item.type.toLowerCase();

    // Check if this is audiobook content
    if (itemType != 'artist' && itemType != 'album' && itemType != 'track') {
      return false;
    }

    if (itemType == 'artist') {
      await _navigateToAuthor(context, item, onRefresh);
    } else if (itemType == 'album') {
      await _navigateToBook(context, item, onRefresh);
    } else if (itemType == 'track') {
      await _navigateToChapter(context, item, client, onRefresh);
    }

    return true;
  }

  static Future<void> _navigateToAuthor(
    BuildContext context,
    PlexMetadata item,
    Function(String)? onRefresh,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthorBooksScreen(author: item),
      ),
    );
    onRefresh?.call(item.ratingKey);
  }

  static Future<void> _navigateToBook(
    BuildContext context,
    PlexMetadata item,
    Function(String)? onRefresh,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AudiobookDetailScreen(book: item),
      ),
    );
    if (result == true) {
      onRefresh?.call(item.ratingKey);
    }
  }

  static Future<void> _navigateToChapter(
    BuildContext context,
    PlexMetadata item,
    PlexClient client,
    Function(String)? onRefresh,
  ) async {
    // Try to get all chapters for the parent book to enable sequential playback
    List<PlexMetadata>? playlist;
    int initialIndex = 0;

    try {
      if (item.parentRatingKey != null) {
        final chapters = await client.getChildren(item.parentRatingKey!);
        if (chapters.isNotEmpty) {
          playlist = chapters;
          // Find the index of the current track
          initialIndex = chapters.indexWhere(
            (c) => c.ratingKey == item.ratingKey,
          );
          if (initialIndex < 0) initialIndex = 0;
        }
      }
    } catch (e) {
      // If we can't load the playlist, just play the single track
    }

    if (context.mounted) {
      final result = await navigateToAudiobookPlayer(
        context,
        metadata: item,
        playlist: playlist,
        initialIndex: initialIndex,
      );
      if (result == true) {
        onRefresh?.call(item.ratingKey);
      }
    }
  }
}
