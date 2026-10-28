import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

import '../sources/source_models.dart';
import '../sources/universal_media_input.dart';

class IptvPlaylistEntry {
  const IptvPlaylistEntry({
    required this.id,
    required this.title,
    required this.streamUrl,
    this.tvgId,
    this.number,
    this.groupTitle,
    this.logoUrl,
    this.radio = false,
    this.catchupSource,
    this.catchupDays,
    this.streamHeaders = const {},
  });

  final String id;
  final String title;
  final String streamUrl;
  final String? tvgId;
  final String? number;
  final String? groupTitle;
  final String? logoUrl;
  final bool radio;
  final String? catchupSource;
  final int? catchupDays;
  /// Only the standard playback presentation headers understood by common
  /// IPTV players are retained. Authentication and arbitrary headers from a
  /// playlist are deliberately ignored.
  final Map<String, String> streamHeaders;
}

class IptvPlaylistParseResult {
  const IptvPlaylistParseResult({required this.entries, required this.skipped, this.isHls = false, this.guideUri});

  final List<IptvPlaylistEntry> entries;
  final int skipped;
  final bool isHls;
  final Uri? guideUri;
}

/// Parses channel metadata, a following media URI, and a small allow-list of
/// playback presentation headers. Playlist-supplied auth headers, commands,
/// player properties and local paths are ignored.
class IptvPlaylistParser {
  static const maxCharacters = 8 * 1024 * 1024;
  static const maxEntries = 20_000;
  static const maxLineLength = 16 * 1024;
  static const _secretQueryKey = RegExp(
    r'(token|password|signature|credential|authorization|secret|api[_-]?key|^auth$|^key$|^code$|x-amz-|x-goog-|^(expires|expiry|expiration|policy|key-pair-id|sig|se|sp|sv|sr|st|skoid|sktid|skt|ske|sks|skv|rscc|rscd|rsct)$)',
    caseSensitive: false,
  );

