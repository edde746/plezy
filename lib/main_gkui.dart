import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'gkui/diagnostics.dart';
import 'gkui/plex_api.dart';

const String buildLabel = 'Plezy GKUI 1.0 consolidated';
const String sourceLabel = 'Plezy 1.8.1 / GKUI compatibility fork';
const String toolchainLabel = 'Flutter 3.19.6 / ExoPlayer 2.19.1 / API 19';
const MethodChannel nativeChannel =
    MethodChannel('com.jialim.plezygkui/diagnostics');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlexApi.installLegacyTrust();
  PaintingBinding.instance.imageCache.maximumSize = 48;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 16 * 1024 * 1024;
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
    const scheme = ColorScheme.dark(
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
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.background,
        fontFamily: 'PlezySans',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(minimumSize: const Size(96, 54)),
        ),
      ),
      home: const GkuiRoot(),
    );
  }
}

enum AppPhase { starting, signedOut, signingIn, chooseServer, ready, error }

enum PlaybackMode { direct, transcode720, transcode480 }

class GkuiController extends ChangeNotifier {
  final RedactingLogStore logs = RedactingLogStore(capacity: 160);
  PlexApi? api;
  AppPhase phase = AppPhase.starting;
  String? error;
  PlexPin? pin;
  String? pendingAccountToken;
  List<PlexServerResource> servers = const <PlexServerResource>[];
  List<PlexShelf> shelves = const <PlexShelf>[];
  List<PlexSection> sections = const <PlexSection>[];
  List<PlexMedia> libraryItems = const <PlexMedia>[];
  PlexSection? selectedSection;
  bool loadingContent = false;
  int authGeneration = 0;
  bool disposed = false;

  bool get clockValid => DateTime.now().year >= 2024;

  Future<void> initialize() async {
    logs.add('Starting consolidated GKUI build.');
    if (!clockValid) {
      logs.add('Clock is invalid; secure network access is paused.');
      phase = AppPhase.signedOut;
      notifySafely();
      return;
    }
    try {
      api = await PlexApi.create(logs);
      if (api!.session == null) {
        phase = AppPhase.signedOut;
      } else {
        await refreshContent();
      }
    } catch (caught) {
      fail('Startup failed', caught);
    }
    notifySafely();
  }

  Future<void> retryClock() async {
    if (!clockValid) {
      error =
          'The head-unit date is still ${DateTime.now().year}. Connect Wi-Fi/4G or correct its clock.';
      notifySafely();
      return;
    }
    phase = AppPhase.starting;
    error = null;
    notifySafely();
    await initialize();
  }

  Future<void> beginSignIn() async {
    if (!clockValid) return retryClock();
    final generation = ++authGeneration;
    try {
      api ??= await PlexApi.create(logs);
      error = null;
      pin = await api!.createPin();
      phase = AppPhase.signingIn;
      notifySafely();
      for (var attempt = 0; attempt < 120; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (generation != authGeneration || disposed) return;
        final token = await api!.checkPin(pin!);
        if (token == null || token.isEmpty) continue;
        pendingAccountToken = token;
        logs.add('Plex sign-in approved.');
        servers = await api!.fetchServers(token);
        if (servers.isEmpty) {
          throw StateError(
              'No Plex Media Server with a secure HTTPS address was found.');
        }
        if (servers.length == 1) {
          await connectServer(token, servers.first);
        } else {
          phase = AppPhase.chooseServer;
          notifySafely();
        }
        return;
      }
      throw TimeoutException('Plex sign-in timed out.');
    } catch (caught) {
      if (generation == authGeneration) fail('Sign-in failed', caught);
    }
  }

  Future<void> connectServer(String token, PlexServerResource server) async {
    try {
      phase = AppPhase.starting;
      notifySafely();
      await api!.connect(token, server);
      pendingAccountToken = null;
      await refreshContent();
    } catch (caught) {
      fail('Server connection failed', caught);
    }
  }

