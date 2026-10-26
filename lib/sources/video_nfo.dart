import 'package:xml/xml.dart';

import 'source_models.dart';

/// Offline-friendly subset of Kodi/Jellyfin NFO video metadata.
///
/// Remote URLs in NFO files are ignored. Metadata and artwork remain
/// sidecar-local, so browsing never sends filenames to a third-party service.
class VideoNfoMetadata {
  const VideoNfoMetadata({
    this.title,
    this.description,
    this.year,
    this.rating,
    this.genres = const [],
    this.identifiers = const {},
  });

  final String? title;
  final String? description;
  final int? year;
  final double? rating;
  final List<String> genres;
  final Map<String, String> identifiers;

  SourceEntry applyTo(SourceEntry entry) => entry.copyWith(
    title: title?.isNotEmpty == true ? title : null,
    description: description?.isNotEmpty == true ? description : null,
    releaseYear: year,
    rating: rating,
    genres: genres.isEmpty ? null : genres,
    identifiers: {...entry.identifiers, ...identifiers},
  );
}

VideoNfoMetadata? parseVideoNfo(String xml) {
  if (xml.length > 1024 * 1024) return null;
  try {
    final document = XmlDocument.parse(xml);
    String? firstText(String name) {
      for (final element in document.findAllElements(name)) {
        final value = element.innerText.trim();
        if (value.isNotEmpty) return value;
      }
      return null;
    }

    final ids = <String, String>{};
    for (final element in document.findAllElements('uniqueid')) {
      final type = element.getAttribute('type')?.trim().toLowerCase();
      final value = element.innerText.trim();
      if (type != null && value.isNotEmpty && const {'tmdb', 'imdb', 'tvdb'}.contains(type)) {
        ids.putIfAbsent(type, () => value);
      }
    }
    final defaultId = firstText('id');
    if (defaultId != null && RegExp(r'^\d+$').hasMatch(defaultId)) {
      ids.putIfAbsent('tmdb', () => defaultId);
    }

    String? yearText = firstText('year');
    final premiered = firstText('premiered');
    if (yearText == null && premiered != null && premiered.length >= 4) {
      yearText = premiered.substring(0, 4);
    }
    final year = int.tryParse(yearText ?? '');

    double? rating;
    for (final element in document.findAllElements('rating')) {
      var value = '';
      for (final child in element.findElements('value')) {
        value = child.innerText.trim();
        if (value.isNotEmpty) break;
      }
      if (value.isEmpty) value = element.innerText.trim();
      final parsed = double.tryParse(value);
      if (parsed != null && parsed >= 0 && parsed <= 10) {
        rating = parsed;
        if (element.getAttribute('default') == 'true') break;
      }
    }

    final genres = <String>[];
    for (final element in document.findAllElements('genre')) {
      final value = element.innerText.trim();
      if (value.isNotEmpty && !genres.contains(value)) genres.add(value);
    }
    final title = firstText('title') ?? firstText('originaltitle');
    final description = firstText('plot') ?? firstText('outline');
    if (title == null && description == null && year == null && ids.isEmpty) return null;
    return VideoNfoMetadata(
      title: title,
      description: description,
      year: year,
      rating: rating,
      genres: genres,
      identifiers: ids,
    );
  } on XmlException {
    return null;
  }
}
