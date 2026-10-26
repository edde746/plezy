import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

import '../source_models.dart';
import '../source_transport.dart';
import 'webdav_source.dart';

/// SigV4 query signing works with AWS S3 and compatible private object stores.
/// The configured endpoint includes the bucket (path or virtual-host style).
class S3SourceAdapter extends SourceAdapter {
  S3SourceAdapter(super.source, super.transport, this.credentials);
  final SourceCredentials credentials;
  @override
  SourceCapabilities get capabilities => const SourceCapabilities();

  static String _encode(String value) => Uri.encodeComponent(
    value,
  ).replaceAll('!', '%21').replaceAll("'", '%27').replaceAll('(', '%28').replaceAll(')', '%29').replaceAll('*', '%2A');
  static List<int> _hmac(List<int> key, String value) => Hmac(sha256, key).convert(utf8.encode(value)).bytes;

  static Uri sign({
    required Uri uri,
    required String accessKey,
    required String secretKey,
    required String region,
    required DateTime time,
    String? sessionToken,
    int expires = 900,
  }) {
    final timestamp =
        '${time.toUtc().toIso8601String().replaceAll('-', '').replaceAll(':', '').split('.').first.replaceAll('Z', '')}Z';
    final date = timestamp.substring(0, 8), scope = '$date/$region/s3/aws4_request';
    final parameters = <String, String>{
      ...uri.queryParameters,
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': '$accessKey/$scope',
      'X-Amz-Date': timestamp,
      'X-Amz-Expires': '$expires',
      'X-Amz-SignedHeaders': 'host',
      if (sessionToken?.isNotEmpty == true) 'X-Amz-Security-Token': sessionToken!,
    };
    final keys = parameters.keys.toList()..sort();
    final query = keys.map((k) => '${_encode(k)}=${_encode(parameters[k]!)}').join('&');
    final path = '/${uri.pathSegments.map(_encode).join('/')}';
    final canonical = 'GET\n$path\n$query\nhost:${uri.authority}\n\nhost\nUNSIGNED-PAYLOAD';
    final toSign = 'AWS4-HMAC-SHA256\n$timestamp\n$scope\n${sha256.convert(utf8.encode(canonical))}';
    final key = _hmac(_hmac(_hmac(_hmac(utf8.encode('AWS4$secretKey'), date), region), 's3'), 'aws4_request');
    final signature = Hmac(sha256, key).convert(utf8.encode(toSign)).toString();
    return Uri.parse('${uri.scheme}://${uri.authority}$path?$query&X-Amz-Signature=$signature');
  }

  Future<Uri> _signed(Uri uri) async {
    final c = await credentials();
    return sign(
      uri: uri,
      accessKey: c['accessKey'] ?? '',
      secretKey: c['secretKey'] ?? '',
      region: source.options['region'] ?? 'us-east-1',
      sessionToken: c['sessionToken'],
      time: DateTime.now(),
    );
  }

  Uri get _base => Uri.parse(source.endpoint.endsWith('/') ? source.endpoint : '${source.endpoint}/');
  void _checkKey(String key) {
    if (key.startsWith('/') ||
        key.split('/').any((p) => p == '..' || p == '.') ||
        key.contains('\\') ||
        (source.root.isNotEmpty &&
            !(key == source.root || key.startsWith(source.root.endsWith('/') ? source.root : '${source.root}/')))) {
      throw const SourceException(SourceFailure.permission);
    }
  }

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final prefix = parent ?? source.root;
    _checkKey(prefix);
    final target = _base.replace(
      queryParameters: {
        'list-type': '2',
        'prefix': prefix,
        'delimiter': '/',
        'max-keys': '200',
        'continuation-token': ?cursor,
      },
    );
    final xml = XmlDocument.parse(await transport.text('GET', await _signed(target)));
    String text(XmlElement node, String name) =>
        node.childElements.where((e) => e.name.local == name).firstOrNull?.innerText ?? '';
    final entries = <SourceEntry>[];
    for (final node in xml.rootElement.childElements) {
      if (node.name.local != 'CommonPrefixes' && node.name.local != 'Contents') continue;
      final folder = node.name.local == 'CommonPrefixes';
      final id = text(node, folder ? 'Prefix' : 'Key');
      if (id == prefix || id.isEmpty) continue;
      _checkKey(id);
      final name = id.replaceAll(RegExp(r'/+$'), '').split('/').last;
      if (query != null && !name.toLowerCase().contains(query.toLowerCase())) continue;
      final kind = folder ? SourceItemKind.folder : classifySourceFile(name);
      if (kind == SourceItemKind.unknown) continue;
      entries.add(
        SourceEntry(
          sourceId: source.id,
          id: id,
          title: name,
          kind: kind,
          parentId: prefix,
          files: folder
              ? []
              : [
                  PublicationFile(
                    id: id,
                    name: name,
                    mimeType: '',
                    size: sourceInt(text(node, 'Size')),
                    revision: text(node, 'ETag'),
                  ),
                ],
        ),
      );
    }
    final next = text(xml.rootElement, 'NextContinuationToken');
    return SourcePage(entries, next: next.isEmpty ? null : next);
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    _checkKey(file.id);
    final uri = _base.replace(pathSegments: [..._base.pathSegments.where((s) => s.isNotEmpty), ...file.id.split('/')]);
    return ContentLease(
      await _signed(uri),
      size: file.size,
      expiresAt: DateTime.now().add(const Duration(minutes: 14)),
    );
  }
}