  Future<void> chooseServer(PlexServerResource server) async {
    final token = pendingAccountToken;
    if (token == null) {
      fail('Server selection failed',
          StateError('The sign-in token is no longer available.'));
      return;
    }
    await connectServer(token, server);
  }

  Future<void> refreshContent() async {
    if (api?.session == null) return;
    loadingContent = true;
    error = null;
    notifySafely();
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        api!.loadHome(),
        api!.loadSections(),
      ]);
      shelves = results[0] as List<PlexShelf>;
      sections = results[1] as List<PlexSection>;
      selectedSection = sections.isEmpty ? null : sections.first;
      libraryItems = selectedSection == null
          ? const <PlexMedia>[]
          : await api!.loadSection(selectedSection!.key);
      phase = AppPhase.ready;
      logs.add('Plex content is ready.');
    } catch (caught) {
      fail('Could not load Plex content', caught);
    } finally {
      loadingContent = false;
      notifySafely();
    }
  }

  Future<void> selectSection(PlexSection section) async {
    selectedSection = section;
    loadingContent = true;
    error = null;
    notifySafely();
    try {
      libraryItems = await api!.loadSection(section.key);
    } catch (caught) {
      error = message('Library failed to load', caught);
    } finally {
      loadingContent = false;
      notifySafely();
    }
  }

  Future<void> signOut() async {
    authGeneration++;
    await api?.signOut();
    shelves = const <PlexShelf>[];
    sections = const <PlexSection>[];
    libraryItems = const <PlexMedia>[];
    phase = AppPhase.signedOut;
    error = null;
    notifySafely();
  }

  void cancelSignIn() {
    authGeneration++;
    pin = null;
    phase = AppPhase.signedOut;
    error = null;
    notifySafely();
  }

  Future<void> play(
      BuildContext context, PlexMedia media, PlaybackMode mode) async {
    try {
      var item = media;
      if (item.directPartKey == null)
        item = await api!.loadMetadata(item.ratingKey);
      final bitrate = mode == PlaybackMode.transcode480 ? 1500 : 3000;
      final request = api!.playback(
        item,
        transcode: mode != PlaybackMode.direct,
        bitrate: bitrate,
      );
      logs.add(
          'Opening ${request.transcoding ? '${bitrate}kbps HLS' : 'direct'} playback: ${item.title}.');
      await api!.reportProgress(item, item.viewOffsetMs, 'playing');
      final raw = await nativeChannel
          .invokeMapMethod<String, dynamic>('playVideo', <String, dynamic>{
        'url': request.url,
        'headers': request.headers,
        'title': item.title,
        'startMs': item.viewOffsetMs,
        'ratingKey': item.ratingKey,
        'durationMs': item.durationMs,
        'timelineUrl': '${api!.session!.baseUrl}/:/timeline',
      });
      final position =
          (raw?['positionMs'] as num?)?.toInt() ?? item.viewOffsetMs;
      await api!.reportProgress(
          item, position, raw?['ended'] == true ? 'stopped' : 'paused');
      final playerError = raw?['error']?.toString();
      if (playerError != null && playerError.isNotEmpty)
        throw StateError(playerError);
      await refreshContent();
    } catch (caught) {
      logs.add('Playback failed: ${compact(caught)}');
      if (context.mounted) {
        final fallback = mode == PlaybackMode.direct
            ? PlaybackMode.transcode720
            : mode == PlaybackMode.transcode720
                ? PlaybackMode.transcode480
                : null;
        if (fallback != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(mode == PlaybackMode.direct
                ? 'Direct play failed; retrying compatible 720p…'
                : '720p failed; retrying 480p safe mode…'),
          ));
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (context.mounted) await play(context, media, fallback);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Playback failed: ${compact(caught)}'),
        ));
      }
    }
  }

  void fail(String prefix, Object value) {
    error = message(prefix, value);
    logs.add(error!);
    phase = AppPhase.error;
    notifySafely();
  }

  String message(String prefix, Object value) {
    if (value is DioException && value.response?.statusCode == 401) {
      return '$prefix: Plex rejected the account or server token (HTTP 401).';
    }
    if (value is DioException && !clockValid) {
      return '$prefix: secure HTTPS cannot work while the car clock is incorrect.';
    }
    return '$prefix: ${compact(value)}';
  }

  static String compact(Object value) =>
      value.toString().replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '');

  void notifySafely() {
    if (!disposed) notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    authGeneration++;
    logs.dispose();
    super.dispose();
  }
}

