import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/widgets/server_activities_button.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('togglePanel opens and closes the server activities overlay', (tester) async {
    final manager = MultiServerManager();
    final multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    final buttonKey = GlobalKey<ServerActivitiesButtonState>();

    addTearDown(() {
      multiServerProvider.dispose();
      manager.dispose();
    });

    await tester.pumpWidget(
      TranslationProvider(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: multiServerProvider,
          child: MaterialApp(
            home: Scaffold(body: ServerActivitiesButton(key: buttonKey)),
          ),
        ),
      ),
    );

    buttonKey.currentState!.togglePanel();
    await tester.pump();
    await tester.pump();

    expect(find.text(t.serverTasks.title), findsOneWidget);
    expect(find.text(t.serverTasks.noTasks), findsOneWidget);

    buttonKey.currentState!.togglePanel();
    await tester.pump();

    expect(find.text(t.serverTasks.title), findsNothing);
  });
}
