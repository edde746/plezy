import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/insecure_connection_consent.dart';

void main() {
  testWidgets('HTTP confirmation hides URL credentials, query and fragment', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => confirmed = await confirmInsecureConnection(
                context,
                'http://user:password@example.com:8096/jellyfin?api_key=secret#private',
              ),
              child: const Text('Connect'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(find.textContaining('http://example.com:8096/jellyfin'), findsOneWidget);
    expect(find.textContaining('user:password@'), findsNothing);
    expect(find.textContaining('?api_key=secret'), findsNothing);
    expect(find.textContaining('#private'), findsNothing);

    await tester.tap(find.text('Allow HTTP'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('HTTPS endpoints proceed without an HTTP confirmation', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => confirmed = await confirmInsecureConnection(context, 'https://example.com'),
              child: const Text('Connect'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('declining an HTTP confirmation blocks the connection', (tester) async {
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => confirmed = await confirmInsecureConnection(context, 'http://example.com'),
              child: const Text('Connect'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
  });
}
