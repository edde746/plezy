import 'package:mime/mime.dart';
import 'package:xml/xml.dart';

import '../source_models.dart';
import '../source_transport.dart';

/// UPnP/DLNA ContentDirectory source. The configured endpoint is the device
/// description URL; SSDP discovery is best effort, with direct entry available
/// on platforms or networks that block multicast.
class DlnaSourceAdapter extends SourceAdapter {
  DlnaSourceAdapter(super.source, super.transport);

  static const _soapEnvelopeNs = 'http://schemas.xmlsoap.org/soap/envelope/';
  static const _requestedCount = 200;
  _DlnaService? _service;

  @override
  SourceCapabilities get capabilities => const SourceCapabilities(rangeRequests: true);

  Uri get _endpoint {
    final uri = Uri.tryParse(source.endpoint.trim());
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const SourceException(SourceFailure.permission);
    }
    transport.validate(uri);
    return uri;
  }

  Future<_DlnaService> _getService() async {
    final cached = _service;
    if (cached != null) return cached;
    final endpoint = _endpoint;
    final xml = await transport.text('GET', endpoint, limit: 2 * 1024 * 1024);
    final document = XmlDocument.parse(xml);
    final baseText = _descendants(
      document,
    ).where((element) => element.name.local == 'URLBase').map((element) => element.innerText.trim()).firstOrNull;
    final base = baseText == null || baseText.isEmpty ? endpoint : endpoint.resolve(baseText);
    _validateSameHost(base);
    for (final service in _descendants(document).where((element) => element.name.local == 'service')) {
      final type = _childText(service, 'serviceType');
      final control = _childText(service, 'controlURL');
      if (type == null || !type.contains(':ContentDirectory:') || control == null || control.isEmpty) continue;
      final uri = base.resolve(control);
      _validateSameHost(uri);
      final result = _DlnaService(type: type, control: uri, base: base);
      _service = result;
      return result;
    }
    throw const SourceException(SourceFailure.unsupported);
  }

  void _validateSameHost(Uri uri) {
    transport.validate(uri);
    if (uri.host.toLowerCase() != _endpoint.host.toLowerCase() || uri.userInfo.isNotEmpty || uri.hasFragment) {
      throw const SourceException(SourceFailure.permission);
    }
  }

  static Iterable<XmlElement> _descendants(XmlNode node) sync* {
    for (final child in node.children) {
      if (child is XmlElement) {
        yield child;
        yield* _descendants(child);
      }
    }
  }

  static String? _childText(XmlElement parent, String localName) {
    for (final child in parent.children.whereType<XmlElement>()) {
      if (child.name.local == localName) return child.innerText.trim();
    }
    return null;
  }

  static String? _descendantText(XmlNode parent, String localName) => _descendants(
    parent,
  ).where((element) => element.name.local == localName).map((element) => element.innerText.trim()).firstOrNull;

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  Future<_DlnaBrowseResult> _browse(String objectId, {required bool metadata, int start = 0}) async {
    final service = await _getService();
    final flag = metadata ? 'BrowseMetadata' : 'BrowseDirectChildren';
    final body =
        '''
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="$_soapEnvelopeNs" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:Browse xmlns:u="${_xmlEscape(service.type)}">
      <ObjectID>${_xmlEscape(objectId)}</ObjectID>
      <BrowseFlag>$flag</BrowseFlag>
      <Filter>*</Filter>
      <StartingIndex>$start</StartingIndex>
      <RequestedCount>${metadata ? 0 : _requestedCount}</RequestedCount>
      <SortCriteria></SortCriteria>
    </u:Browse>
  </s:Body>
</s:Envelope>''';
    final response = await transport.text(
      'POST',
      service.control,
      headers: {'Content-Type': 'text/xml; charset="utf-8"', 'SOAPAction': '"${service.type}#Browse"'},
      body: body,
      limit: 4 * 1024 * 1024,
    );
    final soap = XmlDocument.parse(response);
    final resultXml = _descendants(
      soap,
    ).where((element) => element.name.local == 'Result').map((element) => element.innerText).firstOrNull;
    if (resultXml == null || resultXml.isEmpty) throw const SourceException(SourceFailure.invalidData);
    final didl = XmlDocument.parse(resultXml);
    final rows = <_DlnaObject>[];
    for (final element in didl.rootElement.children.whereType<XmlElement>()) {
      if (!const {'item', 'container'}.contains(element.name.local)) continue;
      final row = _parseObject(element, service);
      if (row != null) rows.add(row);
    }
    final returned = int.tryParse(
      _descendants(soap)
              .where((element) => element.name.local == 'NumberReturned')
              .map((element) => element.innerText.trim())
              .firstOrNull ??
          '',
    );
    final total = int.tryParse(
      _descendants(soap)
              .where((element) => element.name.local == 'TotalMatches')
              .map((element) => element.innerText.trim())
              .firstOrNull ??
          '',
    );
    return _DlnaBrowseResult(rows, returned ?? rows.length, total ?? rows.length);
  }

  _DlnaObject? _parseObject(XmlElement element, _DlnaService service) {
    final id = element.getAttribute('id');
    final title = _descendantText(element, 'title');
    if (id == null || id.isEmpty || title == null || title.isEmpty) return null;
    if (element.name.local == 'container') {
      return _DlnaObject(
        entry: SourceEntry(sourceId: source.id, id: id, title: title, kind: SourceItemKind.folder),
      );
    }

    final resources = <_DlnaResource>[];
    for (final res in element.children.whereType<XmlElement>().where((child) => child.name.local == 'res')) {
      final url = res.innerText.trim();
      if (url.isEmpty) continue;
      final resourceUri = service.base.resolve(url);
      _validateSameHost(resourceUri);
      final protocol = res.getAttribute('protocolInfo') ?? '';
      final protocolParts = protocol.split(':');
      final mimeType = protocolParts.length >= 3 ? protocolParts[2] : '';
      final name = resourceUri.pathSegments.isEmpty ? title : Uri.decodeComponent(resourceUri.pathSegments.last);
      final kind = classifySourceFile(name, mimeType);
      final duration = _durationMs(res.getAttribute('duration'));
      final size = int.tryParse(res.getAttribute('size') ?? '');
      resources.add(_DlnaResource(resourceUri, mimeType, name, kind, size, duration));
    }
    resources.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
    final mediaClass = (_descendantText(element, 'class') ?? '').toLowerCase();
    final preferred = resources
        .where(
          (resource) =>
              resource.kind == SourceItemKind.video ||
              resource.kind == SourceItemKind.music ||
              mediaClass.contains('video') && resource.mimeType.startsWith('video/') ||
              mediaClass.contains('audio') && resource.mimeType.startsWith('audio/'),
        )
        .firstOrNull;
    if (preferred == null) return null;
    final kind = mediaClass.contains('video') || preferred.kind == SourceItemKind.video
        ? SourceItemKind.video
        : SourceItemKind.music;
    final file = PublicationFile(
      id: id,
      name: preferred.name.isEmpty ? title : preferred.name,
      mimeType: preferred.mimeType.isEmpty ? lookupMimeType(preferred.name) ?? '' : preferred.mimeType,
      size: preferred.size,
      durationMs: preferred.durationMs,
    );
    return _DlnaObject(
      resource: preferred,
      entry: SourceEntry(sourceId: source.id, id: id, title: title, kind: kind, files: [file]),
    );
  }

  static int? _durationMs(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'^(\d+):(\d{2}):(\d{2})(?:\.(\d+))?$').firstMatch(raw);
    if (match == null) return null;
    final hours = int.tryParse(match[1]!) ?? 0;
    final minutes = int.tryParse(match[2]!) ?? 0;
    final seconds = int.tryParse(match[3]!) ?? 0;
    final fractionDigits = match[4];
    final fraction = fractionDigits == null ? 0 : int.parse('${fractionDigits}000'.substring(0, 3));
    return ((hours * 3600 + minutes * 60 + seconds) * 1000) + fraction;
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final root = source.root.trim().isEmpty ? '0' : source.root.trim();
    final objectId = parent ?? root;
    final start = int.tryParse(cursor ?? '') ?? 0;
    if (start < 0) throw const SourceException(SourceFailure.invalidData);
    final result = await _browse(objectId, metadata: false, start: start);
    final entries = result.objects
        .where((item) => query == null || item.entry.title.toLowerCase().contains(query.toLowerCase()))
        .map((item) => item.entry.copyWith(parentId: objectId))
        .toList(growable: false);
    final next = result.total > start + result.returned ? '${start + result.returned}' : null;
    return SourcePage(entries, next: next);
  }

  @override
  Future<SourceEntry> hydrate(SourceEntry entry) async {
    if (entry.kind == SourceItemKind.folder) return entry;
    final result = await _browse(entry.id, metadata: true);
    return result.objects.map((item) => item.entry).where((item) => item.id == entry.id).firstOrNull ?? entry;
  }

  Future<_DlnaResource> _resource(String objectId) async {
    final result = await _browse(objectId, metadata: true);
    final resource = result.objects
        .where((item) => item.entry.id == objectId)
        .map((item) => item.resource)
        .whereType<_DlnaResource>()
        .firstOrNull;
    if (resource == null) throw const SourceException(SourceFailure.unsupported);
    return resource;
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final resource = await _resource(file.id);
    return ContentLease(resource.uri, size: resource.size);
  }

  @override
  Future<int?> contentSize(PublicationFile file) async => file.size ?? (await _resource(file.id)).size;

  @override
  Future<SourceByteStream?> openContent(PublicationFile file, {required int offset, required int length}) async => null;
}

class _DlnaService {
  const _DlnaService({required this.type, required this.control, required this.base});
  final String type;
  final Uri control;
  final Uri base;
}

class _DlnaResource {
  const _DlnaResource(this.uri, this.mimeType, this.name, this.kind, this.size, this.durationMs);
  final Uri uri;
  final String mimeType;
  final String name;
  final SourceItemKind kind;
  final int? size;
  final int? durationMs;
}

class _DlnaObject {
  const _DlnaObject({required this.entry, this.resource});
  final SourceEntry entry;
  final _DlnaResource? resource;
}

class _DlnaBrowseResult {
  const _DlnaBrowseResult(this.objects, this.returned, this.total);
  final List<_DlnaObject> objects;
  final int returned;
  final int total;
}
