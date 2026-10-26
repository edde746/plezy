import 'dart:io';

import 'package:flutter/material.dart';

import '../../discovery/discovery_choice.dart';
import '../../focus/focusable_button.dart';
import '../../i18n/strings.g.dart';
import '../../media/media_server_client.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/media_image_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/optimized_media_image.dart';

/// Keep fallbacks bounded and in the same authorized title/server context.
/// Empty strings are common in provider metadata and must not block a fallback.
List<String> discoveryArtworkPaths(DiscoveryChoice choice, {bool backdrop = false}) => <String>{
  for (final path in [
    if (backdrop) choice.mediaItem?.artPath,
    if (backdrop) choice.catalogItem?.backdropFor(1920),
    choice.artworkPath,
    choice.mediaItem?.posterThumbFallback(mixedHubContext: true),
    choice.mediaItem?.thumbPath,
    choice.mediaItem?.parentThumbPath,
    choice.mediaItem?.grandparentThumbPath,
    choice.mediaItem?.artPath,
    choice.catalogItem?.backdropFor(640),
    choice.liveChannel?.thumb,
    choice.liveChannel?.art,
  ])
    if (path != null && path.trim().isNotEmpty) path.trim(),
}.toList();

class DiscoveryArtwork extends StatefulWidget {
  const DiscoveryArtwork({
    super.key,
    required this.paths,
    required this.icon,
    required this.imageType,
    required this.fit,
    this.decorative = false,
    this.onRetry,
    this.client,
    this.localPathFor,
    this.loadCover,
  });

  final VoidCallback? onRetry;
  final bool decorative;
  final List<String> paths;
  final IconData icon;
  final ImageType imageType;
  final BoxFit fit;
  final MediaServerClient? client;
  final String? Function(String path)? localPathFor;
  final Future<File?> Function(bool refresh)? loadCover;

  @override
  State<DiscoveryArtwork> createState() => _DiscoveryArtworkState();
}

class _DiscoveryArtworkState extends State<DiscoveryArtwork> {
  Future<File?>? _cover;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _cover = widget.loadCover?.call(false);
  }

  void _retry() {
    setState(() {
      _attempt++;
      _cover = widget.loadCover?.call(true);
    });
    widget.onRetry?.call();
  }

  Widget _status({required bool loading}) {
    if (widget.decorative) return const SizedBox.expand();
    final canRetry = widget.paths.isNotEmpty || widget.loadCover != null;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < MediaQuery.textScalerOf(context).scale(16) * 3 + 120;
        if (compact) {
          return Center(
            child: loading || !canRetry
                ? Text(
                    loading ? t.discover.findNext.artworkLoading : t.discover.findNext.artworkUnavailable,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Tooltip(
                    message: t.discover.findNext.artworkUnavailable,
                    child: FocusableButton(
                      onPressed: _retry,
                      child: TextButton(
                        onPressed: _retry,
                        child: Text(t.common.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(widget.icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text(
                  loading ? t.discover.findNext.artworkLoading : t.discover.findNext.artworkUnavailable,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                if (!loading && canRetry)
                  FocusableButton(
                    onPressed: _retry,
                    child: TextButton(onPressed: _retry, child: Text(t.common.retry)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageAt(int index, {bool localOnly = false}) {
    if (index >= widget.paths.length) return localOnly ? _imageAt(0) : _status(loading: false);
    final path = widget.paths[index];
    final local = widget.localPathFor?.call(path);
    if (localOnly && local == null) return _imageAt(index + 1, localOnly: true);
    return OptimizedMediaImage(
      key: ValueKey('$_attempt:$localOnly:$index:$path'),
      client: localOnly ? null : widget.client,
      imagePath: localOnly ? null : path,
      localFilePath: localOnly ? local : null,
      fit: widget.fit,
      imageType: widget.imageType,
      placeholder: (_, _) => _status(loading: true),
      errorWidget: (_, _, _) => _imageAt(index + 1, localOnly: localOnly),
      fadeInDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.decorative ? 0 : tokens(context).radiusLg),
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: _cover == null
          ? _imageAt(0, localOnly: widget.localPathFor != null)
          : FutureBuilder<File?>(
              key: ValueKey(_attempt),
              future: _cover,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return _status(loading: true);
                final file = snapshot.data;
                if (file == null) return _imageAt(0);
                return OptimizedMediaImage(
                  imagePath: null,
                  localFilePath: file.path,
                  fit: widget.fit,
                  imageType: widget.imageType,
                  placeholder: (_, _) => _status(loading: true),
                  errorWidget: (_, _, _) => _imageAt(0),
                );
              },
            ),
    ),
  );
}
