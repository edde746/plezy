import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A supported subtitle entry inside a local ZIP archive.
final class SubtitleArchiveCandidate {
  const SubtitleArchiveCandidate._({
    required this.displayName,
    required this._primaryName,
    required this._members,
    required this._documentDigest,
  });

  final String displayName;
  final String _primaryName;
  final List<ArchiveFile> _members;
  final String _documentDigest;
}

/// Bounded ZIP reader that only writes selected subtitle files under the
/// application's temporary directory. Archive names are never used as paths.
abstract final class SubtitleArchiveImporter {
  static const int maximumArchiveBytes = 50 * 1024 * 1024;
  static const int maximumEntries = 4096;
  static const int maximumCandidates = 256;
  static const int maximumMemberBytes = 32 * 1024 * 1024;
  static const int maximumCandidateBytes = 48 * 1024 * 1024;

  static Future<Uint8List> readPickedArchive(PlatformFile file) async {
    if (file.size <= 0 || file.size > maximumArchiveBytes) {
      throw const FormatException('ZIP archive must be between 1 byte and 50 MiB.');
    }
    final inlineBytes = file.bytes;
    if (inlineBytes != null) {
      if (inlineBytes.lengthInBytes != file.size || inlineBytes.lengthInBytes > maximumArchiveBytes) {
        throw const FormatException('Picked archive does not match its declared size.');
      }
      return Uint8List.fromList(inlineBytes);
    }
    final path = file.path;
    if (path == null) {
      throw const FormatException('This platform did not provide archive bytes or a local file path.');
    }
    final input = File(path);
    final actualSize = await input.length();
    if (actualSize <= 0 || actualSize > maximumArchiveBytes || actualSize != file.size) {
      throw const FormatException('ZIP archive must be between 1 byte and 50 MiB.');
    }
    final output = BytesBuilder(copy: false);
    var bytesRead = 0;
    await for (final chunk in input.openRead()) {
      bytesRead += chunk.length;
      if (bytesRead > maximumArchiveBytes) {
        throw const FormatException('ZIP archive must be between 1 byte and 50 MiB.');
      }
      output.add(chunk);
    }
    final bytes = output.takeBytes();
    if (bytes.lengthInBytes != actualSize) {
      throw const FormatException('Picked archive changed while it was being read.');
    }
    return bytes;
  }

  static SubtitleArchiveDocument open(
    Uint8List bytes, {
    required Set<String> supportedExtensions,
  }) {
    if (bytes.isEmpty || bytes.lengthInBytes > maximumArchiveBytes) {
      throw const FormatException('ZIP archive must be between 1 byte and 50 MiB.');
    }
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);
    if (archive.files.length > maximumEntries) {
      throw const FormatException('ZIP archive contains too many entries to inspect safely.');
    }

    final digest = sha256.convert(bytes).toString();
    final supported = supportedExtensions
        .map((extension) => extension.startsWith('.') ? extension.toLowerCase() : '.${extension.toLowerCase()}')
        .toSet();
    final byName = <String, ArchiveFile>{};
    final originalNames = <String, String>{};
    for (final entry in archive.files) {
      if (entry.isSymbolicLink) {
        throw const FormatException('ZIP archives containing symbolic links are not supported.');
      }
      if (entry.isDirectory) continue;
      final safeName = _validateEntryName(entry.name);
      final identity = safeName.toLowerCase();
      if (byName.containsKey(identity)) {
        throw const FormatException('ZIP archive contains duplicate subtitle paths.');
      }
      byName[identity] = entry;
      originalNames[identity] = safeName;
    }

    final pairedSubPaths = <String>{};
    for (final key in byName.keys) {
      if (p.extension(key).toLowerCase() != '.idx') continue;
      final pairedPath = '${p.withoutExtension(key)}.sub'.toLowerCase();
      if (byName.containsKey(pairedPath)) pairedSubPaths.add(pairedPath);
    }

