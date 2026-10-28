import 'dart:convert';

import 'package:xml/xml.dart';

import 'source_models.dart';

class PodcastSubscription {
  const PodcastSubscription({required this.title, required this.url});
  final String title;
  final Uri url;
}

/// Small, bounded OPML reader/writer for portable podcast subscriptions.
/// Feed URLs are credentials for some services and must only be persisted in
/// the source vault or included in a user-requested export.
class PodcastOpml {
  static const maxBytes = 2 * 1024 * 1024;
  static const maxFeeds = 500;

  static List<PodcastSubscription> parse(String content) {
    if (utf8.encode(content).length > maxBytes) throw const SourceException(SourceFailure.invalidData);
    final document = XmlDocument.parse(content);
    if (document.rootElement.name.local != 'opml') throw const SourceException(SourceFailure.invalidData);
    final result = <PodcastSubscription>[];
    final seen = <String>{};
    for (final outline in document.descendants.whereType<XmlElement>().where((node) => node.name.local == 'outline')) {
      final rawUrl = outline.getAttribute('xmlUrl') ?? outline.getAttribute('xmlurl');
      if (rawUrl == null || rawUrl.trim().isEmpty) continue;
      final url = Uri.tryParse(rawUrl.trim());
      if (url == null ||
          url.host.isEmpty ||
          url.scheme != 'https' ||
          url.userInfo.isNotEmpty ||
          url.hasFragment ||
          url.toString().length > 8192) {
        // OPML imports accept HTTPS only. A user can manually add an
        // explicitly approved local HTTP feed from the source form.
        continue;
      }
      if (!seen.add(url.toString())) continue;
      final title = outline.getAttribute('title') ?? outline.getAttribute('text') ?? url.host;
      result.add(PodcastSubscription(title: title.trim().isEmpty ? url.host : title.trim(), url: url));
      if (result.length > maxFeeds) throw const SourceException(SourceFailure.invalidData);
    }
    if (result.isEmpty) throw const SourceException(SourceFailure.invalidData);
    return result;
  }

  static String write(Iterable<PodcastSubscription> subscriptions) {
    final feeds = subscriptions.toList(growable: false);
    if (feeds.length > maxFeeds) throw const SourceException(SourceFailure.invalidData);
    if (feeds.any((feed) =>
        feed.url.host.isEmpty ||
        !const {'https', 'http'}.contains(feed.url.scheme) ||
        feed.url.userInfo.isNotEmpty ||
        feed.url.hasFragment ||
        feed.url.toString().length > 8192)) {
      throw const SourceException(SourceFailure.permission);
    }
    final outlines = feeds
        .map(
          (feed) => XmlElement(
            XmlName('outline'),
            [
              XmlAttribute(XmlName('type'), 'rss'),
              XmlAttribute(XmlName('text'), feed.title),
              XmlAttribute(XmlName('title'), feed.title),
              XmlAttribute(XmlName('xmlUrl'), feed.url.toString()),
            ],
          ),
        )
        .toList();
    final document = XmlDocument([
      XmlDeclaration([
        XmlAttribute(XmlName('version'), '1.0'),
        XmlAttribute(XmlName('encoding'), 'UTF-8'),
      ]),
      XmlElement(
        XmlName('opml'),
        [XmlAttribute(XmlName('version'), '2.0')],
        [
          XmlElement(XmlName('head'), [], [XmlElement(XmlName('title'), [], [XmlText('PlezyNG Podcasts')])]),
          XmlElement(XmlName('body'), [], outlines),
        ],
      ),
    ]);
    final result = document.toXmlString(pretty: true);
    if (utf8.encode(result).length > maxBytes) throw const SourceException(SourceFailure.invalidData);
    return result;
  }
}
