import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A supported subtitle entry inside a bounded local archive.
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

/// Bounded ZIP/TAR/gzip-TAR reader that only writes selected subtitle files under
/// the application's temporary directory. Archive names are never used as paths.
abstract final class SubtitleArchiveImporter {
  static const int maximumArchiveBytes = 50 * 1024 * 1024;
  static const int maximumExpandedArchiveBytes = 64 * 1024 * 1024;
  static const int maximumEntries = 4096;
  static const int maximumCandidates = 256;
  static const int maximumMemberBytes = 32 * 1024 * 1024;
  static const int maximumCandidateBytes = 48 * 1024 * 1024;

  static Future<Uint8List> readPickedArchive(PlatformFile file) async {
    if (file.size <= 0 || file.size > maximumArchiveBytes) {
      throw const FormatException('Selected file must be between 1 byte and 50 MiB.');
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
      throw const FormatException('Selected file must be between 1 byte and 50 MiB.');
    }
    final output = BytesBuilder(copy: false);
    var bytesRead = 0;
    await for (final chunk in input.openRead()) {
      bytesRead += chunk.length;
      if (bytesRead > maximumArchiveBytes) {
        throw const FormatException('Selected file must be between 1 byte and 50 MiB.');
      }
      output.add(chunk);
    }
    final bytes = output.takeBytes();
    if (bytes.lengthInBytes != actualSize) {
      throw const FormatException('Picked archive changed while it was being read.');
    }
    return bytes;
  }

  static bool isSupportedArchiveName(String fileName) {
    final normalized = fileName.replaceAll('\\', '/').split('/').last.toLowerCase();
    return normalized.endsWith('.zip') ||
        normalized.endsWith('.tar') ||
        normalized.endsWith('.tar.gz') ||
        normalized.endsWith('.tgz');
  }

  static bool isLargeArchiveName(String fileName) => isSupportedArchiveName(fileName);

  static SubtitleArchiveDocument open(
    Uint8List bytes, {
    required String fileName,
    required Set<String> supportedExtensions,
  }) {
    if (bytes.isEmpty || bytes.lengthInBytes > maximumArchiveBytes) {
      throw const FormatException('Subtitle archive must be between 1 byte and 50 MiB.');
    }
    final normalized = fileName.replaceAll('\\', '/').split('/').last.toLowerCase();
    final Archive archive;
    if (normalized.endsWith('.zip')) {
      archive = _openZip(bytes);
    } else if (normalized.endsWith('.tar.gz') || normalized.endsWith('.tgz')) {
      final expandedTar = GZipDecoder().decodeBytes(
        bytes,
        verify: true,
        maxOutputSize: maximumExpandedArchiveBytes + maximumEntries * 1024 + 1024,
      );
      archive = _openTar(Uint8List.fromList(expandedTar));
    } else if (normalized.endsWith('.tar')) {
      archive = _openTar(bytes);
    } else {
      throw const FormatException('Choose a ZIP, TAR, or gzip-compressed TAR subtitle archive.');
    }
    if (archive.files.length > maximumEntries) {
      throw const FormatException('Archive contains too many entries to inspect safely.');
    }
    return _documentForArchive(archive, bytes, supportedExtensions);
  }

  static Archive _openZip(Uint8List bytes) {
    _validateZipResourceBounds(bytes);
    return ZipDecoder().decodeBytes(bytes, verify: true);
  }

  static Archive _openTar(Uint8List bytes) {
    _validateTarResourceBounds(bytes);
    return TarDecoder().decodeBytes(bytes, verify: true, storeData: true);
  }