  static IptvPlaylistParseResult parse(String body, {required Uri base, required bool allowHttp}) {
    if (body.length > maxCharacters) throw const SourceException(SourceFailure.invalidData);
    final lines = body.replaceFirst('\uFEFF', '').replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    if (lines.any((line) => line.length > maxLineLength)) throw const SourceException(SourceFailure.invalidData);
    if (lines.any((line) => line.trimLeft().toUpperCase().startsWith('#EXT-X-'))) {
      return const IptvPlaylistParseResult(entries: [], skipped: 0, isHls: true);
    }
    Uri? guideUri;
    String? header;
    for (final line in lines) {
      final candidate = line.trim();
      if (candidate.toUpperCase().startsWith('#EXTM3U')) {
        header = candidate;
        break;
      }
    }
    if (header != null) {
      final guideAddress = _first(_parseAttributes(header.substring(7)), const ['url-tvg', 'x-tvg-url', 'tvg-url']);
      if (guideAddress != null) {
        try {
          guideUri = UniversalMediaAddress.parse(guideAddress, allowHttp: allowHttp, base: base);
        } on Object {
          // A malformed optional guide address does not invalidate channels.
        }
      }
    }

    final result = <IptvPlaylistEntry>[];
    var skipped = 0;
    var attributes = <String, String>{};
    var title = '';
    double? durationSeconds;
    var pending = false;
    final streamHeaders = <String, String>{};
    final duplicateIds = <String, int>{};

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.toUpperCase().startsWith('#EXTINF:')) {
        if (pending) skipped++;
        final parsed = _parseExtInf(line.substring(8));
        attributes = parsed.$1;
        title = _clean(parsed.$2, 240);
        durationSeconds = parsed.$3;
        streamHeaders.clear();
        pending = true;
        continue;
      }
      if (pending && line.startsWith('#EXTVLCOPT:')) {
        final option = line.substring('#EXTVLCOPT:'.length);
        final separator = option.indexOf('=');
        if (separator > 0) {
          _addPlaybackHeader(streamHeaders, option.substring(0, separator), option.substring(separator + 1));
        }
        continue;
      }
      if (pending && line.startsWith('#EXTHTTP:')) {
        final payload = line.substring('#EXTHTTP:'.length).trim();
        if (payload.length <= 4096) {
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map) {
              for (final item in decoded.entries) {
                if (item.key is String && item.value is String) {
                  _addPlaybackHeader(streamHeaders, item.key as String, item.value as String);
                }
              }
            }
          } on FormatException {
            // Malformed optional player metadata does not invalidate channels.
          }
        }
        continue;
      }
      if (line.startsWith('#')) continue;
      if (!pending) continue;
      pending = false;
      if (durationSeconds != null && durationSeconds! > 0) {
        // Finite-duration entries are VOD items. The Live TV import keeps
        // the guide free of movies and episodes until the library adapter is
        // available for this source.
        skipped++;
        attributes = <String, String>{};
        title = '';
        durationSeconds = null;
        continue;
      }
      try {
        final uri = UniversalMediaAddress.parse(line, allowHttp: allowHttp, allowMpvProtocols: true, base: base);
        final displayTitle = _clean(
          _first(attributes, const ['tvg-name', 'channel-name']) ?? title,
          240,
        );
        if (displayTitle.isEmpty) {
          skipped++;
          continue;
        }
        final tvgId = _cleanNullable(_first(attributes, const ['tvg-id', 'tvgid']), 180);
        final number = _cleanNullable(_first(attributes, const ['tvg-chno', 'channel-number']), 32);
        final group = _cleanNullable(_first(attributes, const ['group-title', 'group']), 120);
        final logo = _safeLogo(_first(attributes, const ['tvg-logo', 'logo']), base, allowHttp);
        final identity = tvgId?.toLowerCase() ?? [
          number?.toLowerCase() ?? '',
          group?.toLowerCase() ?? '',
          displayTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim(),
          uri.host.toLowerCase(),
          uri.path.toLowerCase(),
        ].join('|');
        final baseId = tvgId == null ? 'local-${sha256.convert(identity.codeUnits).toString().substring(0, 24)}' : tvgId;
        final duplicateIndex = duplicateIds.update(baseId, (value) => value + 1, ifAbsent: () => 0);
        final id = duplicateIndex == 0 ? baseId : '$baseId#$duplicateIndex';
        final radio = _first(attributes, const ['radio'])?.toLowerCase() == 'true' ||
            _first(attributes, const ['radio']) == '1' ||
            (group?.toLowerCase().contains('radio') ?? false);
        result.add(
          IptvPlaylistEntry(
            id: id,
            title: displayTitle,
            streamUrl: uri.toString(),
            tvgId: tvgId,
            number: number,
            groupTitle: group,
            logoUrl: logo,
            radio: radio,
            catchupSource: _safeCatchupSource(_first(attributes, const ['catchup-source', 'catchup_source'])),
            catchupDays: _catchupDays(_first(attributes, const ['catchup-days', 'catchup_days'])),
            streamHeaders: Map.unmodifiable(streamHeaders),
          ),
        );
        if (result.length > maxEntries) throw const SourceException(SourceFailure.invalidData);
      } on SourceException {
        skipped++;
      } on FormatException {
        skipped++;
      }
      attributes = <String, String>{};
      streamHeaders.clear();
      title = '';
      durationSeconds = null;
    }
    if (pending) skipped++;
    if (result.isEmpty) throw const SourceException(SourceFailure.invalidData);
    return IptvPlaylistParseResult(entries: List.unmodifiable(result), skipped: skipped, guideUri: guideUri);
  }

  static (Map<String, String>, String, double?) _parseExtInf(String value) {
    var comma = -1;
    var quoted = false;
    for (var i = 0; i < value.length; i++) {
      if (value[i] == '"') quoted = !quoted;
      if (value[i] == ',' && !quoted) {
        comma = i;
        break;
      }
    }
    final header = comma < 0 ? value : value.substring(0, comma);
    final title = comma < 0 ? '' : value.substring(comma + 1).trim();
    final attrs = _parseAttributes(header);
    final duration = RegExp(r'^\s*([+-]?\d+(?:\.\d+)?)').firstMatch(header);
    return (attrs, title, duration == null ? null : double.tryParse(duration.group(1)!));
  }

  static Map<String, String> _parseAttributes(String value) {
    final attrs = <String, String>{};
    final pattern = RegExp(r'([A-Za-z0-9_-]+)\s*=\s*(?:"((?:[^"]|"")*)"|([^\s,]+))');
    for (final match in pattern.allMatches(value)) {
      attrs[match.group(1)!.toLowerCase()] = (match.group(2) ?? match.group(3) ?? '').replaceAll('""', '"');
    }
    return attrs;
  }

  static String? _first(Map<String, String> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key]?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String _clean(String value, int max) => value.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim().substring(
    0,
    value.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim().length.clamp(0, max).toInt(),
  );

  static String? _cleanNullable(String? value, int max) => value == null ? null : _clean(value, max).ifNotEmpty;

  static String? _safeLogo(String? value, Uri base, bool allowHttp) {
    if (value == null || value.length > 2048) return null;
    try {
      final uri = UniversalMediaAddress.parse(value, allowHttp: allowHttp, base: base);
      if (uri.queryParameters.keys.any(_secretQueryKey.hasMatch)) return null;
      return uri.toString();
    } on Object {
      return null;
    }
  }

  static String? _safeCatchupSource(String? value) {
    if (value == null || value.length > 4096 || value.contains(RegExp(r'[\x00-\x1f\x7f]'))) return null;
    final normalized = value.replaceAll('&amp;', '&').trim();
    if (normalized.isEmpty ||
        !RegExp(r'\{(?:utc|utcstart|utcend|lutc|duration|start|end)\}|%(?:s|Y|m|d|H|M|S)').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  static int? _catchupDays(String? value) {
    final days = int.tryParse(value ?? '');
    if (days == null || days <= 0 || days > 3650) return null;
    return days;
  }

  static void _addPlaybackHeader(Map<String, String> headers, String rawName, String rawValue) {
    final name = switch (rawName.trim().toLowerCase()) {
      'http-user-agent' || 'user-agent' => 'User-Agent',
      'http-referrer' || 'referer' || 'referrer' => 'Referer',
      'http-origin' || 'origin' => 'Origin',
      _ => null,
    };
    final value = rawValue.trim();
    if (name == null || value.isEmpty || value.length > 1024 || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) return;
    headers[name] = value;
  }
}

extension on String {
  String? get ifNotEmpty => isEmpty ? null : this;
}

class IptvXmltvParseResult {
  const IptvXmltvParseResult({required this.channelLogos, required this.programmes, required this.skipped});
  final Map<String, String> channelLogos;
  final List<IptvXmltvProgramme> programmes;
  final int skipped;
}

class IptvXmltvProgramme {
  const IptvXmltvProgramme({
    required this.channelTvgId,
    required this.beginsAt,
    required this.endsAt,
    required this.title,
    this.summary,
    this.category,
    this.episodeId,
    this.thumb,
  });

  final String channelTvgId;
  final int beginsAt;
  final int endsAt;
  final String title;
  final String? summary;
  final String? category;
  final String? episodeId;
  final String? thumb;
}

class IptvXmltvParser {
  static const maxCharacters = 16 * 1024 * 1024;
  static const maxProgrammes = 300_000;

  static IptvXmltvParseResult parse(String body, {required Uri base, required bool allowHttp}) {
    if (body.length > maxCharacters || RegExp(r'<!\s*(DOCTYPE|ENTITY)', caseSensitive: false).hasMatch(body)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final XmlDocument document;
    try {
      document = XmlDocument.parse(body);
    } on XmlException {
      throw const SourceException(SourceFailure.invalidData);
    }
    if (document.rootElement.name.local != 'tv') throw const SourceException(SourceFailure.invalidData);

    final logos = <String, String>{};
    for (final channel in document.rootElement.findElements('channel')) {
      final id = channel.getAttribute('id')?.trim();
      final icon = channel.findElements('icon').firstOrNull?.getAttribute('src');
      if (id == null || id.isEmpty || icon == null) continue;
      try {
        final uri = UniversalMediaAddress.parse(icon, allowHttp: allowHttp, base: base);
        if (!uri.queryParameters.keys.any(IptvPlaylistParser._secretQueryKey.hasMatch)) logos[id] = uri.toString();
      } on Object {
        // Invalid, credential-bearing or disallowed HTTP artwork is ignored.
      }
    }

    final programmes = <IptvXmltvProgramme>[];
    var skipped = 0;
    for (final node in document.rootElement.findElements('programme')) {
      if (programmes.length >= maxProgrammes) throw const SourceException(SourceFailure.invalidData);
      final channelId = node.getAttribute('channel')?.trim();
      final beginsAt = _xmltvEpoch(node.getAttribute('start'));
      final endsAt = _xmltvEpoch(node.getAttribute('stop'));
      final title = _cleanXml(node.findElements('title').firstOrNull?.innerText ?? '', 240);
      final icon = node.findElements('icon').firstOrNull?.getAttribute('src');
      if (channelId == null || beginsAt == null || endsAt == null || endsAt <= beginsAt || title.isEmpty) {
        skipped++;
        continue;
      }
      programmes.add(
        IptvXmltvProgramme(
          channelTvgId: channelId,
          beginsAt: beginsAt,
          endsAt: endsAt,
          title: title,
          summary: _cleanXmlNullable(node.findElements('desc').firstOrNull?.innerText, 1200),
          category: _cleanXmlNullable(node.findElements('category').firstOrNull?.innerText, 100),
          episodeId: _cleanXmlNullable(node.findElements('episode-num').firstOrNull?.innerText, 180),
          thumb: IptvPlaylistParser._safeLogo(icon, base, allowHttp),
        ),
      );
    }
    return IptvXmltvParseResult(
      channelLogos: Map.unmodifiable(logos),
      programmes: List.unmodifiable(programmes),
      skipped: skipped,
    );
  }

  static int? _xmltvEpoch(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{14})(?:\s*([+-])(\d{2})(\d{2}))?$').firstMatch(value.trim());
    if (match == null) return null;
    final raw = match.group(1)!;
    final wall = DateTime.utc(
      int.parse(raw.substring(0, 4)),
      int.parse(raw.substring(4, 6)),
      int.parse(raw.substring(6, 8)),
      int.parse(raw.substring(8, 10)),
      int.parse(raw.substring(10, 12)),
      int.parse(raw.substring(12, 14)),
    );
    final sign = match.group(2);
    if (sign == null) return wall.millisecondsSinceEpoch ~/ 1000;
    final offset = (int.parse(match.group(3)!) * 60 + int.parse(match.group(4)!)) * 60;
    final seconds = wall.millisecondsSinceEpoch ~/ 1000;
    return seconds - (sign == '+' ? offset : -offset);
  }

  static String _cleanXml(String value, int max) {
    final cleaned = value.replaceAll(RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]'), '').trim();
    return cleaned.substring(0, cleaned.length.clamp(0, max).toInt());
  }

  static String? _cleanXmlNullable(String? value, int max) => value == null ? null : _cleanXml(value, max).ifNotEmpty;
}

extension on Iterable<XmlElement> {
  XmlElement? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