class GkuiRoot extends StatefulWidget {
  const GkuiRoot({super.key});
  @override
  State<GkuiRoot> createState() => _GkuiRootState();
}

class _GkuiRootState extends State<GkuiRoot> {
  final GkuiController controller = GkuiController();
  @override
  void initState() {
    super.initState();
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.phase == AppPhase.starting) {
            return const BusyScreen(label: 'Starting Plezy GKUI…');
          }
          if (!controller.clockValid)
            return ClockScreen(controller: controller);
          if (controller.phase == AppPhase.signedOut ||
              controller.phase == AppPhase.error) {
            return WelcomeScreen(controller: controller);
          }
          if (controller.phase == AppPhase.signingIn)
            return PinScreen(controller: controller);
          if (controller.phase == AppPhase.chooseServer)
            return ServerScreen(controller: controller);
          return GkuiShell(controller: controller);
        },
      );
}

class BusyScreen extends StatelessWidget {
  const BusyScreen({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 22),
          Text(label, style: const TextStyle(fontSize: 22)),
        ])),
      );
}

class ClockScreen extends StatelessWidget {
  const ClockScreen({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) => CenteredPanel(
        icon: Icons.schedule,
        title: 'Car clock needs to sync',
        message:
            'This unit reports ${DateTime.now().year}. Secure Plex HTTPS requires the correct date. '
            'Connect the car to Wi-Fi or 4G, let its clock update, then tap Retry. TLS security will not be disabled.',
        error: controller.error,
        primaryLabel: 'Retry clock',
        primaryAction: controller.retryClock,
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) => CenteredPanel(
        icon: Icons.play_circle_fill,
        title: 'Plezy GKUI',
        message:
            'Sign in with Plex to browse your server and play video. Scan the QR code with your phone to approve this car display.',
        error: controller.error,
        primaryLabel: 'Sign in to Plex',
        primaryAction: controller.beginSignIn,
        secondaryLabel: controller.api?.session == null ? null : 'Retry server',
        secondaryAction:
            controller.api?.session == null ? null : controller.refreshContent,
      );
}

class CenteredPanel extends StatelessWidget {
  const CenteredPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.error,
    required this.primaryLabel,
    required this.primaryAction,
    this.secondaryLabel,
    this.secondaryAction,
    super.key,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? error;
  final String primaryLabel;
  final FutureOr<void> Function() primaryAction;
  final String? secondaryLabel;
  final FutureOr<void> Function()? secondaryAction;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
              margin: const EdgeInsets.all(28),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 38, vertical: 26),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Icon(icon, size: 60, color: const Color(0xFFE5A00D)),
                  const SizedBox(height: 10),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, height: 1.35)),
                  if (error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFFF8A80), fontSize: 16)),
                  ],
                  const SizedBox(height: 20),
                  Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    ElevatedButton(
                        onPressed: primaryAction,
                        child: Text(primaryLabel,
                            style: const TextStyle(fontSize: 18))),
                    if (secondaryAction != null) ...<Widget>[
                      const SizedBox(width: 14),
                      OutlinedButton(
                          onPressed: secondaryAction,
                          child: Text(secondaryLabel!,
                              style: const TextStyle(fontSize: 18))),
                    ],
                  ]),
                ]),
              )),
        ))),
      );
}

