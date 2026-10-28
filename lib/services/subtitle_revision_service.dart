import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'subtitle_retimer.dart';
import 'subtitle_word_timing.dart';

/// Stable local scope for revisions belonging to one profile and library item.
final class SubtitleRevisionIdentity {
  const SubtitleRevisionIdentity({
    required this.profileId,
    required this.serverId,
    required this.ratingKey,
    required this.mediaIndex,
  });

  final String profileId;
  final String serverId;
  final String ratingKey;
  final int mediaIndex;

  String get storageKey => sha256
      .convert(utf8.encode([
        profileId.trim(),
        serverId.trim(),
        ratingKey.trim(),
        mediaIndex.toString(),
      ].join('\u0000')))
      .toString();
}

/// An immutable reviewed subtitle result that can be re-attached or exported.
final class SubtitleRevision {
  const SubtitleRevision({
    required this.id,
    required this.createdAt,
    required this.operation,
    required this.languageCode,
    required this.cues,
    required this.wordTimings,
  });

  final String id;
  final DateTime createdAt;
  final String operation;
  final String? languageCode;
  final List<SubtitleCue> cues;
  final List<SubtitleWordTiming> wordTimings;

  Map<String, Object?> toJson() => {
        'schema': 'plezyng.subtitle-revision.v1',
        'id': id,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'operation': operation,
        'languageCode': languageCode,
        'cues': cues
            .map((cue) => {
                  'index': cue.index,
                  'startMs': cue.startMs,
                  'endMs': cue.endMs,
                  'text': cue.text,
                })
            .toList(growable: false),
        'wordTimings': wordTimings
            .map((timing) => {
                  'startMs': timing.startMs,
                  'endMs': timing.endMs,
                  'text': timing.text,
                  'confidence': timing.confidence,
                  'unit': timing.unit.name,
                  'cueIndex': timing.cueIndex,
                })
            .toList(growable: false),
      };

  static SubtitleRevision fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['schema'] != 'plezyng.subtitle-revision.v1') {
      throw const FormatException('Unsupported subtitle revision record.');
    }
    final id = value['id'];
    final createdAt = DateTime.tryParse(value['createdAt'] as String? ?? '');
    final operation = value['operation'];
    final language = value['languageCode'];
    final rawCues = value['cues'];
    final rawWords = value['wordTimings'];
    if (id is! String ||
        !RegExp(r'^\d+_[0-9a-f]+$').hasMatch(id) ||
        createdAt == null ||
        operation is! String ||
        operation.trim().isEmpty ||
        operation.length > 120 ||
        (language != null && (language is! String || language.length > 24)) ||
        rawCues is! List ||
        rawWords is! List ||
        rawCues.isEmpty ||
        rawCues.length > SubtitleRetimer.maximumCueCount ||
        rawWords.length > 250000) {
      throw const FormatException('Subtitle revision metadata is invalid.');
    }

    final cues = <SubtitleCue>[];
    for (final row in rawCues) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Subtitle revision cue is invalid.');
      }
      final index = row['index'];
      final start = row['startMs'];
      final end = row['endMs'];
      final text = row['text'];
      if (index is! int ||
          start is! int ||
          end is! int ||
          text is! String ||
          text.length > SubtitleRetimer.maximumInputBytes ||
          start < 0 ||
          end <= start ||
          end > SubtitleRetimer.maximumTimeMs) {
        throw const FormatException('Subtitle revision cue timing or text is invalid.');
      }
      cues.add(SubtitleCue(index: index, startMs: start, endMs: end, text: text));
    }

    final wordTimings = <SubtitleWordTiming>[];
    for (final row in rawWords) {
      if (row is! Map<String, dynamic>) {
        throw const FormatException('Subtitle revision word timing is invalid.');
      }
      final start = row['startMs'];
      final end = row['endMs'];
      final text = row['text'];
      final confidence = row['confidence'];
      final unitName = row['unit'];
      final cueIndex = row['cueIndex'];
      if (start is! int ||
          end is! int ||
          text is! String ||
          confidence is! num ||
          unitName is! String ||
          (cueIndex != null && cueIndex is! int) ||
          start < 0 ||
          end <= start ||
          end > SubtitleRetimer.maximumTimeMs ||
          text.length > 4096 ||
          confidence < 0 ||
          confidence > 1 ||
          (cueIndex != null && ((cueIndex as int) < 1 || cueIndex > cues.length))) {
        throw const FormatException('Subtitle revision word timing fields are invalid.');
      }
      final unit = SubtitleWordTimingUnit.values.where((candidate) => candidate.name == unitName);
      if (unit.isEmpty) throw const FormatException('Subtitle revision timing unit is invalid.');
      wordTimings.add(SubtitleWordTiming(
        startMs: start,
        endMs: end,
        text: text,
        confidence: confidence.toDouble(),
        unit: unit.first,
        cueIndex: cueIndex as int?,
      ));
    }

    return SubtitleRevision(
      id: id,
      createdAt: createdAt.toUtc(),
      operation: operation,
      languageCode: language as String?,
      cues: List<SubtitleCue>.unmodifiable(cues),
      wordTimings: List<SubtitleWordTiming>.unmodifiable(wordTimings),
    );
  }
}

