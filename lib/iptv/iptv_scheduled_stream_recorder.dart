import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../sources/source_transport.dart';

/// Captures direct HTTP streams and AES-128 or clear HLS while PlezyNG is
/// running. HLS media segments are concatenated in playlist order.
class IptvScheduledStreamRecorder {
  IptvScheduledStreamRecorder({
    required this.uri,
    required this.allowHttp,
    this.headers = const {},
    required this.outputFile,
    required this.endsAt,
  });

  final Uri uri;
  final bool allowHttp;
  final Map<String, String> headers;
  final File outputFile;
  final DateTime endsAt;

  SourceTransport? _transport;
  StreamSubscription<List<int>>? _subscription;
  Completer<void>? _directDone;
  Timer? _stopTimer;
  bool _stopped = false;

  Future<String> record() async {
    if (uri.path.toLowerCase().endsWith('.m3u8')) {
      return _recordHls(uri);
    }
    if (await _recordDirect(uri)) return _recordHls(uri);
    final filename = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final extension = RegExp(r'\.(ts|mp2t|m2ts|mp4|m4v|mkv|mp3|aac|m4a|mpg|mpeg|webm)$', caseSensitive: false)
        .firstMatch(filename)
        ?.group(1)
        ?.toLowerCase();
    return extension == null ? '.ts' : '.$extension';
  }

  Future<void> stop() async {
    _stopped = true;
    _stopTimer?.cancel();
    await _subscription?.cancel();
    final directDone = _directDone;
    if (directDone != null && !directDone.isCompleted) directDone.complete();
    _transport?.close();
  }

  Future<bool> _recordDirect(Uri source) async {
    final transport = SourceTransport(allowHttp: allowHttp);
    _transport = transport;
    final response = await transport.send('GET', source, headers: headers, redirects: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>();
      SourceTransport.check(response.statusCode);
    }
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('mpegurl') || contentType.contains('x-mpegurl')) {
      await response.stream.drain<void>();
      transport.close();
      _transport = null;
      return true;
    }
    final sink = outputFile.openWrite(mode: FileMode.writeOnly);
    final done = Completer<void>();
    _directDone = done;
    var reachedScheduledEnd = false;
    late final StreamSubscription<List<int>> subscription;
    void finish([Object? error, StackTrace? stackTrace]) {
      if (done.isCompleted) return;
      if (error == null) {
        done.complete();
      } else {
        done.completeError(error, stackTrace ?? StackTrace.current);
      }
    }

