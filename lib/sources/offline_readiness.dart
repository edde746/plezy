import 'source_models.dart';

/// Includes the representation, not just a provider's reusable file id.
String offlineFileIdentity(String sourceId, PublicationFile file) =>
    sourceKey(sourceKey(sourceId, file.id), file.fingerprint);

/// Offline availability is evaluated per playable edition. An ebook and its
/// audiobook are alternatives; the chapters within the audiobook are not.
class PublicationOfflineReadiness {
  const PublicationOfflineReadiness({
    required this.readableEditions,
    required this.canListen,
    required this.canWatch,
    required this.availableFiles,
    required this.totalFiles,
  });

  final Set<String> readableEditions;
  final bool canListen;
  final bool canWatch;
  final int availableFiles;
  final int totalFiles;

  bool get isReady => readableEditions.isNotEmpty || canListen || canWatch;
  bool get isPartial => availableFiles > 0 && !isReady;

  factory PublicationOfflineReadiness.evaluate(SourceEntry entry, Set<String> verifiedFiles) {
    bool ready(PublicationFile file) => verifiedFiles.contains(offlineFileIdentity(entry.sourceId, file));
    final audio = entry.audio;
    return PublicationOfflineReadiness(
      readableEditions: {
        for (final file in entry.ebooks)
          if (ready(file)) file.fingerprint,
      },
      canListen: audio.isNotEmpty && audio.every(ready),
      // Matches the ordered file list used by the Files video playback path.
      canWatch: entry.kind == SourceItemKind.video && entry.files.isNotEmpty && entry.files.every(ready),
      availableFiles: entry.files.where(ready).length,
      totalFiles: entry.files.length,
    );
  }
}