class PinScreen extends StatelessWidget {
  const PinScreen({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) {
    final pin = controller.pin!;
    return Scaffold(body: SafeArea(child: LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 1000 || constraints.maxHeight < 600;
        final qrSize = compact ? 220.0 : 285.0;
        final inset = compact ? 22.0 : 34.0;
        return Row(children: <Widget>[
          Expanded(
              child: Padding(
            padding: EdgeInsets.all(inset),
            child: Center(
                child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Sign in to Plex',
                        style: TextStyle(
                            fontSize: compact ? 28 : 32,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(
                        'Scan with your phone, approve Plezy GKUI, and leave this screen open.',
                        style: TextStyle(
                            fontSize: compact ? 17 : 20, height: 1.3)),
                    const SizedBox(height: 12),
                    Text('Code: ${pin.code}',
                        style: TextStyle(
                            fontSize: compact ? 23 : 27,
                            color: const Color(0xFFE5A00D),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    const Row(children: <Widget>[
                      SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(strokeWidth: 3)),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text('Waiting for approval…',
                              style: TextStyle(fontSize: 17))),
                    ]),
                    const SizedBox(height: 14),
                    OutlinedButton(
                        onPressed: controller.cancelSignIn,
                        child: const Text('Cancel',
                            style: TextStyle(fontSize: 17))),
                  ]),
            )),
          )),
          Container(
            color: Colors.white,
            margin: EdgeInsets.all(compact ? 16 : 24),
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: QrImageView(
                data: pin.authUrl(controller.api!.clientIdentifier),
                size: qrSize),
          ),
        ]);
      },
    )));
  }
}

class ServerScreen extends StatelessWidget {
  const ServerScreen({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Choose a Plex server')),
        body: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: controller.servers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final server = controller.servers[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              tileColor: const Color(0xFF1D1D1D),
              leading: const Icon(Icons.dns, size: 38),
              title: Text(server.name, style: const TextStyle(fontSize: 22)),
              subtitle: Text('${server.connections.length} secure route(s)'),
              trailing: const Icon(Icons.chevron_right, size: 36),
              onTap: () => controller.chooseServer(server),
            );
          },
        ),
      );
}

class GkuiShell extends StatefulWidget {
  const GkuiShell({required this.controller, super.key});
  final GkuiController controller;
  @override
  State<GkuiShell> createState() => _GkuiShellState();
}

class _GkuiShellState extends State<GkuiShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePane(controller: widget.controller),
      LibraryPane(controller: widget.controller),
      DiagnosticsPane(
          logs: widget.controller.logs, controller: widget.controller),
    ];
    return Scaffold(
        body: SafeArea(
            child: Row(children: <Widget>[
      Container(
          width: 104,
          color: const Color(0xFF121212),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            selectedIndex: selected,
            labelType: NavigationRailLabelType.all,
            minWidth: 100,
            onDestinationSelected: (value) => setState(() => selected = value),
            leading: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Image.asset('assets/plezy.png', width: 45, height: 45)),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                  icon: Icon(Icons.home_outlined, size: 29),
                  selectedIcon: Icon(Icons.home, size: 31),
                  label: Text('Home')),
              NavigationRailDestination(
                  icon: Icon(Icons.video_library_outlined, size: 29),
                  selectedIcon: Icon(Icons.video_library, size: 31),
                  label: Text('Library')),
              NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined, size: 29),
                  selectedIcon: Icon(Icons.monitor_heart, size: 31),
                  label: Text('Status')),
            ],
          )),
      const VerticalDivider(width: 1),
      Expanded(child: pages[selected]),
    ])));
  }
}

class HomePane extends StatelessWidget {
  const HomePane({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) {
    if (controller.loadingContent && controller.shelves.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: controller.refreshContent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
        children: <Widget>[
          PageHeading(
              title: controller.api!.session!.serverName,
              subtitle: 'Secure Plex connection • pull down to refresh'),
          if (controller.error != null) ErrorBanner(controller.error!),
          const SizedBox(height: 18),
          if (controller.shelves.isEmpty)
            const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                    child: Text('No home items returned by this server.',
                        style: TextStyle(fontSize: 19))))
          else
            for (final shelf in controller.shelves) ...<Widget>[
              MediaShelf(shelf: shelf, controller: controller),
              const SizedBox(height: 24),
            ],
        ],
      ),
    );
  }
}

