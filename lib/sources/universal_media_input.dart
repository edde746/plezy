import 'source_models.dart';

/// A media address that exists only for the current open/play session unless
/// the caller explicitly saves a credential-free HTTP(S) favorite.
class UniversalMediaItem {
  const UniversalMediaItem({required this.title, required this.uri, this.group = '', this.durationSeconds});

  final String title;
  final Uri uri;
  final String group;
  final int? durationSeconds;
}

class UniversalMediaPlaylist {
  const UniversalMediaPlaylist({required this.title, required this.items, this.skipped = 0, this.live = false});

  final String title;
  final List<UniversalMediaItem> items;
  final int skipped;
  final bool live;
}

/// Strict URI parsing shared by direct playback, playlist entries, and saved
/// favorites. No parser accepts credentials embedded in the URL authority.
class UniversalMediaAddress {
  static const maxLength = 4096;
  static const _webSchemes = {'http', 'https'};
  static const _mpvSchemes = {'rtsp', 'rtmp', 'rtmps', 'udp', 'rtp'};

  static bool usesMpvProtocol(Uri uri) => _mpvSchemes.contains(uri.scheme.toLowerCase());

  static Uri parse(String value, {required bool allowHttp, bool allowMpvProtocols = false, Uri? base}) {
    final input = value.trim();
    if (input.isEmpty || input.length > maxLength || input.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final parsed = Uri.tryParse(input);
    if (parsed == null) throw const SourceException(SourceFailure.invalidData);
    final uri = base != null && parsed.scheme.isEmpty ? base.resolveUri(parsed) : parsed;
    final scheme = uri.scheme.toLowerCase();
    final supported = _webSchemes.contains(scheme) || allowMpvProtocols && _mpvSchemes.contains(scheme);
    if (!supported ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        scheme == 'http' && !allowHttp) {
      throw const SourceException(SourceFailure.permission);
    }
    return uri;
  }

  /// Favorites live in profile-local preferences. Signed, password-bearing,
  /// and expiring URLs remain usable for this playback but cannot be persisted.
  static bool canSaveFavorite(Uri uri) {
    try {
      validatePublicSourceUri(uri, allowHttp: true);
      return true;
    } on SourceException {
      return false;
    }
  }
}

/// Parses the common radio/video playlist formats without interpreting remote
/// directives, local filesystem paths, player options, or embedded headers.
class UniversalMediaPlaylistParser {
  static const maxCharacters = 2 * 1024 * 1024;
  static const maxItems = 1000;
  static const maxLineLength = 16 * 1024;

  static bool isLiveHls(String value) {
    final lines = value.replaceAll('\r', '').split('\n').map((line) => line.trim().toUpperCase());
    var endList = false;
    var vod = false;
    var master = false;
    for (final line in lines) {
      if (line == '#EXT-X-ENDLIST') endList = true;
      if (line == '#EXT-X-PLAYLIST-TYPE:VOD') vod = true;
      if (line.startsWith('#EXT-X-STREAM-INF:') ||
          line.startsWith('#EXT-X-I-FRAME-STREAM-INF:') ||
          line.startsWith('#EXT-X-MEDIA:')) {
        master = true;
      }
    }
    return !endList && !vod && !master;
  }

  static UniversalMediaPlaylist parse(
    String value, {
    required String fallbackTitle,
    Uri? base,
    required bool allowHttp,
    bool allowMpvProtocols = false,
  }) {
    if (value.length > maxCharacters) throw const SourceException(SourceFailure.invalidData);
    final text = value.replaceFirst('\uFEFF', '').replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.trim().isEmpty) throw const SourceException(SourceFailure.invalidData);
    final lines = text.split('\n');
    if (lines.any((line) => line.length > maxLineLength)) throw const SourceException(SourceFailure.invalidData);
    final isPls = lines.any((line) => line.trim().toLowerCase() == '[playlist]');
    return isPls
        ? _parsePls(lines, fallbackTitle, base, allowHttp, allowMpvProtocols)
        : _parseM3u(lines, fallbackTitle, base, allowHttp, allowMpvProtocols);
  }