    subscription = response.stream.listen(
      sink.add,
      onError: (Object error, StackTrace stackTrace) => finish(error, stackTrace),
      onDone: finish,
      cancelOnError: true,
    );
    _subscription = subscription;
    _stopTimer = Timer(
      endsAt.difference(DateTime.now()).isNegative ? Duration.zero : endsAt.difference(DateTime.now()),
      () {
        reachedScheduledEnd = true;
        _stopped = true;
        unawaited(subscription.cancel().then((_) => finish()));
      },
    );
    try {
      await done.future;
      if (!reachedScheduledEnd && !_stopped && DateTime.now().isBefore(endsAt)) {
        throw const FileSystemException('Stream ended before the scheduled programme ended');
      }
    } finally {
      _stopTimer?.cancel();
      await subscription.cancel();
      await sink.flush();
      await sink.close();
      transport.close();
      _transport = null;
      _directDone = null;
    }
    if (_stopped && await outputFile.length() == 0) throw const FileSystemException('No stream data received');
    return false;
  }

  Future<String> _recordHls(Uri source) async {
    final transport = SourceTransport(allowHttp: allowHttp);
    _transport = transport;
    _stopTimer = Timer(
      endsAt.difference(DateTime.now()).isNegative ? Duration.zero : endsAt.difference(DateTime.now()),
      () => _stopped = true,
    );
    final sink = outputFile.openWrite(mode: FileMode.writeOnly);
    final seen = <String>{};
    var playlistUri = source;
    var wroteAny = false;
    var fragmentedMp4 = false;
    final keyCache = <String, Uint8List>{};
    try {
      while (!_stopped && DateTime.now().isBefore(endsAt)) {
        var text = await transport.text('GET', playlistUri, headers: headers, limit: 1024 * 1024, redirects: true);
        final master = _masterVariant(text, playlistUri);
        if (master != null) {
          playlistUri = master;
          text = await transport.text('GET', playlistUri, headers: headers, limit: 1024 * 1024, redirects: true);
        }
        final parsed = _parseMediaPlaylist(text, playlistUri);
        fragmentedMp4 = fragmentedMp4 || parsed.initializationMap != null;
        final initRange = parsed.initializationRange;
        final mapIdentity = parsed.initializationMap == null
            ? null
            : 'map:${playlistUri.resolve(parsed.initializationMap!)}:${initRange?.offset}:${initRange?.length}';
        if (parsed.initializationMap != null && seen.add(mapIdentity!)) {
          final mapUri = playlistUri.resolve(parsed.initializationMap!);
          final encryptedMap = await _readResource(transport, mapUri, range: parsed.initializationRange);
          final mapBytes = parsed.initializationKey == null
              ? encryptedMap
              : _decryptHlsSegment(
                  encryptedMap,
                  await _keyBytes(transport, playlistUri.resolve(parsed.initializationKey!.uri), keyCache),
                  parsed.initializationKey!.iv ??
                      _sequenceIv(parsed.initializationSequence, requireExplicit: true),
                );
          sink.add(mapBytes);
        }
        for (final segment in parsed.segments) {
          if (_stopped || !DateTime.now().isBefore(endsAt)) break;
          final segmentUri = playlistUri.resolve(segment.uri);
          final key = '${segment.sequence}:$segmentUri';
          if (!seen.add(key)) continue;
          final encryptedSegment = await _readResource(transport, segmentUri, range: segment.range);
          final segmentBytes = segment.key == null
              ? encryptedSegment
              : _decryptHlsSegment(
                  encryptedSegment,
                  await _keyBytes(transport, playlistUri.resolve(segment.key!.uri), keyCache),
                  segment.key!.iv ?? _sequenceIv(segment.sequence),
                );
          if (segmentBytes.isEmpty) throw const FileSystemException('Empty HLS media segment');
          sink.add(segmentBytes);
          wroteAny = true;
        }
        if (parsed.endList) break;
        final seconds = parsed.targetDuration.clamp(1, 8).toInt();
        await Future<void>.delayed(Duration(seconds: seconds));
      }
      await sink.flush();
      if (!wroteAny) throw const FileSystemException('No HLS media segments received');
      return fragmentedMp4 ? '.mp4' : '.ts';
    } finally {
      _stopTimer?.cancel();
      await sink.close();
      transport.close();
      _transport = null;
    }
  }

  Future<Uint8List> _readResource(SourceTransport transport, Uri resource, {_IptvHlsRange? range}) async {
    final response = await transport.send(
      'GET',
      resource,
      headers: {
        ...headers,
        if (range != null) 'Range': 'bytes=${range.offset}-${range.offset + range.length - 1}',
      },
      redirects: true,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>();
      SourceTransport.check(response.statusCode);
    }
    if (range != null) {
      final contentRange = response.headers['content-range'];
      final match = contentRange == null ? null : RegExp(r'^bytes (\d+)-(\d+)/', caseSensitive: false).firstMatch(contentRange);
      if (response.statusCode != 206 ||
          match == null ||
          int.tryParse(match.group(1) ?? '') != range.offset ||
          int.tryParse(match.group(2) ?? '') != range.offset + range.length - 1) {
        await response.stream.drain<void>();
        throw const FileSystemException('IPTV server did not honor the HLS byte range');
      }
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(const Duration(seconds: 45))) {
      if (_stopped || !DateTime.now().isBefore(endsAt)) break;
      if (bytes.length + chunk.length > 64 * 1024 * 1024) {
        throw const FileSystemException('HLS resource is too large');
      }
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  Future<Uint8List> _keyBytes(
    SourceTransport transport,
    Uri keyUri,
    Map<String, Uint8List> cache,
  ) async {
    final key = keyUri.toString();
    final cached = cache[key];
    if (cached != null) return cached;
    final response = await transport.send('GET', keyUri, headers: headers, redirects: true);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>();
      SourceTransport.check(response.statusCode);
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(const Duration(seconds: 20))) {
      if (bytes.length + chunk.length > 16) throw const FileSystemException('Invalid HLS encryption key');
      bytes.add(chunk);
    }
    final resolved = bytes.takeBytes();
    if (resolved.length != 16) throw const FileSystemException('Invalid HLS encryption key');
    cache[key] = resolved;
    return resolved;
  }

  static Uint8List _decryptHlsSegment(Uint8List ciphertext, Uint8List key, Uint8List iv) {
    if (ciphertext.isEmpty || ciphertext.length % 16 != 0 || key.length != 16 || iv.length != 16) {
      throw const FileSystemException('Invalid AES-128 HLS segment');
    }
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV<KeyParameter>(KeyParameter(key), iv));
    final padded = Uint8List(ciphertext.length);
    for (var offset = 0; offset < ciphertext.length; offset += cipher.blockSize) {
      cipher.processBlock(ciphertext, offset, padded, offset);
    }
    final paddingLength = padded.last;
    if (paddingLength < 1 || paddingLength > cipher.blockSize ||
        !padded.sublist(padded.length - paddingLength).every((byte) => byte == paddingLength)) {
      throw const FileSystemException('Invalid AES-128 HLS padding');
    }
    return Uint8List.sublistView(padded, 0, padded.length - paddingLength);
  }

  static Uint8List _sequenceIv(int sequence, {bool requireExplicit = false}) {
    if (requireExplicit) throw const UnsupportedError('AES-128 HLS initialization maps need an explicit IV');
    if (sequence < 0) throw const FileSystemException('Invalid HLS media sequence');
    final iv = Uint8List(16);
    var value = sequence;
    for (var index = iv.length - 1; index >= 0 && value > 0; index--) {
      iv[index] = value & 0xff;
      value >>= 8;
    }
    if (value != 0) throw const FileSystemException('Invalid HLS media sequence');
    return iv;
  }

  Uri? _masterVariant(String text, Uri base) {
    final lines = const LineSplitter().convert(text);
    final variants = <({int bandwidth, Uri uri})>[];
    int? bandwidth;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        final match = RegExp(r'(?:^|,)BANDWIDTH=(\d+)').firstMatch(line.substring('#EXT-X-STREAM-INF:'.length));
        bandwidth = int.tryParse(match?.group(1) ?? '') ?? 0;
      } else if (bandwidth != null && line.isNotEmpty && !line.startsWith('#')) {
        variants.add((bandwidth: bandwidth, uri: base.resolve(line)));
        bandwidth = null;
      }
    }
    if (variants.isEmpty) return null;
    variants.sort((a, b) => b.bandwidth.compareTo(a.bandwidth));
    return variants.first.uri;
  }

  _IptvHlsPlaylist _parseMediaPlaylist(String text, Uri base) {
    final lines = const LineSplitter().convert(text);
    final segments = <_IptvHlsSegment>[];
    var sequence = 0;
    var target = 4;
    var endList = false;
    String? initializationMap;
    _IptvHlsRange? initializationRange;
    _IptvHlsEncryption? currentKey;
    _IptvHlsEncryption? initializationKey;
    var initializationSequence = 0;
    String? pendingByteRange;
    final nextByteRangeOffset = <String, int>{};
    for (final raw in lines) {
      final line = raw.trim();
      if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
        sequence = int.tryParse(line.substring('#EXT-X-MEDIA-SEQUENCE:'.length)) ?? 0;
      } else if (line.startsWith('#EXT-X-TARGETDURATION:')) {
        target = int.tryParse(line.substring('#EXT-X-TARGETDURATION:'.length)) ?? target;
      } else if (line.startsWith('#EXT-X-KEY:')) {
        final attributes = _parseHlsAttributes(line.substring('#EXT-X-KEY:'.length));
        final method = attributes['METHOD']?.toUpperCase();
        if (method == 'NONE') {
          currentKey = null;
        } else if (method == 'AES-128') {
          final keyUri = attributes['URI'];
          if (keyUri == null || keyUri.isEmpty ||
              (attributes['KEYFORMAT'] != null && attributes['KEYFORMAT'] != 'identity')) {
            throw const UnsupportedError('Unsupported HLS encryption key format');
          }
          currentKey = _IptvHlsEncryption(uri: keyUri, iv: _parseIv(attributes['IV']));
        } else {
          throw const UnsupportedError('Unsupported encrypted HLS method');
        }
      } else if (line.startsWith('#EXT-X-MAP:')) {
        final attributes = _parseHlsAttributes(line.substring('#EXT-X-MAP:'.length));
        initializationMap = attributes['URI'];
        initializationRange = initializationMap == null || attributes['BYTERANGE'] == null
            ? null
            : _parseByteRange(
                attributes['BYTERANGE']!,
                base.resolve(initializationMap).toString(),
                nextByteRangeOffset,
              );
        initializationKey = currentKey;
        initializationSequence = sequence;
      } else if (line.startsWith('#EXT-X-BYTERANGE:')) {
        pendingByteRange = line.substring('#EXT-X-BYTERANGE:'.length).trim();
      } else if (line == '#EXT-X-ENDLIST') {
        endList = true;
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        final resourceUri = base.resolve(line).toString();
        final range = pendingByteRange == null ? null : _parseByteRange(pendingByteRange!, resourceUri, nextByteRangeOffset);
        segments.add(_IptvHlsSegment(uri: line, sequence: sequence + segments.length, key: currentKey, range: range));
        pendingByteRange = null;
      }
    }
    return _IptvHlsPlaylist(
      segments: segments,
      mediaSequence: sequence,
      targetDuration: target,
      endList: endList,
      initializationMap: initializationMap,
      initializationRange: initializationRange,
      initializationKey: initializationKey,
      initializationSequence: initializationSequence,
    );
  }

  _IptvHlsRange _parseByteRange(String value, String resource, Map<String, int> nextOffsetByResource) {
    final match = RegExp(r'^(\d+)(?:@(\d+))?$').firstMatch(value.trim());
    final length = int.tryParse(match?.group(1) ?? '');
    final offset = match?.group(2) == null
        ? nextOffsetByResource[resource]
        : int.tryParse(match!.group(2)!);
    if (length == null || length <= 0 || offset == null || offset < 0 || offset + length <= offset) {
      throw const FileSystemException('Invalid HLS byte range');
    }
    nextOffsetByResource[resource] = offset + length;
    return _IptvHlsRange(offset: offset, length: length);
  }

  Map<String, String> _parseHlsAttributes(String input) {
    final attributes = <String, String>{};
    final expression = RegExp(r'([A-Za-z0-9-]+)=((?:"[^"]*")|[^,]*)');
    for (final match in expression.allMatches(input)) {
      final raw = match.group(2)!.trim();
      attributes[match.group(1)!.toUpperCase()] = raw.startsWith('"') && raw.endsWith('"')
          ? raw.substring(1, raw.length - 1)
          : raw;
    }
    return attributes;
  }

  Uint8List? _parseIv(String? value) {
    if (value == null) return null;
    final hex = value.toLowerCase().startsWith('0x') ? value.substring(2) : value;
    if (hex.isEmpty || hex.length > 32 || !RegExp(r'^[0-9a-f]+$', caseSensitive: false).hasMatch(hex)) {
      throw const FileSystemException('Invalid HLS encryption IV');
    }
    final padded = hex.padLeft(32, '0');
    return Uint8List.fromList([for (var index = 0; index < 32; index += 2) int.parse(padded.substring(index, index + 2), radix: 16)]);
  }
}

class _IptvHlsPlaylist {
  const _IptvHlsPlaylist({
    required this.segments,
    required this.mediaSequence,
    required this.targetDuration,
    required this.endList,
    required this.initializationMap,
    required this.initializationRange,
    required this.initializationKey,
    required this.initializationSequence,
  });

  final List<_IptvHlsSegment> segments;
  final int mediaSequence;
  final int targetDuration;
  final bool endList;
  final String? initializationMap;
  final _IptvHlsRange? initializationRange;
  final _IptvHlsEncryption? initializationKey;
  final int initializationSequence;
}

class _IptvHlsSegment {
  const _IptvHlsSegment({required this.uri, required this.sequence, required this.key, required this.range});

  final String uri;
  final int sequence;
  final _IptvHlsEncryption? key;
  final _IptvHlsRange? range;
}

class _IptvHlsRange {
  const _IptvHlsRange({required this.offset, required this.length});

  final int offset;
  final int length;
}

class _IptvHlsEncryption {
  const _IptvHlsEncryption({required this.uri, required this.iv});

  final String uri;
  final Uint8List? iv;
}
