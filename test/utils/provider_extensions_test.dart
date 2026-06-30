import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/media/ids.dart';
import 'package:vibe_stream/utils/provider_extensions.dart';

void main() {
  testWidgets('optional media-client lookups return null without MultiServerProvider', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(capturedContext.tryGetMediaClientForServer(ServerId('server-1')), isNull);
    expect(capturedContext.tryGetMediaClientWithFallback(ServerId('server-1')), isNull);
    expect(capturedContext.tryGetPlexClientForServer(ServerId('server-1')), isNull);
  });
}
