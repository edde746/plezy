import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../providers/seerr_session_provider.dart';
import '../../widgets/app_icon.dart';
import 'my_requests_screen.dart';
import 'seerr_discover_screen.dart';
import 'seerr_login_screen.dart';
import 'seerr_search_screen.dart';

/// Root widget for the Seerr top-level nav tab.
///
/// Branches on [SeerrSessionProvider.isConnected]:
///   - connected → `DefaultTabController` with Discover / Search / Requests
///   - bound-but-invalid → re-login form
///   - unbound → "Add a Seerr server in settings" empty state
///
/// Search results from a Plezy main-search "Not in your library" tap pass
/// [initialSearchQuery] so we can land directly on the Search sub-tab with
/// the query pre-populated.
class SeerrTabRoot extends StatelessWidget {
  final String? initialSearchQuery;

  const SeerrTabRoot({super.key, this.initialSearchQuery});

  @override
  Widget build(BuildContext context) {
    return Consumer<SeerrSessionProvider>(
      builder: (context, session, _) {
        if (!session.isConnected) {
          return Scaffold(
            appBar: AppBar(title: Text(t.seerr.tab)),
            body: SeerrLoginScreen(connection: session.connection),
          );
        }
        final initialIndex = (initialSearchQuery ?? '').isNotEmpty ? 1 : 0;
        return DefaultTabController(
          length: 3,
          initialIndex: initialIndex,
          child: Scaffold(
            appBar: AppBar(
              title: Text(t.seerr.tab),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: Builder(
                  builder: (innerContext) {
                    final controller = DefaultTabController.of(innerContext);
                    Widget tab(int index, IconData icon, String label) => FocusableWrapper(
                      disableScale: true,
                      borderRadius: 6,
                      descendantsAreFocusable: false,
                      onSelect: () => controller.animateTo(index),
                      child: Tab(icon: AppIcon(icon, fill: 1), text: label),
                    );
                    return TabBar(
                      tabs: [
                        tab(0, Symbols.explore_rounded, t.seerr.tabs.discover),
                        tab(1, Symbols.search_rounded, t.seerr.tabs.search),
                        tab(2, Symbols.list_alt_rounded, t.seerr.tabs.myRequests),
                      ],
                    );
                  },
                ),
              ),
            ),
            body: TabBarView(
              children: [
                const SeerrDiscoverScreen(),
                SeerrSearchScreen(initialQuery: initialSearchQuery),
                const MyRequestsScreen(),
              ],
            ),
          ),
        );
      },
    );
  }
}
