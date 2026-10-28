import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../services/remote_streams/real_debrid_client.dart';
import '../../services/remote_streams/remote_stream_models.dart';
import '../../services/remote_streams/remote_streaming_provider.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../sources/source_transport.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'remote_cloud_files_screen.dart';
import '../settings/remote_streaming_settings_screen.dart';
import '../sources/source_player_screen.dart';
import '../sources/sources_screen.dart';

class RemoteStreamPickerScreen extends StatefulWidget {
  const RemoteStreamPickerScreen({
    super.key,
    required this.request,
    required this.identifiers,
    this.durationMs,
  });

  final RemoteStreamRequest request;
  final Map<String, String> identifiers;
  final int? durationMs;

  @override
  State<RemoteStreamPickerScreen> createState() => _RemoteStreamPickerScreenState();
}

class _RemoteStreamPickerScreenState extends State<RemoteStreamPickerScreen> {
  RemoteStreamSearchResult? _result;
  bool _loading = true;
  bool _error = false;
  String? _loadedProfileId;
  bool _profileReloadQueued = false;
  String? _busyCandidate;
  final Map<String, RemoteSubtitle> _selectedSubtitles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });
    final provider = context.read<RemoteStreamingProvider>();
    final profileId = provider.profileId;
    try {
      final result = await provider.streamsFor(widget.request);
      if (!mounted) return;
      if (provider.profileId != profileId) {
        setState(() => _loading = false);
        return;
      }
      setState(() {
        _loadedProfileId = profileId;
        _result = result;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = provider.profileId == profileId;
      });
    }
  }

  Future<void> _play(RemoteStreamCandidate candidate, {bool viaProvider = false}) async {
    if (_busyCandidate != null) return;
    final streaming = context.read<RemoteStreamingProvider>();
    final startingProfile = streaming.profileId;
    if (startingProfile == null || !streaming.isReady) return;
    final accounts = viaProvider
        ? streaming.accounts.where((account) => account.service != RemoteStreamService.torbox).toList()
        : streaming.accounts;
    final needsProvider = viaProvider || candidate.url == null && candidate.infoHash != null;
    final service = !needsProvider
        ? null
        : accounts.length == 1
        ? accounts.single.service
        : accounts.isEmpty
        ? null
        : await _chooseProvider(accounts);
    if (needsProvider && service == null) {
      if (mounted) showAppSnackBar(context, t.streaming.streamNeedsProvider);
      return;
    }
    if (!mounted || streaming.profileId != startingProfile || !streaming.isReady) return;
    setState(() => _busyCandidate = candidate.addonId + candidate.label);
    try {
      Uri? uri = candidate.url;
      Map<String, String> headers = candidate.headers;
      String fileName = _fileNameFor(candidate);
      int? size;
      if (viaProvider && candidate.url != null) {
        final resolved = await streaming.resolveHosterLink(candidate.url!, service: service!);
        uri = resolved.uri;
        fileName = resolved.fileName;
        size = resolved.size;
        headers = const {};
      } else if (candidate.url == null && candidate.infoHash != null) {
        final resolved = await streaming.resolveTorrent(candidate, service: service);
        uri = resolved.uri;
        fileName = resolved.fileName;
        size = resolved.size;
        headers = const {};
      }
      if (streaming.profileId != startingProfile || !streaming.isReady) return;
      if (uri == null || !const {'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
        throw const RealDebridException(RealDebridFailure.unsupported);
      }
      if (!mounted) return;
      await _openPlayer(candidate, uri, headers, fileName, size, _selectedSubtitles[_candidateKey(candidate)]);
    } on RemoteProviderException catch (error) {
      if (mounted && error.reason != RemoteProviderFailure.cancelled) {
        showAppSnackBar(
          context,
          error.reason == RemoteProviderFailure.authentication
              ? t.streaming.streamNeedsProvider
              : t.streaming.streamPrepareFailed,
        );
      }
    } on RealDebridException catch (error) {
      if (mounted && error.reason != RealDebridFailure.cancelled) {
        showAppSnackBar(
          context,
          error.reason == RealDebridFailure.authentication
              ? t.streaming.streamNeedsProvider
              : t.streaming.streamPrepareFailed,
        );
      }
    } on SourceException catch (error) {
      if (mounted && error.reason != SourceFailure.cancelled) showAppSnackBar(context, t.streaming.streamUnsupported);
    } on Object {
      if (mounted) showAppSnackBar(context, t.streaming.streamPrepareFailed);
    } finally {
      if (mounted) setState(() => _busyCandidate = null);
    }
  }

  Future<RemoteStreamService?> _chooseProvider(List<RemoteStreamAccount> accounts) => showModalBottomSheet<RemoteStreamService>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: Text(t.streaming.chooseProvider), enabled: false),
          for (final account in accounts)
            ListTile(
              leading: const AppIcon(Symbols.cloud_rounded),
              title: Text(_serviceName(account.service)),
              subtitle: Text(t.streaming.accountConnected(username: account.displayName)),
              onTap: () => Navigator.pop(context, account.service),
            ),
        ],
      ),
    ),
  );

  Future<void> _browseCloudFiles() async {
    final streaming = context.read<RemoteStreamingProvider>();
    final profileId = streaming.profileId;
    if (!streaming.isReady || profileId == null || streaming.accounts.isEmpty) return;
    final accounts = streaming.accounts;
    final service = accounts.length == 1 ? accounts.single.service : await _chooseProvider(accounts);
    if (!mounted || service == null || streaming.profileId != profileId || !streaming.isReady) return;
    final account = streaming.accountFor(service);
    if (account == null) return;
    final sourceController = context.read<SourceController>();
    final fileSource = sourceController.sources
        .where(
          (source) =>
              source.kind == FileSourceKind.remoteCloud &&
              source.options['accountId'] == account.id &&
              sourceController.profileId == profileId,
        )
        .firstOrNull;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => fileSource == null
            ? RemoteCloudFilesScreen(
                service: service,
                onManageConnections: _manageRemoteStreaming,
                expectedAccountId: account.id,
                expectedProfileId: profileId,
              )
            : SourcesScreen(
                source: fileSource,
                title: Text('${_serviceName(service)} · ${account.displayName}'),
              ),
      ),
    );
  }

  Future<void> _manageRemoteStreaming() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RemoteStreamingSettingsScreen()),
    );
  }

  String _serviceName(RemoteStreamService service) => switch (service) {
    RemoteStreamService.realDebrid => t.streaming.realDebrid,
    RemoteStreamService.allDebrid => t.streaming.allDebrid,
    RemoteStreamService.premiumize => t.streaming.premiumize,
    RemoteStreamService.torbox => t.streaming.torbox,
  };

  Future<void> _openPlayer(
    RemoteStreamCandidate candidate,
    Uri uri,
    Map<String, String> headers,
    String fileName,
    int? size,
    RemoteSubtitle? subtitle,
  ) async {
    final profile = context.read<SourceController>().profileId;
    if (profile == null || context.read<RemoteStreamingProvider>().profileId != profile) {
      throw const SourceException(SourceFailure.cancelled);
    }
    final fileId = sourceDigest(
      '${candidate.addonId}\u0000${widget.request.id}\u0000${candidate.label}\u0000${candidate.infoHash ?? ''}'
      '\u0000${candidate.fileIndex ?? ''}\u0000${candidate.url == null ? '' : sourceDigest(candidate.url.toString())}'
      '\u0000${candidate.externalUrl == null ? '' : sourceDigest(candidate.externalUrl.toString())}',
    );
    final file = PublicationFile(
      id: fileId,
      name: fileName,
      mimeType: _mimeType(fileName),
      size: size,
      durationMs: widget.durationMs,
      streamOnly: true,
    );
    final entry = SourceEntry(
      sourceId: 'stremio:${candidate.addonId}',
      id: widget.request.id,
      title: widget.request.title,
      kind: SourceItemKind.video,
      files: [file],
      identifiers: widget.identifiers,
      releaseYear: widget.request.year,
      onlineTitle: widget.request.title,
    );
    await context.read<SourcePlayback>().start(
      entry,
      [file],
      playbackMode: PublicationMode.watching,
      localOverrides: {file.id: uri},
      localOverrideHeaders: {file.id: headers},
      persistProgress: true,
    );
    if (!mounted ||
        context.read<SourceController>().profileId != profile ||
        context.read<RemoteStreamingProvider>().profileId != profile) {
      return;
    }
    if (subtitle != null) {
      try {
        final bytes = await _downloadSubtitle(subtitle);
        if (!mounted ||
            context.read<SourceController>().profileId != profile ||
            context.read<RemoteStreamingProvider>().profileId != profile) {
          return;
        }
        await context.read<SourcePlayback>().applyExternalSubtitle(name: _subtitleFileName(subtitle), bytes: bytes);
      } on Object {
        if (mounted) showAppSnackBar(context, t.streaming.subtitleLoadFailed);
      }
    }
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'remote-stream-player'),
        builder: (_) => const SourcePlayerScreen(),
      ),
    );
  }

  Future<void> _chooseSubtitle(RemoteStreamCandidate candidate) async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(t.streaming.chooseSubtitle), enabled: false),
            ListTile(
              leading: const AppIcon(Symbols.subtitles_off_rounded),
              title: Text(t.streaming.subtitleOff),
              onTap: () => Navigator.pop(context, -1),
            ),
            for (var index = 0; index < candidate.subtitles.length; index++)
              ListTile(
                leading: const AppIcon(Symbols.subtitles_rounded),
                title: Text(_subtitleLabel(candidate.subtitles[index])),
                onTap: () => Navigator.pop(context, index),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      if (choice < 0 || choice >= candidate.subtitles.length) {
        _selectedSubtitles.remove(_candidateKey(candidate));
      } else {
        _selectedSubtitles[_candidateKey(candidate)] = candidate.subtitles[choice];
      }
    });
  }

  Future<List<int>> _downloadSubtitle(RemoteSubtitle subtitle) async {
    final transport = SourceTransport(allowHttp: subtitle.url.scheme == 'http');
    try {
      final response = await transport.send('GET', subtitle.url, redirects: true);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.stream.drain<void>().timeout(const Duration(seconds: 20));
        SourceTransport.check(response.statusCode);
      }
      final declaredLength = int.tryParse(response.headers['content-length'] ?? '');
      if (declaredLength != null && declaredLength > 5 * 1024 * 1024) {
        await response.stream.drain<void>().timeout(const Duration(seconds: 20));
        throw const SourceException(SourceFailure.invalidData);
      }
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(const Duration(seconds: 20))) {
        if (bytes.length + chunk.length > 5 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
        bytes.addAll(chunk);
      }
      if (bytes.isEmpty) throw const SourceException(SourceFailure.invalidData);
      return bytes;
    } finally {
      transport.close();
    }
  }

  String _candidateKey(RemoteStreamCandidate candidate) =>
      '${candidate.addonId}\u0000${candidate.label}\u0000${candidate.infoHash ?? ''}'
      '\u0000${candidate.url == null ? candidate.fileIndex ?? '' : sourceDigest(candidate.url.toString())}'
      '\u0000${candidate.externalUrl == null ? '' : sourceDigest(candidate.externalUrl.toString())}';

  String _subtitleLabel(RemoteSubtitle subtitle) =>
      subtitle.label?.trim().isNotEmpty == true ? subtitle.label! : subtitle.lang?.trim().isNotEmpty == true
      ? subtitle.lang!
      : t.streaming.subtitleTracks(count: 1);

  String _subtitleFileName(RemoteSubtitle subtitle) {
    final segment = subtitle.url.pathSegments.isEmpty ? '' : subtitle.url.pathSegments.last;
    final name = Uri.decodeComponent(segment);
    return name.toLowerCase().endsWith('.srt') ||
            name.toLowerCase().endsWith('.ass') ||
            name.toLowerCase().endsWith('.ssa') ||
            name.toLowerCase().endsWith('.vtt') ||
            name.toLowerCase().endsWith('.sub')
        ? name
        : '${_subtitleLabel(subtitle)}.srt';
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      if (mounted) showAppSnackBar(context, t.streaming.streamUnsupported);
    }
  }

  Future<void> _openStreamingSettings() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RemoteStreamingSettingsScreen()));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final streaming = context.watch<RemoteStreamingProvider>();
    final result = _result;
    final staleProfile = streaming.profileId != _loadedProfileId;
    if (staleProfile && !_loading && !_profileReloadQueued) {
      _profileReloadQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _profileReloadQueued = false;
        _selectedSubtitles.clear();
        _load();
      });
    }
    final hasDebrid = streaming.accounts.isNotEmpty;
    final hasHosterResolver = streaming.accounts.any((account) => account.service != RemoteStreamService.torbox);
    return FocusedScrollScaffold(
      title: Text(t.streaming.streamsTitle),
      slivers: [
        if (_loading || staleProfile)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error || result == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.streaming.streamLookupFailed, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const AppIcon(Symbols.refresh_rounded),
                    label: Text(t.common.retry),
                  ),
                  TextButton.icon(
                    onPressed: _openStreamingSettings,
                    icon: const AppIcon(Symbols.settings_rounded),
                    label: Text(t.streaming.manageConnections),
                  ),
                  if (streaming.accounts.isNotEmpty)
                    TextButton.icon(
                      onPressed: _browseCloudFiles,
                      icon: const AppIcon(Symbols.folder_open_rounded),
                      label: Text(t.streaming.browseCloud),
                    ),
                ],
              ),
            ),
          )
        else if (result.candidates.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(Symbols.search_off_rounded, size: 40),
                    const SizedBox(height: 16),
                    Text(t.streaming.noStreams, textAlign: TextAlign.center),
                    if (result.failedAddons > 0) ...[
                      const SizedBox(height: 8),
                      Text(t.streaming.streamLookupPartial, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _openStreamingSettings,
                      icon: const AppIcon(Symbols.settings_rounded),
                      label: Text(t.streaming.manageConnections),
                    ),
                    if (hasDebrid)
                      TextButton.icon(
                        onPressed: _browseCloudFiles,
                        icon: const AppIcon(Symbols.folder_open_rounded),
                        label: Text(t.streaming.browseCloud),
                      ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildListDelegate([
              if (result.failedAddons > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(t.streaming.streamLookupPartial, style: Theme.of(context).textTheme.bodySmall),
                ),
              for (final candidate in result.candidates) _candidateTile(candidate, hasDebrid, hasHosterResolver),
              const SizedBox(height: 24),
            ]),
          ),
      ],
    );
  }

  Widget _candidateTile(RemoteStreamCandidate candidate, bool hasDebrid, bool hasHosterResolver) {
    final busy = _busyCandidate == '${candidate.addonId}${candidate.label}';
    final selectedSubtitle = _selectedSubtitles[_candidateKey(candidate)];
    final canPlay = candidate.url != null || candidate.infoHash != null && hasDebrid;
    final subtitle = [
      candidate.addonName,
      if (candidate.description?.isNotEmpty == true) candidate.description!,
      if (candidate.infoHash != null && !hasDebrid) t.streaming.streamNeedsProvider,
      if (candidate.subtitles.isNotEmpty) t.streaming.subtitleTracks(count: candidate.subtitles.length),
      if (selectedSubtitle != null) _subtitleLabel(selectedSubtitle),
    ].join(' · ');
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (candidate.subtitles.isNotEmpty)
          IconButton(
            tooltip: t.streaming.chooseSubtitle,
            onPressed: busy ? null : () => _chooseSubtitle(candidate),
            icon: const AppIcon(Symbols.subtitles_rounded),
          ),
        if (candidate.url != null && candidate.url!.scheme == 'https' && hasHosterResolver && !busy)
          IconButton(
            tooltip: t.streaming.playViaProvider,
            onPressed: () => _play(candidate, viaProvider: true),
            icon: const AppIcon(Symbols.cloud_download_rounded),
          ),
        if (busy)
          const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
        else if (candidate.externalUrl != null && candidate.url == null && candidate.infoHash == null)
          TextButton(onPressed: () => _openExternal(candidate.externalUrl!), child: Text(t.streaming.streamOpenExternal))
        else if (!canPlay && candidate.infoHash != null && !hasDebrid)
          TextButton(onPressed: _openStreamingSettings, child: Text(t.streaming.manageConnections))
        else if (canPlay)
          const AppIcon(Symbols.chevron_right_rounded),
      ],
    );
    return FocusableListTile(
      leading: AppIcon(
        candidate.externalUrl != null && candidate.url == null && candidate.infoHash == null
            ? Symbols.open_in_new_rounded
            : candidate.infoHash != null
            ? Symbols.cloud_download_rounded
            : Symbols.play_circle_rounded,
        fill: 1,
      ),
      title: Text(candidate.label),
      subtitle: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
      trailing: trailing,
      onTap: busy
          ? null
          : candidate.externalUrl != null && candidate.url == null && candidate.infoHash == null
          ? () => _openExternal(candidate.externalUrl!)
          : canPlay
          ? () => _play(candidate)
          : !canPlay && candidate.infoHash != null && !hasDebrid
          ? _openStreamingSettings
          : null,
    );
  }

  String _fileNameFor(RemoteStreamCandidate candidate) {
    final uri = candidate.url;
    final name = uri == null || uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final decoded = Uri.decodeComponent(name);
    final safeName = decoded.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '').trim();
    if (safeName.contains('.') && safeName.length <= 240) return safeName;
    final label = candidate.label.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '').trim();
    return '${label.isEmpty ? widget.request.title : label}.mp4';
  }

  String _mimeType(String name) => switch (name.toLowerCase().split('.').last) {
    'mkv' => 'video/x-matroska',
    'm4v' => 'video/x-m4v',
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    'avi' => 'video/x-msvideo',
    'ts' => 'video/mp2t',
    _ => 'video/mp4',
  };
}
