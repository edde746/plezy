import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'game_models.dart';

/// Read-only Steam manifest reader. Never opens loginusers, cookies, account
/// tokens, executables or arbitrary files requested by a remote peer.
class SteamLocalInventory {
  static const maxFileBytes = 2 * 1024 * 1024;
  static const maxGames = 2000;

  static List<String> defaultRoots() {
    final env = Platform.environment;
    final home = env['HOME'];
    if (Platform.isLinux && home != null) {
      return [
        p.join(home, '.local/share/Steam'),
        p.join(home, '.steam/steam'),
        p.join(home, '.var/app/com.valvesoftware.Steam/.local/share/Steam'),
      ];
    }
    if (Platform.isMacOS && home != null) return [p.join(home, 'Library/Application Support/Steam')];
    if (Platform.isWindows) {
      return [
        for (final key in ['ProgramFiles(x86)', 'ProgramFiles'])
          if (env[key] != null) p.join(env[key]!, 'Steam'),
      ];
    }
    return const [];
  }

  Future<SteamInventoryScan> scan({String? root, bool Function()? isCurrent}) async {
    final roots = root == null || root.isEmpty ? defaultRoots() : [root];
    final libraries = <String>{};
    var complete = true;
    var foundRoot = false;
    void check() {
      if (isCurrent?.call() == false) throw const SteamInventoryCancelled();
    }

    for (final candidate in roots) {
      check();
      if (!p.isAbsolute(candidate) || candidate.startsWith(r'\\')) continue;
      final directory = Directory(p.join(candidate, 'steamapps'));
      if (!await directory.exists()) continue;
      foundRoot = true;
      final canonical = await directory.resolveSymbolicLinks();
      if (!libraries.add(canonical)) continue;
      final folders = File(p.join(canonical, 'libraryfolders.vdf'));
      if (!await folders.exists()) continue; // Old Steam installs use only the root.
      try {
        final vdf = parseSteamKeyValues(await _read(folders));
        final values = vdf['libraryfolders'] ?? vdf['LibraryFolders'];
        if (values is! Map) {
          complete = false;
          continue;
        }
        for (final entry in values.entries.take(64)) {
          if (!RegExp(r'^\d+$').hasMatch(entry.key.toString())) continue;
          final path = entry.value is Map ? entry.value['path'] : entry.value;
          if (path is! String || path.length > 4096 || !p.isAbsolute(path) || path.startsWith(r'\\')) {
            complete = false;
            continue;
          }
          final folder = Directory(p.join(path, 'steamapps'));
          if (!await folder.exists()) {
            complete = false;
            continue;
          }
          if (libraries.length >= 32) {
            complete = false;
            break;
          }
          libraries.add(await folder.resolveSymbolicLinks());
        }
      } catch (_) {
        complete = false;
      }
    }
    if (!foundRoot) throw const FileSystemException('Steam library not found');
    final games = <int, SteamInstalledGame>{};
    var examined = 0;
    for (final library in libraries) {
      check();
      try {
        await for (final entity in Directory(library).list(followLinks: false)) {
          check();
          if (++examined > 10000 || games.length >= maxGames) {
            complete = false;
            break;
          }
          if (entity is! File) continue;
          final match = RegExp(r'^appmanifest_([1-9][0-9]{0,9})\.acf$').firstMatch(p.basename(entity.path));
          if (match == null) continue;
          try {
            final manifest = parseSteamKeyValues(await _read(entity))['AppState'];
            if (manifest is! Map) throw const FormatException('Missing AppState');
            final appId = int.tryParse(manifest['appid']?.toString() ?? '');
            if (appId == null || !validSteamAppId(appId) || '$appId' != match[1]) {
              throw const FormatException('Manifest identity mismatch');
            }
            final flags = int.tryParse(manifest['StateFlags']?.toString() ?? '');
            final game = SteamInstalledGame(
              appId: appId,
              name: manifest['name'] as String,
              installed: flags != null && flags & 4 != 0,
            );
            // A duplicate library may have an incomplete/stale download.
            if (games[appId]?.installed != true) games[appId] = game;
          } catch (_) {
            complete = false;
          }
        }
      } on SteamInventoryCancelled {
        rethrow;
      } catch (_) {
        complete = false;
      }
    }
    check();
    return SteamInventoryScan(
      games: games.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
      complete: complete,
    );
  }

  Future<String> _read(File file) async {
    final bytes = <int>[];
    await for (final chunk in file.openRead(0, maxFileBytes + 1)) {
      if (bytes.length + chunk.length > maxFileBytes) throw const FormatException('Steam metadata too large');
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }
}

class SteamInventoryScan {
  const SteamInventoryScan({required this.games, required this.complete});
  final List<SteamInstalledGame> games;
  final bool complete;
}

class SteamInventoryCancelled implements Exception {
  const SteamInventoryCancelled();
}

/// Bounded KeyValues subset used by Steam's text manifests. No includes,
/// directives, file access, interpolation or binary KeyValues are evaluated.
Map<String, Object> parseSteamKeyValues(String source) {
  if (source.length > SteamLocalInventory.maxFileBytes) throw const FormatException('KeyValues too large');
  var offset = 0, tokens = 0;
  String? next() {
    if (++tokens > 100000) throw const FormatException('Too many KeyValues tokens');
    while (offset < source.length) {
      if (source.codeUnitAt(offset) <= 32 || source.codeUnitAt(offset) == 0xfeff) {
        offset++;
        continue;
      }
      if (source.startsWith('//', offset)) {
        final newline = source.indexOf('\n', offset + 2);
        offset = newline < 0 ? source.length : newline + 1;
        continue;
      }
      break;
    }
    if (offset == source.length) return null;
    final char = source[offset++];
    if (char == '{' || char == '}') return char;
    if (char != '"') throw const FormatException('Expected quoted KeyValues string');
    final result = StringBuffer();
    while (offset < source.length) {
      final c = source[offset++];
      if (c == '"') return result.toString();
      if (c == '\\') {
        if (offset == source.length) break;
        final escaped = source[offset++];
        if (escaped != '\\' && escaped != '"') result.write('\\');
        result.write(escaped);
      } else {
        result.write(c);
      }
      if (result.length > 4096) throw const FormatException('KeyValues string too large');
    }
    throw const FormatException('Unterminated KeyValues string');
  }

  Map<String, Object> object(int depth) {
    if (depth > 16) throw const FormatException('KeyValues nesting too deep');
    final result = <String, Object>{};
    while (true) {
      final key = next();
      if (key == null) {
        if (depth != 0) throw const FormatException('Unclosed KeyValues object');
        return result;
      }
      if (key == '}') {
        if (depth == 0) throw const FormatException('Unexpected closing brace');
        return result;
      }
      if (key == '{' || key.startsWith('#') || result.containsKey(key)) {
        throw const FormatException('Invalid KeyValues key');
      }
      final value = next();
      if (value == null || value == '}') throw const FormatException('Missing KeyValues value');
      result[key] = value == '{' ? object(depth + 1) : value;
    }
  }

  return object(0);
}