  static SubtitleArchiveDocument _documentForArchive(
    Archive archive,
    Uint8List bytes,
    Set<String> supportedExtensions,
  ) {
    final digest = sha256.convert(bytes).toString();
    final supported = supportedExtensions
        .map((extension) => extension.startsWith('.') ? extension.toLowerCase() : '.${extension.toLowerCase()}')
        .toSet();
    final byName = <String, ArchiveFile>{};
    final originalNames = <String, String>{};
    final seenNames = <String>{};
    for (final entry in archive.files) {
      if (entry.isSymbolicLink) {
        throw const FormatException('Archives containing symbolic links are not supported.');
      }
      if (entry.isDirectory) {
        final directoryName = entry.name.replaceAll('\\', '/');
        final withoutTrailingSeparator = directoryName.endsWith('/')
            ? directoryName.substring(0, directoryName.length - 1)
            : directoryName;
        final safeName = _validateEntryName(withoutTrailingSeparator);
        if (!seenNames.add(safeName.toLowerCase())) {
          throw const FormatException('Archive contains duplicate subtitle paths.');
        }
        continue;
      }
      final safeName = _validateEntryName(entry.name);
      final identity = safeName.toLowerCase();
      if (!seenNames.add(identity) || byName.containsKey(identity)) {
        throw const FormatException('Archive contains duplicate subtitle paths.');
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
        throw const FormatException('Archive contains too many supported subtitle files.');
      }
    }

    if (candidates.isEmpty) {
      throw const FormatException('Archive contains no supported subtitle files.');
    }
    candidates.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return SubtitleArchiveDocument._(archiveDigest: digest, candidates: List.unmodifiable(candidates));
  }

  /// Validate plain TAR headers and resource bounds before decoding member data.
  static void _validateTarResourceBounds(Uint8List bytes) {
    const blockBytes = 512;
    if (bytes.lengthInBytes < blockBytes * 2 || bytes.lengthInBytes % blockBytes != 0) {
      throw const FormatException('TAR archive is truncated or is not block aligned.');
    }

    var offset = 0;
    var entries = 0;
    var expandedBytes = 0;
    while (offset + blockBytes <= bytes.lengthInBytes) {
      if (_isZeroTarBlock(bytes, offset)) {
        final secondEndMarker = offset + blockBytes;
        if (secondEndMarker + blockBytes > bytes.lengthInBytes || !_isZeroTarBlock(bytes, secondEndMarker)) {
          throw const FormatException('TAR archive must end with two zero blocks.');
        }
        for (var trailing = secondEndMarker + blockBytes; trailing < bytes.lengthInBytes; trailing += blockBytes) {
          if (!_isZeroTarBlock(bytes, trailing)) {
            throw const FormatException('TAR archive has unexpected data after its end markers.');
          }
        }
        return;
      }

      final header = Uint8List.sublistView(bytes, offset, offset + blockBytes);
      final expectedChecksum = _readTarOctal(header, 148, 8, allowEmpty: false);
      var actualChecksum = 0;
      for (var index = 0; index < blockBytes; index++) {
        actualChecksum += index >= 148 && index < 156 ? 32 : header[index];
      }
      if (actualChecksum != expectedChecksum) {
        throw const FormatException('TAR header checksum is invalid.');
      }

      final typeFlag = header[156];
      final isDirectory = typeFlag == 53;
      if (typeFlag != 0 && typeFlag != 48 && !isDirectory) {
        throw const FormatException('TAR links, special files, and extended headers are not supported.');
      }
      final size = _readTarOctal(header, 124, 12);
      if (isDirectory && size != 0) {
        throw const FormatException('TAR directory entries must not contain file data.');
      }
      if (!isDirectory) {
        if (size > maximumMemberBytes || size > maximumExpandedArchiveBytes - expandedBytes) {
          throw const FormatException('TAR expands beyond the subtitle import size bounds.');
        }
        expandedBytes += size;
      }
      entries++;
      if (entries > maximumEntries) {
        throw const FormatException('TAR archive contains too many entries to inspect safely.');
      }

      final name = _readTarString(header, 0, 100);
      final magic = String.fromCharCodes(header.sublist(257, 263));
      final prefix = magic.startsWith('ustar') ? _readTarString(header, 345, 155) : '';
      final path = prefix.isEmpty ? name : '$prefix/$name';
      if (path.isEmpty) throw const FormatException('TAR contains an entry with an empty path.');
      final pathForValidation = isDirectory && path.endsWith('/') ? path.substring(0, path.length - 1) : path;
      _validateEntryName(pathForValidation);

      final dataOffset = offset + blockBytes;
      if (size > bytes.lengthInBytes - dataOffset) {
        throw const FormatException('TAR member data exceeds the archive bounds.');
      }
      final paddedSize = ((size + blockBytes - 1) ~/ blockBytes) * blockBytes;
      if (paddedSize > bytes.lengthInBytes - dataOffset) {
        throw const FormatException('TAR member padding exceeds the archive bounds.');
      }
      offset = dataOffset + paddedSize;
    }

    throw const FormatException('TAR archive is missing its end markers.');
  }