/// Device-local, bounded history for reviewed results on server library items.
///
/// Records are stored in the app support directory, scoped by a one-way hash of
/// profile/server/item/media identity. The history never synchronizes to a
/// server and does not modify the source subtitle or playback track.
abstract final class SubtitleRevisionService {
  static const int maximumRevisionsPerItem = 12;
  static const int maximumRevisionBytes = 8 * 1024 * 1024;
  static const int maximumHistoryBytesPerItem = 24 * 1024 * 1024;
  static const int maximumTotalRevisionFiles = 1000;
  static const int maximumTotalRevisionBytes = 256 * 1024 * 1024;

  static Future<void> _writeTail = Future<void>.value();

  static Future<void> _exclusive(Future<void> Function() action) async {
    final previous = _writeTail;
    final released = Completer<void>();
    _writeTail = released.future;
    await previous;
    try {
      await action();
    } finally {
      released.complete();
    }
  }

  static Future<Directory> _rootDirectory() async {
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'subtitle-revisions'));
    await root.create(recursive: true);
    return root;
  }

  static Future<Directory> _directoryFor(SubtitleRevisionIdentity identity) async {
    final root = await _rootDirectory();
    final directory = Directory(p.join(root.path, identity.storageKey));
    await directory.create(recursive: true);
    return directory;
  }

  static Future<SubtitleRevision> saveRevision({
    required SubtitleRevisionIdentity identity,
    required String operation,
    required String? languageCode,
    required List<SubtitleCue> cues,
    required List<SubtitleWordTiming> wordTimings,
  }) async {
    late SubtitleRevision revision;
    await _exclusive(() async {
      if (identity.profileId.trim().isEmpty ||
          identity.serverId.trim().isEmpty ||
          identity.ratingKey.trim().isEmpty ||
          identity.mediaIndex < 0) {
        throw ArgumentError('Subtitle revision identity is incomplete.');
      }
      if (operation.trim().isEmpty ||
          operation.length > 120 ||
          (languageCode?.length ?? 0) > 24 ||
          cues.isEmpty ||
          cues.length > SubtitleRetimer.maximumCueCount ||
          wordTimings.length > 250000) {
        throw const FormatException('Subtitle revision exceeds the supported metadata or cue bound.');
      }
      for (final cue in cues) {
        if (cue.startMs < 0 ||
            cue.endMs <= cue.startMs ||
            cue.endMs > SubtitleRetimer.maximumTimeMs ||
            cue.text.length > SubtitleRetimer.maximumInputBytes) {
          throw const FormatException('Subtitle revision contains an invalid cue.');
        }
      }
      for (final timing in wordTimings) {
        if (timing.startMs < 0 ||
            timing.endMs <= timing.startMs ||
            timing.endMs > SubtitleRetimer.maximumTimeMs ||
            timing.text.length > 4096 ||
            !timing.confidence.isFinite ||
            timing.confidence < 0 ||
            timing.confidence > 1 ||
            (timing.cueIndex != null && (timing.cueIndex! < 1 || timing.cueIndex! > cues.length))) {
          throw const FormatException('Subtitle revision contains an invalid word timing.');
        }
      }
      final now = DateTime.now().toUtc();
      final id = now.microsecondsSinceEpoch.toString() + '_' + DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      revision = SubtitleRevision(
        id: id,
        createdAt: now,
        operation: operation.trim(),
        languageCode: languageCode?.trim().isEmpty == true ? null : languageCode?.trim(),
        cues: List<SubtitleCue>.unmodifiable(cues),
        wordTimings: List<SubtitleWordTiming>.unmodifiable(wordTimings),
      );
      final bytes = utf8.encode(jsonEncode(revision.toJson()));
      if (bytes.length > maximumRevisionBytes) {
        throw const FormatException('This reviewed result is too large for local revision history.');
      }
      final directory = await _directoryFor(identity);
      final target = File(p.join(directory.path, id + '.json'));
      final temporary = File(p.join(directory.path, '.tmp-' + id));
      try {
        await temporary.writeAsBytes(bytes, flush: true);
        await temporary.rename(target.path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
      await _pruneItem(directory);
      await _pruneGlobal(await _rootDirectory());
    });
    return revision;
  }

  static Future<List<SubtitleRevision>> loadRevisions(SubtitleRevisionIdentity identity) async {
    await _writeTail;
    final directory = Directory(p.join((await _rootDirectory()).path, identity.storageKey));
    if (!await directory.exists()) return const <SubtitleRevision>[];
    final files = await _revisionFiles(directory);
    await _sortNewestFirst(files);
    final output = <SubtitleRevision>[];
    var totalBytes = 0;
    for (final file in files) {
      if (output.length >= maximumRevisionsPerItem) break;
      final length = await file.length();
      if (length <= 0 || length > maximumRevisionBytes || totalBytes + length > maximumHistoryBytesPerItem) continue;
      try {
        final decoded = jsonDecode(await file.readAsString());
        final revision = SubtitleRevision.fromJson(decoded);
        final expected = p.basenameWithoutExtension(file.path);
        if (revision.id != expected) throw const FormatException('Revision filename does not match its record.');
        output.add(revision);
        totalBytes += length;
      } catch (_) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    return List<SubtitleRevision>.unmodifiable(output);
  }

  static Future<void> deleteRevision(SubtitleRevisionIdentity identity, String id) async {
    if (!RegExp(r'^\d+_[0-9a-f]+$').hasMatch(id)) {
      throw const FormatException('Subtitle revision identifier is invalid.');
    }
    await _exclusive(() async {
      final directory = Directory(p.join((await _rootDirectory()).path, identity.storageKey));
      final file = File(p.join(directory.path, id + '.json'));
      if (await file.exists()) await file.delete();
    });
  }

  static Future<List<File>> _revisionFiles(Directory directory) async {
    final entities = await directory.list(followLinks: false).toList();
    return entities.whereType<File>().where((file) => p.extension(file.path) == '.json').toList();
  }

  static Future<void> _sortNewestFirst(List<File> files) async {
    files.sort((left, right) => _timestampFromName(right).compareTo(_timestampFromName(left)));
  }

  static int _timestampFromName(File file) {
    final name = p.basenameWithoutExtension(file.path);
    return int.tryParse(name.split('_').first) ?? 0;
  }

  static Future<void> _pruneItem(Directory directory) async {
    final files = await _revisionFiles(directory);
    await _sortNewestFirst(files);
    final sizes = <int>[];
    var total = 0;
    for (final file in files) {
      final size = await file.length();
      sizes.add(size);
      total += size;
    }
    var keep = files.length;
    while (keep > maximumRevisionsPerItem || total > maximumHistoryBytesPerItem) {
      keep--;
      total -= sizes[keep];
      await files[keep].delete();
    }
  }

  static Future<void> _pruneGlobal(Directory root) async {
    final files = <File>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && p.extension(entity.path) == '.json') files.add(entity);
    }
    await _sortNewestFirst(files);
    final sizes = <int>[];
    var total = 0;
    for (final file in files) {
      final size = await file.length();
      sizes.add(size);
      total += size;
    }
    var keep = files.length;
    while (keep > maximumTotalRevisionFiles || total > maximumTotalRevisionBytes) {
      keep--;
      total -= sizes[keep];
      await files[keep].delete();
    }
  }
}