class LibraryPane extends StatelessWidget {
  const LibraryPane({required this.controller, super.key});
  final GkuiController controller;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
            child: PageHeading(
                title: 'Library',
                subtitle: controller.selectedSection?.title ??
                    'No Plex libraries found')),
        SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: controller.sections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final section = controller.sections[index];
                return ChoiceChip(
                  label:
                      Text(section.title, style: const TextStyle(fontSize: 17)),
                  selected: section.key == controller.selectedSection?.key,
                  onSelected: (_) => controller.selectSection(section),
                );
              },
            )),
        if (controller.error != null) ErrorBanner(controller.error!),
        Expanded(
            child: controller.loadingContent
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 170,
                      childAspectRatio: 0.66,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: controller.libraryItems.length,
                    itemBuilder: (context, index) => MediaCard(
                        media: controller.libraryItems[index],
                        controller: controller),
                  )),
      ]);
}

class MediaShelf extends StatelessWidget {
  const MediaShelf({required this.shelf, required this.controller, super.key});
  final PlexShelf shelf;
  final GkuiController controller;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(shelf.title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
            height: 222,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shelf.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) => SizedBox(
                  width: 128,
                  child: MediaCard(
                      media: shelf.items[index], controller: controller)),
            )),
      ]);
}

class MediaCard extends StatelessWidget {
  const MediaCard({required this.media, required this.controller, super.key});
  final PlexMedia media;
  final GkuiController controller;
  @override
  Widget build(BuildContext context) {
    final image = controller.api!.imageUrl(media.thumb);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DetailsScreen(media: media, controller: controller))),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Container(
                color: const Color(0xFF272727),
                width: double.infinity,
                child: image == null
                    ? const Icon(Icons.movie_outlined,
                        size: 48, color: Colors.white38)
                    : CachedNetworkImage(
                        imageUrl: image,
                        httpHeaders: controller.api!.imageHeaders,
                        fit: BoxFit.cover,
                        memCacheWidth: 260,
                        maxWidthDiskCache: 320,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.broken_image_outlined,
                            size: 44,
                            color: Colors.white38),
                      ),
              ),
            )),
            const SizedBox(height: 6),
            Text(media.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15)),
            if (media.viewOffsetMs > 0 && media.durationMs > 0)
              LinearProgressIndicator(
                  value:
                      (media.viewOffsetMs / media.durationMs).clamp(0.0, 1.0),
                  minHeight: 3),
          ]),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen(
      {required this.media, required this.controller, super.key});
  final PlexMedia media;
  final GkuiController controller;
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Future<List<PlexMedia>>? children;
  @override
  void initState() {
    super.initState();
    children = widget.media.children
        ? widget.controller.api!.loadChildren(widget.media)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final image = widget.controller.api!
        .imageUrl(media.art ?? media.thumb, width: 900, height: 500);
    return Scaffold(
      appBar: AppBar(title: Text(media.title)),
      body: Stack(fit: StackFit.expand, children: <Widget>[
        if (image != null)
          Opacity(
              opacity: 0.18,
              child: CachedNetworkImage(
                imageUrl: image,
                httpHeaders: widget.controller.api!.imageHeaders,
                fit: BoxFit.cover,
                memCacheWidth: 900,
              )),
        Container(color: Colors.black.withOpacity(0.38)),
        Padding(
            padding: const EdgeInsets.all(26),
            child: children == null
                ? playableDetails(media)
                : childrenList(media)),
      ]),
    );
  }

  Widget playableDetails(PlexMedia media) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        SizedBox(
            width: 210,
            child: MediaCard(media: media, controller: widget.controller)),
        const SizedBox(width: 28),
        Expanded(
            child: ListView(children: <Widget>[
          Text(media.title,
              style:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
              <String>[
                if (media.year != null) '${media.year}',
                if (media.subtitle != null) media.subtitle!
              ].join(' • '),
              style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 14),
          Text(media.summary ?? 'No summary available.',
              style: const TextStyle(fontSize: 17, height: 1.4)),
          const SizedBox(height: 22),
          Wrap(spacing: 12, runSpacing: 12, children: <Widget>[
            ElevatedButton.icon(
              onPressed: () =>
                  widget.controller.play(context, media, PlaybackMode.direct),
              icon: const Icon(Icons.play_arrow),
              label: Text(
                  media.viewOffsetMs > 0 ? 'Resume direct' : 'Play direct'),
            ),
            OutlinedButton(
              onPressed: () => widget.controller
                  .play(context, media, PlaybackMode.transcode720),
              child: const Text('720p compatible'),
            ),
            OutlinedButton(
              onPressed: () => widget.controller
                  .play(context, media, PlaybackMode.transcode480),
              child: const Text('480p safe mode'),
            ),
          ]),
        ])),
      ]);

  Widget childrenList(PlexMedia media) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(media.title,
            style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w700)),
        if (media.summary != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(media.summary!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16)),
          ),
        Expanded(
            child: FutureBuilder<List<PlexMedia>>(
          future: children,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError)
              return Center(
                  child: Text('Could not load items: ${snapshot.error}'));
            final items = snapshot.data ?? const <PlexMedia>[];
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 175,
                childAspectRatio: 0.68,
                crossAxisSpacing: 16,
                mainAxisSpacing: 18,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  MediaCard(media: items[index], controller: widget.controller),
            );
          },
        )),
      ]);
}