  static int _readTarOctal(Uint8List bytes, int offset, int length, {bool allowEmpty = true}) {
    if ((bytes[offset] & 0x80) != 0) {
      throw const FormatException('TAR base-256 numeric fields are not supported.');
    }
    final value = String.fromCharCodes(bytes.sublist(offset, offset + length)).replaceAll('\u0000', ' ').trim();
    if (value.isEmpty) {
      if (allowEmpty) return 0;
      throw const FormatException('TAR numeric field is empty.');
    }
    if (!RegExp(r'^[0-7]+  /// archive package expands every member into memory.
  static void _validateZipResourceBounds(Uint8List bytes) {
    if (bytes.lengthInBytes < 22) throw const FormatException('ZIP archive is truncated.');
    final view = ByteData.sublistView(bytes);
    final searchStart = bytes.lengthInBytes > 22 + 0xffff ? bytes.lengthInBytes - 22 - 0xffff : 0;
    var endRecord = -1;
    for (var offset = bytes.lengthInBytes - 22; offset >= searchStart; offset--) {
      if (view.getUint32(offset, Endian.little) != 0x06054b50) continue;
      final commentLength = view.getUint16(offset + 20, Endian.little);
      if (offset + 22 + commentLength == bytes.lengthInBytes) {
        endRecord = offset;
        break;
      }
    }
    if (endRecord < 0) throw const FormatException('ZIP archive has no valid end-of-directory record.');

    final diskNumber = view.getUint16(endRecord + 4, Endian.little);
    final directoryDisk = view.getUint16(endRecord + 6, Endian.little);
    final diskEntryCount = view.getUint16(endRecord + 8, Endian.little);
    final entryCount = view.getUint16(endRecord + 10, Endian.little);
    final directoryBytes = view.getUint32(endRecord + 12, Endian.little);
    final directoryOffset = view.getUint32(endRecord + 16, Endian.little);
    if (diskNumber != 0 || directoryDisk != 0 || diskEntryCount != entryCount) {
      throw const FormatException('Split or multi-disk ZIP archives are not supported.');
    }
    if (entryCount == 0xffff || directoryBytes == 0xffffffff || directoryOffset == 0xffffffff) {
      throw const FormatException('ZIP64 archives are not supported by the bounded subtitle importer.');
    }
    if (entryCount > maximumEntries) {
      throw const FormatException('ZIP archive contains too many entries to inspect safely.');
    }
    final directoryEnd = directoryOffset + directoryBytes;
    if (directoryEnd > endRecord || directoryEnd < directoryOffset) {
      throw const FormatException('ZIP central directory is outside the archive bounds.');
    }

    var cursor = directoryOffset;
    var expandedBytes = 0;
    for (var index = 0; index < entryCount; index++) {
      if (cursor + 46 > directoryEnd || view.getUint32(cursor, Endian.little) != 0x02014b50) {
        throw const FormatException('ZIP central directory contains an invalid entry.');
      }
      final flags = view.getUint16(cursor + 8, Endian.little);
      final method = view.getUint16(cursor + 10, Endian.little);
      final compressedSize = view.getUint32(cursor + 20, Endian.little);
      final uncompressedSize = view.getUint32(cursor + 24, Endian.little);
      final nameLength = view.getUint16(cursor + 28, Endian.little);
      final extraLength = view.getUint16(cursor + 30, Endian.little);
      final commentLength = view.getUint16(cursor + 32, Endian.little);
      final startDisk = view.getUint16(cursor + 34, Endian.little);
      final localHeaderOffset = view.getUint32(cursor + 42, Endian.little);
      final recordEnd = cursor + 46 + nameLength + extraLength + commentLength;
      if (recordEnd > directoryEnd) {
        throw const FormatException('ZIP central directory entry exceeds its declared bounds.');
      }
      if (startDisk != 0 ||
          compressedSize == 0xffffffff ||
          uncompressedSize == 0xffffffff ||
          localHeaderOffset == 0xffffffff) {
        throw const FormatException('ZIP64 and multi-disk entries are not supported.');
      }
      if ((flags & 0x0041) != 0) {
        throw const FormatException('Encrypted ZIP entries are not supported.');
      }
      if (method != 0 && method != 8) {
        throw const FormatException('ZIP entries must use stored or DEFLATE compression.');
      }
      if (uncompressedSize > maximumMemberBytes ||
          uncompressedSize > maximumExpandedArchiveBytes - expandedBytes) {
        throw const FormatException('ZIP expands beyond the 64 MiB subtitle import bound.');
      }
      _rejectZip64ExtraFields(bytes, cursor + 46 + nameLength, extraLength);

      if (localHeaderOffset + 30 > directoryOffset ||
          view.getUint32(localHeaderOffset, Endian.little) != 0x04034b50) {
        throw const FormatException('ZIP local file header is invalid.');
      }
      final localFlags = view.getUint16(localHeaderOffset + 6, Endian.little);
      final localMethod = view.getUint16(localHeaderOffset + 8, Endian.little);
      final localCompressedSize = view.getUint32(localHeaderOffset + 18, Endian.little);
      final localUncompressedSize = view.getUint32(localHeaderOffset + 22, Endian.little);
      final localNameLength = view.getUint16(localHeaderOffset + 26, Endian.little);
      final localExtraLength = view.getUint16(localHeaderOffset + 28, Endian.little);
      final usesDataDescriptor = (flags & 0x0008) != 0;
      if ((localFlags & 0x0041) != 0 ||
          localMethod != method ||
          ((localFlags ^ flags) & 0x0008) != 0 ||
          localCompressedSize == 0xffffffff ||
          localUncompressedSize == 0xffffffff ||
          (!usesDataDescriptor &&
              (localCompressedSize != compressedSize || localUncompressedSize != uncompressedSize)) ||
          (usesDataDescriptor &&
              ((localCompressedSize != 0 && localCompressedSize != compressedSize) ||
                  (localUncompressedSize != 0 && localUncompressedSize != uncompressedSize)))) {
        throw const FormatException('ZIP local and central entry headers do not match.');
      }
      final dataOffset = localHeaderOffset + 30 + localNameLength + localExtraLength;
      final dataEnd = dataOffset + compressedSize;
      if (dataEnd > directoryOffset || dataEnd < dataOffset) {
        throw const FormatException('ZIP compressed entry data is outside the archive bounds.');
      }
      _rejectZip64ExtraFields(bytes, localHeaderOffset + 30 + localNameLength, localExtraLength);

      if (method == 0) {
        if (compressedSize != uncompressedSize) {
          throw const FormatException('Stored ZIP entry has inconsistent size metadata.');
        }
        expandedBytes += compressedSize;
      } else {
        final sink = _ZipOutputLimitSink(maximumMemberBytes);
        try {
          final decoder = ZLibCodec(raw: true).decoder.startChunkedConversion(sink);
          decoder.add(Uint8List.sublistView(bytes, dataOffset, dataEnd));
          decoder.close();
        } on FormatException {
          rethrow;
        } catch (_) {
          throw const FormatException('ZIP contains a malformed or oversized DEFLATE stream.');
        }
        if (sink.bytes != uncompressedSize) {
          throw const FormatException('ZIP entry output does not match its declared uncompressed size.');
        }
        expandedBytes += sink.bytes;
      }
      cursor = recordEnd;
    }

    if (cursor != directoryEnd) {
      // The optional digital-signature record is the only supported trailer.
      if (cursor + 6 > directoryEnd ||
          view.getUint32(cursor, Endian.little) != 0x05054b50 ||
          cursor + 6 + view.getUint16(cursor + 4, Endian.little) != directoryEnd) {
        throw const FormatException('ZIP central directory has unexpected trailing data.');
      }
    }
  }

  static void _rejectZip64ExtraFields(Uint8List bytes, int offset, int length) {
    final view = ByteData.sublistView(bytes);
    final end = offset + length;
    var cursor = offset;
    while (cursor < end) {
      if (cursor + 4 > end) throw const FormatException('ZIP extra field is truncated.');
      final identifier = view.getUint16(cursor, Endian.little);
      final fieldLength = view.getUint16(cursor + 2, Endian.little);
      cursor += 4;
      if (cursor + fieldLength > end) throw const FormatException('ZIP extra field is outside its declared bounds.');
      if (identifier == 0x0001) throw const FormatException('ZIP64 extra fields are not supported.');
      cursor += fieldLength;
    }
  }

  static String _validateEntryName(String rawName) {
    if (rawName.isEmpty || rawName.contains('\u0000')) {
      throw const FormatException('Archive contains an invalid file path.');
    }
    final normalized = rawName.replaceAll('\\', '/');
    if (normalized.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(normalized)) {
      throw const FormatException('Archive contains an absolute file path.');
    }
    final components = normalized.split('/');
    if (components.any((component) => component.isEmpty || component == '.' || component == '..')) {
      throw const FormatException('Archive contains a path traversal entry.');
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

final class _ZipOutputLimitSink implements Sink<List<int>> {
  _ZipOutputLimitSink(this.limit);

  final int limit;
  int bytes = 0;

  @override
  void add(List<int> chunk) {
    bytes += chunk.length;
    if (bytes > limit) throw const FormatException('ZIP entry expands beyond the 32 MiB per-file bound.');
  }

  @override
  void close() {}
}
).hasMatch(value)) {
      throw const FormatException('TAR numeric field is not valid octal.');
    }
    var parsed = 0;
    for (final digit in value.codeUnits) {
      parsed = parsed * 8 + digit - 48;
      if (parsed > maximumExpandedArchiveBytes) {
        throw const FormatException('TAR numeric field exceeds the subtitle import size bounds.');
      }
    }
    return parsed;
  }

  static String _readTarString(Uint8List bytes, int offset, int length) {
    var end = offset;
    final limit = offset + length;
    while (end < limit && bytes[end] != 0) {
      end++;
    }
    try {
      return utf8.decode(Uint8List.sublistView(bytes, offset, end), allowMalformed: false);
    } on FormatException {
      throw const FormatException('TAR path is not valid UTF-8.');
    }
  }

  static bool _isZeroTarBlock(Uint8List bytes, int offset) {
    for (var index = offset; index < offset + 512; index++) {
      if (bytes[index] != 0) return false;
    }
    return true;
  }

  /// Validate the central directory and cap actual DEFLATE output before the
  /// archive package expands every member into memory.
  static void _validateZipResourceBounds(Uint8List bytes) {
    if (bytes.lengthInBytes < 22) throw const FormatException('ZIP archive is truncated.');
    final view = ByteData.sublistView(bytes);
    final searchStart = bytes.lengthInBytes > 22 + 0xffff ? bytes.lengthInBytes - 22 - 0xffff : 0;
    var endRecord = -1;
    for (var offset = bytes.lengthInBytes - 22; offset >= searchStart; offset--) {
      if (view.getUint32(offset, Endian.little) != 0x06054b50) continue;
      final commentLength = view.getUint16(offset + 20, Endian.little);
      if (offset + 22 + commentLength == bytes.lengthInBytes) {
        endRecord = offset;
        break;
      }
    }
    if (endRecord < 0) throw const FormatException('ZIP archive has no valid end-of-directory record.');

    final diskNumber = view.getUint16(endRecord + 4, Endian.little);
    final directoryDisk = view.getUint16(endRecord + 6, Endian.little);
    final diskEntryCount = view.getUint16(endRecord + 8, Endian.little);
    final entryCount = view.getUint16(endRecord + 10, Endian.little);
    final directoryBytes = view.getUint32(endRecord + 12, Endian.little);
    final directoryOffset = view.getUint32(endRecord + 16, Endian.little);
    if (diskNumber != 0 || directoryDisk != 0 || diskEntryCount != entryCount) {
      throw const FormatException('Split or multi-disk ZIP archives are not supported.');
    }
    if (entryCount == 0xffff || directoryBytes == 0xffffffff || directoryOffset == 0xffffffff) {
      throw const FormatException('ZIP64 archives are not supported by the bounded subtitle importer.');
    }
    if (entryCount > maximumEntries) {
      throw const FormatException('ZIP archive contains too many entries to inspect safely.');
    }
    final directoryEnd = directoryOffset + directoryBytes;
    if (directoryEnd > endRecord || directoryEnd < directoryOffset) {
      throw const FormatException('ZIP central directory is outside the archive bounds.');
    }

    var cursor = directoryOffset;
    var expandedBytes = 0;
    for (var index = 0; index < entryCount; index++) {
      if (cursor + 46 > directoryEnd || view.getUint32(cursor, Endian.little) != 0x02014b50) {
        throw const FormatException('ZIP central directory contains an invalid entry.');
      }
      final flags = view.getUint16(cursor + 8, Endian.little);
      final method = view.getUint16(cursor + 10, Endian.little);
      final compressedSize = view.getUint32(cursor + 20, Endian.little);
      final uncompressedSize = view.getUint32(cursor + 24, Endian.little);
      final nameLength = view.getUint16(cursor + 28, Endian.little);
      final extraLength = view.getUint16(cursor + 30, Endian.little);
      final commentLength = view.getUint16(cursor + 32, Endian.little);
      final startDisk = view.getUint16(cursor + 34, Endian.little);
      final localHeaderOffset = view.getUint32(cursor + 42, Endian.little);
      final recordEnd = cursor + 46 + nameLength + extraLength + commentLength;
      if (recordEnd > directoryEnd) {
        throw const FormatException('ZIP central directory entry exceeds its declared bounds.');
      }
      if (startDisk != 0 ||
          compressedSize == 0xffffffff ||
          uncompressedSize == 0xffffffff ||
          localHeaderOffset == 0xffffffff) {
        throw const FormatException('ZIP64 and multi-disk entries are not supported.');
      }
      if ((flags & 0x0041) != 0) {
        throw const FormatException('Encrypted ZIP entries are not supported.');
      }
      if (method != 0 && method != 8) {
        throw const FormatException('ZIP entries must use stored or DEFLATE compression.');
      }
      if (uncompressedSize > maximumMemberBytes ||
          uncompressedSize > maximumExpandedArchiveBytes - expandedBytes) {
        throw const FormatException('ZIP expands beyond the 64 MiB subtitle import bound.');
      }
      _rejectZip64ExtraFields(bytes, cursor + 46 + nameLength, extraLength);

      if (localHeaderOffset + 30 > directoryOffset ||
          view.getUint32(localHeaderOffset, Endian.little) != 0x04034b50) {
        throw const FormatException('ZIP local file header is invalid.');
      }
      final localFlags = view.getUint16(localHeaderOffset + 6, Endian.little);
      final localMethod = view.getUint16(localHeaderOffset + 8, Endian.little);
      final localCompressedSize = view.getUint32(localHeaderOffset + 18, Endian.little);
      final localUncompressedSize = view.getUint32(localHeaderOffset + 22, Endian.little);
      final localNameLength = view.getUint16(localHeaderOffset + 26, Endian.little);
      final localExtraLength = view.getUint16(localHeaderOffset + 28, Endian.little);
      final usesDataDescriptor = (flags & 0x0008) != 0;
      if ((localFlags & 0x0041) != 0 ||
          localMethod != method ||
          ((localFlags ^ flags) & 0x0008) != 0 ||
          localCompressedSize == 0xffffffff ||
          localUncompressedSize == 0xffffffff ||
          (!usesDataDescriptor &&
              (localCompressedSize != compressedSize || localUncompressedSize != uncompressedSize)) ||
          (usesDataDescriptor &&
              ((localCompressedSize != 0 && localCompressedSize != compressedSize) ||
                  (localUncompressedSize != 0 && localUncompressedSize != uncompressedSize)))) {
        throw const FormatException('ZIP local and central entry headers do not match.');
      }
      final dataOffset = localHeaderOffset + 30 + localNameLength + localExtraLength;
      final dataEnd = dataOffset + compressedSize;
      if (dataEnd > directoryOffset || dataEnd < dataOffset) {
        throw const FormatException('ZIP compressed entry data is outside the archive bounds.');
      }
      _rejectZip64ExtraFields(bytes, localHeaderOffset + 30 + localNameLength, localExtraLength);

      if (method == 0) {
        if (compressedSize != uncompressedSize) {
          throw const FormatException('Stored ZIP entry has inconsistent size metadata.');
        }
        expandedBytes += compressedSize;
      } else {
        final sink = _ZipOutputLimitSink(maximumMemberBytes);
        try {
          final decoder = ZLibCodec(raw: true).decoder.startChunkedConversion(sink);
          decoder.add(Uint8List.sublistView(bytes, dataOffset, dataEnd));
          decoder.close();
        } on FormatException {
          rethrow;
        } catch (_) {
          throw const FormatException('ZIP contains a malformed or oversized DEFLATE stream.');
        }
        if (sink.bytes != uncompressedSize) {
          throw const FormatException('ZIP entry output does not match its declared uncompressed size.');
        }
        expandedBytes += sink.bytes;
      }
      cursor = recordEnd;
    }

    if (cursor != directoryEnd) {
      // The optional digital-signature record is the only supported trailer.
      if (cursor + 6 > directoryEnd ||
          view.getUint32(cursor, Endian.little) != 0x05054b50 ||
          cursor + 6 + view.getUint16(cursor + 4, Endian.little) != directoryEnd) {
        throw const FormatException('ZIP central directory has unexpected trailing data.');
      }
    }
  }

  static void _rejectZip64ExtraFields(Uint8List bytes, int offset, int length) {
    final view = ByteData.sublistView(bytes);
    final end = offset + length;
    var cursor = offset;
    while (cursor < end) {
      if (cursor + 4 > end) throw const FormatException('ZIP extra field is truncated.');
      final identifier = view.getUint16(cursor, Endian.little);
      final fieldLength = view.getUint16(cursor + 2, Endian.little);
      cursor += 4;
      if (cursor + fieldLength > end) throw const FormatException('ZIP extra field is outside its declared bounds.');
      if (identifier == 0x0001) throw const FormatException('ZIP64 extra fields are not supported.');
      cursor += fieldLength;
    }
  }

  static String _validateEntryName(String rawName) {
    if (rawName.isEmpty || rawName.contains('\u0000')) {
      throw const FormatException('Archive contains an invalid file path.');
    }
    final normalized = rawName.replaceAll('\\', '/');
    if (normalized.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(normalized)) {
      throw const FormatException('Archive contains an absolute file path.');
    }
    final components = normalized.split('/');
    if (components.any((component) => component.isEmpty || component == '.' || component == '..')) {
      throw const FormatException('Archive contains a path traversal entry.');
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

final class _ZipOutputLimitSink implements Sink<List<int>> {
  _ZipOutputLimitSink(this.limit);

  final int limit;
  int bytes = 0;

  @override
  void add(List<int> chunk) {
    bytes += chunk.length;
    if (bytes > limit) throw const FormatException('ZIP entry expands beyond the 32 MiB per-file bound.');
  }

  @override
  void close() {}
}
