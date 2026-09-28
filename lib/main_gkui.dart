import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gkui/diagnostics.dart';

const String _buildLabel = 'Plezy GKUI M0';
const String _sourceBase = 'Plezy 1.8.1 / 10d4b308';
const String _toolchain = 'Flutter 3.19.6 / Dart 3.3.4 / API 19';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const PlezyGkuiApp());
}

class PlezyGkuiApp extends StatelessWidget {
  const PlezyGkuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFFE5A00D),
      secondary: Color(0xFFE5A00D),
      surface: Color(0xFF171717),
      background: Color(0xFF0B0B0B),
      error: Color(0xFFFF6B6B),
    );
    return MaterialApp(
      title: 'Plezy GKUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        fontFamily: 'PlezySans',
        visualDensity: VisualDensity.standard,
      ),
      home: const GkuiShell(),
    );
  }
}

class GkuiShell extends StatefulWidget {
  const GkuiShell({super.key});

  @override
  State<GkuiShell> createState() => _GkuiShellState();
}

class _GkuiShellState extends State<GkuiShell> {
  int _selectedIndex = 0;
  final RedactingLogStore _logs = RedactingLogStore();

  @override
  void initState() {
    super.initState();
    _logs.add('M0 shell started; Plex and player are intentionally disabled.');
  }

  @override
  void dispose() {
    _logs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _HomePane(),
      const _LibraryPane(),
      DiagnosticsPane(logs: _logs),
    ];
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            Container(
              width: 116,
              color: const Color(0xFF121212),
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIndex: _selectedIndex,
                labelType: NavigationRailLabelType.all,
                minWidth: 112,
                minExtendedWidth: 112,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                leading: Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 20),
                  child: Image.asset(
                    'assets/plezy.png',
                    width: 52,
                    height: 52,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.play_circle_fill,
                      size: 52,
                      color: Color(0xFFE5A00D),
                    ),
                  ),
                ),
                destinations: const <NavigationRailDestination>[
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined, size: 32),
                    selectedIcon: Icon(Icons.home, size: 34),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.video_library_outlined, size: 32),
                    selectedIcon: Icon(Icons.video_library, size: 34),
                    label: Text('Library'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.monitor_heart_outlined, size: 32),
                    selectedIcon: Icon(Icons.monitor_heart, size: 34),
                    label: Text('Status'),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: pages[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}

class _HomePane extends StatelessWidget {
  const _HomePane();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      children: const <Widget>[
        _PageHeading(
          title: 'Plezy GKUI',
          subtitle: 'API 19 compatibility shell — no account required',
        ),
        SizedBox(height: 24),
        _Shelf(title: 'Continue Watching'),
        SizedBox(height: 28),
        _Shelf(title: 'Recently Added'),
      ],
    );
  }
}

class _LibraryPane extends StatelessWidget {
  const _LibraryPane();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: const <Widget>[
        _PageHeading(
          title: 'Library',
          subtitle: 'Poster grid placeholder for the first hardware gate',
        ),
        SizedBox(height: 24),
        Wrap(
          spacing: 18,
          runSpacing: 22,
          children: <Widget>[
            _PosterPlaceholder(index: 1),
            _PosterPlaceholder(index: 2),
            _PosterPlaceholder(index: 3),
            _PosterPlaceholder(index: 4),
            _PosterPlaceholder(index: 5),
            _PosterPlaceholder(index: 6),
          ],
        ),
      ],
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (_, index) => _PosterPlaceholder(index: index + 1),
          ),
        ),
      ],
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Poster placeholder $index',
      child: SizedBox(
        width: 136,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 136,
              height: 184,
              decoration: BoxDecoration(
                color: Color(0xFF222222 + ((index % 3) * 0x080808)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.movie_outlined,
                size: 52,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Title $index',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class DiagnosticsPane extends StatefulWidget {
  const DiagnosticsPane({required this.logs, super.key});

  final RedactingLogStore logs;

  @override
  State<DiagnosticsPane> createState() => _DiagnosticsPaneState();
}

class _DiagnosticsPaneState extends State<DiagnosticsPane> {
  late Future<DeviceDiagnostics> _diagnostics;

  @override
  void initState() {
    super.initState();
    _diagnostics = _load();
  }

  Future<DeviceDiagnostics> _load() async {
    try {
      final result = await DeviceDiagnostics.load();
      widget.logs.add('Device diagnostics loaded.');
      return result;
    } on PlatformException catch (error) {
      widget.logs.add('Device diagnostics failed: ${error.code}.');
      rethrow;
    } on MissingPluginException {
      widget.logs.add('Device diagnostics channel is unavailable.');
      rethrow;
    }
  }

  void _refresh() {
    setState(() => _diagnostics = _load());
  }

  Future<void> _copy() async {
    final snapshot = await _diagnostics;
    final details = snapshot.values.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
    await Clipboard.setData(
      ClipboardData(
        text: '$_buildLabel\n$_sourceBase\n$_toolchain\n$details\n\n'
            '${widget.logs.exportText()}',
      ),
    );
    widget.logs.add('Diagnostics copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: _PageHeading(
                  title: 'Device status',
                  subtitle: 'No Plex account or player is configured in M0',
                ),
              ),
              _LargeButton(
                icon: Icons.refresh,
                label: 'Refresh',
                onPressed: _refresh,
              ),
              const SizedBox(width: 12),
              _LargeButton(
                icon: Icons.copy,
                label: 'Copy',
                onPressed: _copy,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _DiagnosticsCard(diagnostics: _diagnostics),
                ),
                const SizedBox(width: 18),
                Expanded(child: _LogCard(logs: widget.logs)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeButton extends StatelessWidget {
  const _LargeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 26),
        label: Text(label, style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.diagnostics});

  final Future<DeviceDiagnostics> diagnostics;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF171717),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<DeviceDiagnostics>(
          future: diagnostics,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Diagnostics unavailable. Use Refresh after relaunch.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            final rows = <MapEntry<String, String>>[
              const MapEntry<String, String>('build', _buildLabel),
              const MapEntry<String, String>('source', _sourceBase),
              const MapEntry<String, String>('toolchain', _toolchain),
              ...snapshot.requireData.values.entries,
            ];
            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 18),
              itemBuilder: (context, index) {
                final row = rows[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 142,
                      child: Text(
                        row.key,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        row.value,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.logs});

  final RedactingLogStore logs;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF171717),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Bounded local log',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: logs,
                builder: (context, _) {
                  final entries = logs.entries;
                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SelectableText(
                        entries[index].line,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
