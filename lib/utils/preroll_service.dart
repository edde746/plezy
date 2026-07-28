import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../media/library_query.dart';
import '../media/media_item.dart';
import '../media/media_library.dart';
import '../providers/libraries_provider.dart';
import '../services/settings_service.dart';
import 'app_logger.dart';
import 'provider_extensions.dart';

Future<MediaItem?> pickRandomPreroll(BuildContext context) async {
  final settingsService = await SettingsService.getInstance();
  if (!settingsService.read(SettingsService.playPrerollsBeforeMovies)) return null;

  final globalKey = settingsService.read(SettingsService.prerollLibraryGlobalKey);
  if (globalKey.isEmpty) return null;
  if (!context.mounted) return null;

  final libraries = context.read<LibrariesProvider>().libraries;
  MediaLibrary? library;
  for (final candidate in libraries) {
    if (candidate.globalKey == globalKey) {
      library = candidate;
      break;
    }
  }
  if (library == null) return null;

  try {
    final client = context.getMediaClientForLibrary(library);
    final page = await client.fetchLibraryContent(library.id, LibraryQuery(limit: 200));
    if (page.items.isEmpty) return null;

    final selectedKeys = settingsService.read(SettingsService.prerollSelectedItemKeys).toSet();
    final candidates = selectedKeys.isEmpty
        ? page.items
        : page.items.where((item) => selectedKeys.contains(item.globalKey)).toList();
    if (candidates.isEmpty) return null;

    return candidates[Random().nextInt(candidates.length)];
  } catch (e) {
    appLogger.w('Preroll fetch failed', error: e);
    return null;
  }
}
