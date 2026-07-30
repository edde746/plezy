import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../media/media_library.dart';
import '../providers/libraries_provider.dart';
import '../services/settings_service.dart';
import 'app_logger.dart';
import 'global_key_utils.dart';
import 'provider_extensions.dart';

bool prerollsEnabled() => (SettingsService.instanceOrNull?.read(SettingsService.playPrerollsBeforeMovies)) ?? false;

Future<MediaItem?> pickRandomPreroll(BuildContext context) async {
  final settingsService = await SettingsService.getInstance();
  if (!settingsService.read(SettingsService.playPrerollsBeforeMovies)) return null;

  final globalKey = settingsService.read(SettingsService.prerollLibraryGlobalKey);
  if (globalKey.isEmpty) return null;

  final selectedKeys = settingsService.read(SettingsService.prerollSelectedItemKeys);
  if (selectedKeys.isEmpty) return null;
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
    final shuffledKeys = [...selectedKeys]..shuffle(Random());
    for (final key in shuffledKeys) {
      final parsed = parseGlobalKey(key);
      if (parsed == null) continue;
      final item = await client.fetchItem(parsed.ratingKey);
      if (item != null) return item;
    }
    return null;
  } catch (e) {
    appLogger.w('Preroll fetch failed', error: e);
    return null;
  }
}
