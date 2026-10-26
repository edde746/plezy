import 'source_models.dart';

enum PublicationSort { title, author, narrator, series, recent }

enum PublicationStatus { all, unstarted, inProgress, finished }

List<SourceEntry> organizePublications(
  List<SourceEntry> entries,
  List<PublicationProgress> progress, {
  PublicationSort sort = PublicationSort.title,
  PublicationStatus status = PublicationStatus.all,
  PublicationMode? mode,
}) {
  final latest = <String, PublicationProgress>{};
  for (final p in progress) {
    if (mode != null && p.mode != mode) continue;
    if ((latest[p.entryKey]?.updatedAt ?? -1) < p.updatedAt) latest[p.entryKey] = p;
  }
  bool started(PublicationProgress? p) => p != null && (p.positionMs > 0 || p.fraction > 0 || p.locator != null);
  final result = entries.where((e) {
    if (e.isFolder) return true;
    final p = latest[e.key];
    return switch (status) {
      PublicationStatus.all => true,
      PublicationStatus.unstarted => p?.finished != true && !started(p),
      PublicationStatus.inProgress => p?.finished != true && started(p),
      PublicationStatus.finished => p?.finished == true,
    };
  }).toList();
  int text(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
  result.sort((a, b) {
    if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
    final primary = switch (sort) {
      PublicationSort.title => text(a.title, b.title),
      PublicationSort.author => text(a.author, b.author),
      PublicationSort.narrator => text(a.narrator, b.narrator),
      PublicationSort.series =>
        text(a.series, b.series) != 0
            ? text(a.series, b.series)
            : (a.seriesOrder ?? double.infinity).compareTo(b.seriesOrder ?? double.infinity),
      PublicationSort.recent => (latest[b.key]?.updatedAt ?? 0).compareTo(latest[a.key]?.updatedAt ?? 0),
    };
    if (primary != 0) return primary;
    final title = text(a.title, b.title);
    return title != 0 ? title : a.key.compareTo(b.key);
  });
  return result;
}
