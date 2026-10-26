import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/sources/adapters/dlna_source.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  test('DLNA resolves same-host ContentDirectory metadata and paginates safely', () async {
    final requests = <http.Request>[];
    const didl = '''
<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">
  <item id="movie-1"><dc:title>Example Film</dc:title><upnp:class>object.item.videoItem</upnp:class>
    <res protocolInfo="http-get:*:video/mp4:*" size="123" duration="00:01:02.500">https://nas.example/media/movie.mp4</res>
  </item>
</DIDL-Lite>''';
    final adapter = DlnaSourceAdapter(
      const FileSource(
        id: 'dlna',
        profileId: 'profile',
        kind: FileSourceKind.dlna,
        name: 'Living room',
        endpoint: 'https://nas.example/rootDesc.xml',
      ),
      SourceTransport(
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response('''
<root><URLBase>https://nas.example/</URLBase><serviceList><service>
  <serviceType>urn:schemas-upnp-org:service:ContentDirectory:1</serviceType>
  <controlURL>/ContentDirectory/control</controlURL>
</service></serviceList></root>''', 200);
          }
          expect(request.url.path, '/ContentDirectory/control');
          expect(request.headers['soapaction'], contains('#Browse'));
          expect(request.body, contains('<ObjectID>0</ObjectID>'));
          return http.Response('''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body><u:BrowseResponse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">
    <Result><![CDATA[$didl]]></Result><NumberReturned>1</NumberReturned><TotalMatches>2</TotalMatches>
  </u:BrowseResponse></s:Body>
</s:Envelope>''', 200);
        }),
      ),
    );

    final firstPage = await adapter.browse();
    expect(firstPage.entries.single.title, 'Example Film');
    expect(firstPage.entries.single.kind, SourceItemKind.video);
    expect(firstPage.entries.single.files.single.size, 123);
    expect(firstPage.entries.single.files.single.durationMs, 62500);
    expect(firstPage.next, '1');

    await adapter.browse(cursor: firstPage.next);
    expect(requests.where((request) => request.method == 'POST'), hasLength(2));
    expect(requests.last.body, contains('<StartingIndex>1</StartingIndex>'));
    adapter.close();
  });

  test('DLNA rejects a foreign control URL before sending SOAP requests', () async {
    final requests = <http.Request>[];
    final adapter = DlnaSourceAdapter(
      const FileSource(
        id: 'dlna',
        profileId: 'profile',
        kind: FileSourceKind.dlna,
        name: 'Living room',
        endpoint: 'https://nas.example/rootDesc.xml',
      ),
      SourceTransport(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('''
<root><serviceList><service>
  <serviceType>urn:schemas-upnp-org:service:ContentDirectory:1</serviceType>
  <controlURL>https://evil.example/control</controlURL>
</service></serviceList></root>''', 200);
        }),
      ),
    );

    await expectLater(
      adapter.browse(),
      throwsA(isA<SourceException>().having((error) => error.reason, 'reason', SourceFailure.permission)),
    );
    expect(requests, hasLength(1));
    adapter.close();
  });
}
