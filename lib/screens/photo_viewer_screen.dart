import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../utils/app_logger.dart';
import '../utils/formatters.dart';
import '../utils/immersive_mode_guard.dart';
import '../utils/media_image_helper.dart';
import '../utils/orientation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../widgets/app_bar_back_button.dart';

/// Shows one photo full-screen, sized to the screen, with pinch and scroll zoom.
class PhotoViewerScreen extends StatefulWidget {
  final MediaItem photo;

  const PhotoViewerScreen({super.key, required this.photo});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  /// Longest edge requested. The decoded bitmap stays within this square,
  /// which keeps a large original from exhausting a low-RAM TV.
  static const int _maxImageEdge = 3840;
  static const double _maxZoom = 5;

  /// Where focus starts, so that Enter on opening does not press Back.
  final FocusNode _photoFocusNode = FocusNode(debugLabel: 'photo_viewer_photo');
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'photo_viewer_back');

  /// Fixed at open, sized to the monitor rather than the window, and a square,
  /// so turning the phone or resizing or maximising the window does not
  /// refetch the image.
  int? _imageEdge;
  bool _immersive = false;

  /// Images this viewer put in the artwork cache, by URL. Each one is the size
  /// of the screen, so their decoded bitmaps leave the memory cache when the
  /// viewer closes. Their files stay in the disk cache, so reopening the photo
  /// does not download it again.
  final Map<String, ImageProvider> _screenImages = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _photoFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _imageEdge ??= math.min(_screenEdge(), _maxImageEdge);
    if (!_immersive && PlatformDetector.isMobile(context)) {
      _immersive = true;
      ImmersiveModeGuard.acquire(this);
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
    }
  }

  @override
  void dispose() {
    if (_immersive) {
      // Before the overlays are shown: the re-show callback that follows must
      // find no owner, or it would hide them again.
      ImmersiveModeGuard.release(this);
      unawaited(
        OrientationHelper.restoreSystemUI().catchError((Object e) {
          appLogger.w('Failed to restore system UI', error: e);
        }),
      );
    }
    for (final image in _screenImages.values) {
      unawaited(image.evict());
    }
    _photoFocusNode.dispose();
    _backFocusNode.dispose();
    super.dispose();
  }

  /// Longest edge of the monitor in physical pixels. The window's own edge
  /// stands in when it is larger, or when the platform reports no display size.
  int _screenEdge() {
    final windowEdge = MediaQuery.sizeOf(context).longestSide * MediaQuery.devicePixelRatioOf(context);
    double displayEdge = 0;
    try {
      displayEdge = View.of(context).display.size.longestSide;
    } catch (_) {
      // No display information on this platform.
    }
    return math.max(windowEdge, displayEdge).ceil();
  }

  /// The photo's own title, or its album's when it has none.
  String get _title {
    final title = widget.photo.title;
    if (title != null && title.isNotEmpty) return title;
    return widget.photo.parentTitle ?? '';
  }

  /// When the photo was taken, as the server reports it. Shown only: imports
  /// such as Google Takeout can carry the import date instead.
  String? get _dateLabel {
    final date = widget.photo.originallyAvailableAt;
    return date == null || date.isEmpty ? null : formatFullDate(date);
  }

  /// Up and Down move between the photo and the back button. Left and Right do
  /// nothing yet, and are consumed so they cannot wander off to the back button.
  KeyEventResult _handleKeyEvent(KeyEvent event) {
    final key = event.logicalKey;
    if (!key.isDpadDirection) return handleBackKeyNavigation(context, event);
    if (event.isActionable) {
      if (key == LogicalKeyboardKey.arrowUp) _backFocusNode.requestFocus();
      if (key == LogicalKeyboardKey.arrowDown) _photoFocusNode.requestFocus();
    }
    return KeyEventResult.handled;
  }

  Widget _buildHeaderText(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateLabel = _dateLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        if (dateLabel != null)
          Text(
            dateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          t.errors.unableToLoad(context: _title),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  /// [path] drawn to fit the screen, or whatever [onFailed] builds when it
  /// cannot be loaded.
  Widget _buildImage(MediaServerClient client, String? path, {required Widget Function() onFailed}) {
    final edge = _imageEdge!;
    final url = client.thumbnailUrl(path, width: edge, height: edge, cover: false);
    if (url.isEmpty) return onFailed();
    return Image(
      image: _screenImages.putIfAbsent(
        url,
        () => MediaImageHelper.serverArtworkProvider(imageUrl: url, memWidth: edge, memHeight: edge),
      ),
      fit: BoxFit.contain,
      semanticLabel: _title,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => onFailed(),
    );
  }

  Widget _buildPhoto() {
    final client = context.tryGetMediaClientForServer(serverIdOrNull(widget.photo.serverId));
    if (client == null) return _buildError();
    final imagePath = widget.photo.photoImagePath;
    final thumbPath = widget.photo.thumbPath;
    return _buildImage(
      client,
      imagePath,
      onFailed: () => imagePath == thumbPath ? _buildError() : _buildImage(client, thumbPath, onFailed: _buildError),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Focus(
                focusNode: _photoFocusNode,
                // Select does nothing on the photo for now.
                onKeyEvent: (_, event) =>
                    event.logicalKey.isSelectKey ? KeyEventResult.handled : KeyEventResult.ignored,
                child: InteractiveViewer(
                  maxScale: _maxZoom,
                  child: SizedBox.expand(child: _buildPhoto()),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 96,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    AppBarBackButton(focusNode: _backFocusNode),
                    Expanded(
                      // Pinches that start on the title still reach the photo.
                      child: IgnorePointer(child: _buildHeaderText(context)),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