  static UniversalMediaPlaylist _parseM3u(
    List<String> lines,
    String fallbackTitle,
    Uri? base,
    bool allowHttp,
    bool allowMpvProtocols,
  ) {
    final hasHlsDirective = lines.any((line) => line.trimLeft().toUpperCase().startsWith('#EXT-X-'));
    // An HLS manifest is one playable media item. Its segments and variants
    // belong to the player; expanding them here would break adaptive playback.
    if (hasHlsDirective && base != null) {
      return UniversalMediaPlaylist(
        title: fallbackTitle,
        items: [
          UniversalMediaItem(
            title: fallbackTitle,
            uri: UniversalMediaAddress.parse(
              base.toString(),
              allowHttp: allowHttp,
              allowMpvProtocols: allowMpvProtocols,
            ),
          ),
        ],
        live: isLiveHls(lines.join('\n')),
      );
    }

    final items = <UniversalMediaItem>[];
    var pendingTitle = '';
    var pendingGroup = '';
    int? pendingDuration;
    var containsLiveInput = false;
    var skipped = 0;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.toUpperCase() == '#EXTM3U') continue;
      if (line.startsWith('#EXTINF:')) {
        final comma = line.indexOf(',');
        pendingTitle = comma >= 0 ? line.substring(comma + 1).trim() : '';
        pendingGroup = _attribute(line, 'group-title') ?? '';
        final durationText = line
            .substring('#EXTINF:'.length, comma < 0 ? line.length : comma)
            .trim()
            .split(RegExp(r'\s+'))
            .first;
        pendingDuration = int.tryParse(durationText);
        if (pendingDuration != null && pendingDuration < 0) containsLiveInput = true;
        continue;
      }
      if (line.startsWith('#')) continue;
      try {
        final uri = UniversalMediaAddress.parse(
          line,
          allowHttp: allowHttp,
          allowMpvProtocols: allowMpvProtocols,
          base: base,
        );
        items.add(
          UniversalMediaItem(
            title: _safeTitle(pendingTitle, uri),
            uri: uri,
            group: pendingGroup,
            durationSeconds: pendingDuration != null && pendingDuration >= 0 ? pendingDuration : null,
          ),
        );
      } on SourceException {
        skipped++;
      }
      pendingTitle = '';
      pendingGroup = '';
      pendingDuration = null;
      if (items.length > maxItems) throw const SourceException(SourceFailure.invalidData);
    }
    if (items.isEmpty) throw const SourceException(SourceFailure.invalidData);
    return UniversalMediaPlaylist(
      title: fallbackTitle,
      items: List.unmodifiable(items),
      skipped: skipped,
      live: containsLiveInput || items.any((item) => UniversalMediaAddress.usesMpvProtocol(item.uri)),
    );
  }

  static UniversalMediaPlaylist _parsePls(
    List<String> lines,
    String fallbackTitle,
    Uri? base,
    bool allowHttp,
    bool allowMpvProtocols,
  ) {
    final files = <int, String>{};
    final titles = <int, String>{};
    final lengths = <int, int>{};
    var playlistTitle = fallbackTitle;
    var declaredCount = 0;
    var containsLiveInput = false;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith(';') || line.startsWith('[')) continue;
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      final numbered = RegExp(r'^(File|Title|Length)(\d+)$', caseSensitive: false).firstMatch(key);
      if (numbered != null) {
        final index = int.tryParse(numbered.group(2)!);
        if (index == null || index < 1 || index > maxItems) continue;
        switch (numbered.group(1)!.toLowerCase()) {
          case 'file':
            files[index] = value;
          case 'title':
            titles[index] = value;
          case 'length':
            final duration = int.tryParse(value) ?? 0;
            lengths[index] = duration;
            if (duration < 0) containsLiveInput = true;
        }
      } else if (key.toLowerCase() == 'title' && value.isNotEmpty) {
        playlistTitle = value;
      } else if (key.toLowerCase() == 'numberofentries') {
        declaredCount = int.tryParse(value) ?? 0;
      }
    }
    if (declaredCount > maxItems || files.length > maxItems) throw const SourceException(SourceFailure.invalidData);
    final items = <UniversalMediaItem>[];
    var skipped = 0;
    for (final index in files.keys.toList()..sort()) {
      try {
        final uri = UniversalMediaAddress.parse(
          files[index]!,
          allowHttp: allowHttp,
          allowMpvProtocols: allowMpvProtocols,
          base: base,
        );
        items.add(
          UniversalMediaItem(
            title: _safeTitle(titles[index] ?? '', uri),
            uri: uri,
            durationSeconds: lengths[index] == null || lengths[index]! < 0 ? null : lengths[index],
          ),
        );
      } on SourceException {
        skipped++;
      }
    }
    if (items.isEmpty) throw const SourceException(SourceFailure.invalidData);
    return UniversalMediaPlaylist(
      title: playlistTitle,
      items: List.unmodifiable(items),
      skipped: skipped,
      live: containsLiveInput || items.any((item) => UniversalMediaAddress.usesMpvProtocol(item.uri)),
    );
  }

  static String? _attribute(String line, String name) {
    final match = RegExp('(?:^|\\s)${RegExp.escape(name)}="([^"]*)"', caseSensitive: false).firstMatch(line);
    return match?.group(1)?.trim();
  }

  static String _safeTitle(String candidate, Uri uri) {
    final title = candidate.trim().replaceAll(RegExp(r'[\x00-\x1f]'), '').trim();
    if (title.isNotEmpty) return title.length > 180 ? title.substring(0, 180) : title;
    return inferredMediaName(uri);
  }
}

String universalMediaMimeType(String name) {
  final extension = name.split('.').last.toLowerCase();
  return const {
        'm3u8': 'application/vnd.apple.mpegurl',
        'mp3': 'audio/mpeg',
        'm4a': 'audio/mp4',
        'mka': 'audio/x-matroska',
        'aac': 'audio/aac',
        'ac3': 'audio/ac3',
        'flac': 'audio/flac',
        'ogg': 'audio/ogg',
        'opus': 'audio/opus',
        'wav': 'audio/wav',
        'aif': 'audio/aiff',
        'aiff': 'audio/aiff',
        'wma': 'audio/x-ms-wma',
        'amr': 'audio/amr',
        'ape': 'audio/ape',
        'caf': 'audio/x-caf',
        'mid': 'audio/midi',
        'midi': 'audio/midi',
        'mp4': 'video/mp4',
        'mkv': 'video/x-matroska',
        'webm': 'video/webm',
        'mov': 'video/quicktime',
        'avi': 'video/x-msvideo',
        'flv': 'video/x-flv',
        'wmv': 'video/x-ms-wmv',
        'mpeg': 'video/mpeg',
        'mpg': 'video/mpeg',
        'm2ts': 'video/mp2t',
        'mts': 'video/mp2t',
        '3gp': 'video/3gpp',
        '3g2': 'video/3gpp2',
        'ogv': 'video/ogg',
        'vob': 'video/mpeg',
        'ts': 'video/mp2t',
      }[extension] ??
      'application/octet-stream';
}

String inferredMediaName(Uri uri) {
  if (uri.scheme != 'file') return uri.host;
  final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
  if (segments.isEmpty) return uri.host;
  final safe = segments.last.replaceAll(RegExp(r'[\x00-\x1f]'), '').trim();
  return safe.isEmpty ? uri.host : safe;
}
