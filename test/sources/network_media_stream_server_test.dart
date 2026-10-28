import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/network_media_stream_server.dart';

void main() {
  test('serves token-scoped HLS only to a private peer and closes cleanly', () async {
    final version = await Process.run('ffmpeg', const ['-hide_banner', '-version']);
    if (version.exitCode != 0) markTestSkipped('FFmpeg is not installed');

    final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.IPv4);
    final hasPrivateAddress = interfaces.any(
      (interface) => interface.addresses.any(NetworkMediaStreamPolicy.isPrivateIPv4),
    );
    if (!hasPrivateAddress) markTestSkipped('No private IPv4 address is available');

    final directory = await Directory.systemTemp.createTemp('plezy-stream-server-test-');
    final input = File('${directory.path}/sample.mp4');
    final generated = await Process.run('ffmpeg', [
      '-hide_banner',
      '-loglevel',
      'error',
      '-f',
      'lavfi',
      '-i',
      'color=c=black:s=64x64:r=10',
      '-f',
      'lavfi',
      '-i',
      'sine=frequency=440:sample_rate=44100',
      '-t',
      '30',
      '-c:v',
      'libx264',
      '-preset',
      'ultrafast',
      '-pix_fmt',
      'yuv420p',
      '-c:a',
      'aac',
      '-movflags',
      '+faststart',
      '-y',
      input.path,
    ]);
    if (generated.exitCode != 0) {
      await directory.delete(recursive: true);
      markTestSkipped('FFmpeg does not include the H.264/AAC encoders');
    }

    final server = NetworkMediaStreamServer(lifetime: const Duration(minutes: 1));
    final client = HttpClient();
    addTearDown(() async {
      client.close(force: true);
      await server.stop();
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    await server.start(input);
    expect(server.isRunning, isTrue);
    expect(server.expiresAt, isNotNull);
    expect(
      server.urls,
      hasLength(
        interfaces.expand((item) => item.addresses).where(NetworkMediaStreamPolicy.isPrivateIPv4).toSet().length,
      ),
    );

    final advertised = Uri.parse(server.urls.first);
    final localBase = Uri(scheme: 'http', host: '127.0.0.1', port: advertised.port);
    Future<HttpClientResponse> request(String method, String path) async {
      final request = await client.openUrl(method, localBase.replace(path: path));
      request.headers.set(HttpHeaders.hostHeader, '${advertised.host}:${advertised.port}');
      return request.close();
    }

    final playlist = await request('GET', advertised.path);
    expect(playlist.statusCode, HttpStatus.ok);
    expect(playlist.headers.contentType?.mimeType, 'application/vnd.apple.mpegurl');
    final playlistBody = await utf8.decoder.bind(playlist).join();
    expect(playlistBody, contains('#EXTM3U'));
    final segmentName = RegExp(r'^segment\d+\.ts$', multiLine: true).firstMatch(playlistBody)?.group(0);
    expect(segmentName, isNotNull, reason: 'The playlist should be published with its first media segment.');
    if (segmentName == null) fail('The HLS playlist did not name its first segment.');
    final segmentPath = '${advertised.path.substring(0, advertised.path.lastIndexOf('/') + 1)}$segmentName';
    final segment = await request('GET', segmentPath);
    expect(segment.statusCode, HttpStatus.ok);
    expect(segment.headers.contentType?.mimeType, 'video/mp2t');
    expect(await segment.fold<int>(0, (length, chunk) => length + chunk.length), greaterThan(0));

    final invalidToken = await request('GET', '/wrong-token/index.m3u8');
    expect(invalidToken.statusCode, HttpStatus.notFound);
    await invalidToken.drain<void>();

    final invalidSegment = await request('GET', '/wrong-token/$segmentName');
    expect(invalidSegment.statusCode, HttpStatus.notFound);
    await invalidSegment.drain<void>();

    final post = await request('POST', advertised.path);
    expect(post.statusCode, HttpStatus.methodNotAllowed);
    expect(post.headers.value(HttpHeaders.allowHeader), 'GET, HEAD');
    await post.drain<void>();

    final expiredPort = advertised.port;
    await server.stop();
    expect(server.isRunning, isFalse);
    expect(server.urls, isEmpty);
    expect(server.expiresAt, isNull);
    await expectLater(() async {
      final request = await client.getUrl(
        Uri(scheme: 'http', host: '127.0.0.1', port: expiredPort, path: advertised.path),
      );
      await request.close();
    }, throwsA(isA<SocketException>()));
  });
}