    final candidates = <SubtitleArchiveCandidate>[];
    for (final item in byName.entries) {
      final primaryName = originalNames[item.key]!;
      final extension = p.extension(primaryName).toLowerCase();
      if (!supported.contains(extension) || pairedSubPaths.contains(item.key)) continue;
      final members = <ArchiveFile>[item.value];
      if (extension == '.idx') {
        final pairedPath = '${p.withoutExtension(item.key)}.sub'.toLowerCase();
        final companion = byName[pairedPath];
        if (companion == null) continue;
        members.add(companion);
      }
      final totalBytes = members.fold<int>(0, (total, member) => total + member.size);
      if (members.any((member) => member.size <= 0 || member.size > maximumMemberBytes) ||
          totalBytes > maximumCandidateBytes) {
        continue;
      }
      candidates.add(
        SubtitleArchiveCandidate._(
          displayName: primaryName,
          _primaryName: primaryName,
          _members: List.unmodifiable(members),
          _documentDigest: digest,
        ),
      );
      if (candidates.length > maximumCandidates) {
        throw const FormatException('ZIP archive contains too many supported subtitle files.');
      }
    }

    if (candidates.isEmpty) {
      throw const FormatException('ZIP archive contains no supported subtitle files.');
    }
    candidates.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return SubtitleArchiveDocument._(archiveDigest: digest, candidates: List.unmodifiable(candidates));
  }

  static String _validateEntryName(String rawName) {
    if (rawName.isEmpty || rawName.contains('\u0000')) {
      throw const FormatException('ZIP archive contains an invalid file path.');
    }
    final normalized = rawName.replaceAll('\\', '/');
    if (normalized.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(normalized)) {
      throw const FormatException('ZIP archive contains an absolute file path.');
    }
    final components = normalized.split('/');
    if (components.any((component) => component.isEmpty || component == '.' || component == '..')) {
      throw const FormatException('ZIP archive contains a path traversal entry.');
    }
    return normalized;
  }
}

/// A decoded archive and its validated candidate list.
final class SubtitleArchiveDocument {
  const SubtitleArchiveDocument._({required this.archiveDigest, required this.candidates});

  final String archiveDigest;
  final List<SubtitleArchiveCandidate> candidates;

  Future<List<String>> materialize(SubtitleArchiveCandidate candidate) async {
    if (candidate._documentDigest != archiveDigest || !candidates.contains(candidate)) {
      throw ArgumentError.value(candidate, 'candidate', 'The subtitle entry does not belong to this archive.');
    }

    final decoded = <({ArchiveFile member, Uint8List bytes})>[];
    for (final member in candidate._members) {
      final bytes = member.readBytes();
      if (bytes == null ||
          bytes.lengthInBytes != member.size ||
          bytes.lengthInBytes > SubtitleArchiveImporter.maximumMemberBytes) {
        throw const FormatException('Subtitle entry did not match its declared safe size.');
      }
      decoded.add((member: member, bytes: Uint8List.fromList(bytes)));
    }

    final temporary = await getTemporaryDirectory();
    final candidateDigest = sha256.convert(utf8.encode(candidate._primaryName)).toString().substring(0, 16);
    final directory = Directory(p.join(temporary.path, 'plezyng_subtitle_imports', archiveDigest.substring(0, 24)));
    await directory.create(recursive: true);
    final baseName = 'subtitle_$candidateDigest';
    final paths = <String>[];
    final stagedFiles = <File>[];
    try {
      for (final item in decoded) {
        final extension = p.extension(item.member.name).toLowerCase();
        if (extension.length < 2 || extension.length > 8 || !RegExp(r'^\.[a-z0-9]+$').hasMatch(extension)) {
          throw const FormatException('Subtitle archive entry has an invalid extension.');
        }
        final target = File(p.join(directory.path, '$baseName$extension'));
        if (await target.exists() && await target.length() == item.bytes.length) {
          final existingDigest = sha256.convert(await target.readAsBytes()).toString();
          if (existingDigest == sha256.convert(item.bytes).toString()) {
            paths.add(target.path);
            continue;
          }
        }
        final staged = File('${target.path}.${DateTime.now().microsecondsSinceEpoch}.pending');
        stagedFiles.add(staged);
        await staged.writeAsBytes(item.bytes, flush: true);
        if (await target.exists()) await target.delete();
        await staged.rename(target.path);
        paths.add(target.path);
      }
      return List.unmodifiable(paths);
    } on Object {
      for (final staged in stagedFiles) {
        if (await staged.exists()) await staged.delete();
      }
      rethrow;
    }
  }
}
