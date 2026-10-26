import 'dart:io';

import 'package:xml/xml.dart';

import 'source_models.dart';
import 'source_transport.dart';

/// Physical image identity is independent of spreads, split halves and zoom.
class ComicPage {
  const ComicPage(this.name, {this.width, this.height, this.doublePage = false, this.bookmark = ''});
  final String name;
  final int? width, height;
  final bool doublePage;
  final String bookmark;
  Map<String, dynamic> toJson() => {
    'name': name,
    'width': width,
    'height': height,
    'doublePage': doublePage,
    'bookmark': bookmark,
  };
}

class ComicDocument {
  const ComicDocument(this.pages, {this.metadata = const {}, this.direction = 'ltr'});
  final List<ComicPage> pages;
  final Map<String, String> metadata;
  final String direction;
  Map<String, dynamic> toJson() => {
    'pages': pages.map((p) => p.toJson()).toList(),
    'metadata': metadata,
    'direction': direction,
  };

  static bool isImage(String name) =>
      !name.split('/').any((part) => part.startsWith('.') || part == '__MACOSX') &&
      RegExp(r'\.(jpe?g|png|gif|bmp|webp|avif|jxl|svg)$', caseSensitive: false).hasMatch(name);

  /// Locale-independent ordering, including names with integers larger than 64 bits.
  static int compareNames(String a, String b) {
    final parts = RegExp(r'\d+|\D+');
    final x = parts.allMatches(a.toLowerCase()).map((m) => m[0]!).toList();
    final y = parts.allMatches(b.toLowerCase()).map((m) => m[0]!).toList();
    for (var i = 0; i < x.length && i < y.length; i++) {
      var left = x[i], right = y[i];
      if (int.tryParse(left.substring(0, 1)) != null && int.tryParse(right.substring(0, 1)) != null) {
        left = left.replaceFirst(RegExp(r'^0+'), '');
        right = right.replaceFirst(RegExp(r'^0+'), '');
        final length = left.length.compareTo(right.length);
        if (length != 0) return length;
      }
      final result = left.compareTo(right);
      if (result != 0) return result;
    }
    final length = x.length.compareTo(y.length);
    return length != 0 ? length : a.compareTo(b);
  }

  static ComicDocument fromFiles(Iterable<String> files, {String? comicInfo}) {
    final names = files.where(isImage).toList()..sort(compareNames);
    if (names.isEmpty || names.length > 10000) throw const SourceException(SourceFailure.invalidData);
    final metadata = <String, String>{};
    final hints = <int, XmlElement>{};
    // Metadata is optional: a broken tag must not make readable pages disappear.
    if (comicInfo != null &&
        comicInfo.length <= 1024 * 1024 &&
        !RegExp(r'<!\s*(DOCTYPE|ENTITY)', caseSensitive: false).hasMatch(comicInfo)) {
      try {
        final xml = XmlDocument.parse(comicInfo);
        if (xml.rootElement.name.local == 'ComicInfo') {
          for (final key in [
            'Title',
            'Series',
            'Number',
            'Volume',
            'Summary',
            'Writer',
            'Penciller',
            'Inker',
            'Colorist',
            'Letterer',
            'CoverArtist',
            'Publisher',
            'LanguageISO',
            'Manga',
            'Genre',
            'AgeRating',
            'Web',
          ]) {
            final text = xml.rootElement.getElement(key)?.innerText.trim();
            if (text != null && text.isNotEmpty) metadata[key] = text.substring(0, text.length.clamp(0, 10000));
          }
          for (final page in xml.rootElement.getElement('Pages')?.findElements('Page') ?? <XmlElement>[]) {
            final index = int.tryParse(page.getAttribute('Image') ?? '');
            if (index != null && index >= 0 && index < names.length) hints.putIfAbsent(index, () => page);
          }
        }
      } catch (_) {
        /* Fall back to filename order. */
      }
    }
    int? dimension(XmlElement? node, String key) {
      final value = int.tryParse(node?.getAttribute(key) ?? '');
      return value != null && value > 0 && value <= 100000 ? value : null;
    }

    return ComicDocument(
      [
        for (var i = 0; i < names.length; i++)
          ComicPage(
            names[i],
            width: dimension(hints[i], 'ImageWidth'),
            height: dimension(hints[i], 'ImageHeight'),
            doublePage: hints[i]?.getAttribute('DoublePage')?.toLowerCase() == 'true',
            bookmark: (hints[i]?.getAttribute('Bookmark') ?? '').substring(
              0,
              (hints[i]?.getAttribute('Bookmark') ?? '').length.clamp(0, 500),
            ),
          ),
      ],
      metadata: metadata,
      direction: metadata['Manga'] == 'YesAndRightToLeft' ? 'rtl' : 'ltr',
    );
  }

  static Future<ComicDocument> fromArchive(Directory directory, Map<String, int> files) async {
    final info = files.keys.where((name) => name.toLowerCase() == 'comicinfo.xml').firstOrNull;
    String? xml;
    if (info != null && files[info]! <= 1024 * 1024) {
      try {
        xml = await File('${directory.path}/$info').readAsString();
      } catch (_) {
        /* Optional metadata. */
      }
    }
    return fromFiles(files.keys, comicInfo: xml);
  }
}

/// Transport remains in Dart. Neither credentials nor remote URLs reach the WebView.
class ComicPageSource {
  ComicPageSource({required this.document, required this.transport, required this.resolve});
  final ComicDocument document;
  final SourceTransport transport;
  final Future<ContentLease> Function(int index) resolve;
}