class PageHeading extends StatelessWidget {
  const PageHeading({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.white70)),
      ]);
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF5A2020),
        child: Text(message),
      );
}

class DiagnosticsPane extends StatefulWidget {
  const DiagnosticsPane(
      {required this.logs, required this.controller, super.key});
  final RedactingLogStore logs;
  final GkuiController controller;
  @override
  State<DiagnosticsPane> createState() => _DiagnosticsPaneState();
}

class _DiagnosticsPaneState extends State<DiagnosticsPane> {
  late Future<DeviceDiagnostics> diagnostics = DeviceDiagnostics.load();

  Future<void> copyDiagnostics() async {
    final snapshot = await diagnostics;
    final details = snapshot.values.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
    await Clipboard.setData(ClipboardData(
        text:
            '$buildLabel\n$sourceLabel\n$toolchainLabel\n$details\n\n${widget.logs.exportText()}'));
    widget.logs.add('Diagnostics copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(children: <Widget>[
                const Expanded(
                    child: PageHeading(
                        title: 'Device status',
                        subtitle: 'Plex, player, memory and redacted logs')),
                ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => diagnostics = DeviceDiagnostics.load()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                    onPressed: copyDiagnostics,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy')),
                const SizedBox(width: 8),
                OutlinedButton(
                    onPressed: widget.controller.signOut,
                    child: const Text('Sign out')),
              ]),
              const SizedBox(height: 12),
              Expanded(
                  child: Row(children: <Widget>[
                Expanded(
                    child: Card(
                        child: FutureBuilder<DeviceDiagnostics>(
                  future: diagnostics,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final rows = <MapEntry<String, String>>[
                      const MapEntry<String, String>('build', buildLabel),
                      const MapEntry<String, String>('source', sourceLabel),
                      const MapEntry<String, String>(
                          'toolchain', toolchainLabel),
                      MapEntry<String, String>(
                          'server',
                          widget.controller.api?.session?.serverName ??
                              'not connected'),
                      ...snapshot.data!.values.entries,
                    ];
                    return ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (_, index) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(
                                width: 125,
                                child: Text(rows[index].key,
                                    style: const TextStyle(
                                        color: Colors.white60))),
                            Expanded(
                                child: SelectableText(rows[index].value,
                                    style: const TextStyle(fontSize: 15))),
                          ]),
                    );
                  },
                ))),
                const SizedBox(width: 14),
                Expanded(
                    child: Card(
                        child: AnimatedBuilder(
                  animation: widget.logs,
                  builder: (_, __) => ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: widget.logs.entries.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SelectableText(widget.logs.entries[index].line,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.white70)),
                    ),
                  ),
                ))),
              ])),
            ]),
      );
}
