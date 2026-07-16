import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../media/media_server_client.dart';
import '../services/device_performance.dart';
import '../utils/media_image_helper.dart';

/// Displays server artwork and rotates through multiple backdrops in order.
///
/// The settled image remains visible until the incoming provider produces a
/// frame. Failed candidates are skipped without flashing an empty frame.
class CyclingMediaBackdrop extends StatefulWidget {
  const CyclingMediaBackdrop({
    super.key,
    required this.mediaKey,
    required this.imagePaths,
    required this.client,
    required this.width,
    required this.height,
    required this.fallbackColor,
    this.fallbackImagePaths = const [],
    this.localArtworkPathResolver,
    this.imageProviderResolver,
    this.allowNetwork = true,
    this.active = true,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.rotationInterval = const Duration(seconds: 10),
    this.fadeDuration = const Duration(milliseconds: 280),
  });

  final Object? mediaKey;
  final List<String> imagePaths;
  final List<String> fallbackImagePaths;
  final MediaServerClient? client;
  final String? Function(String artworkPath)? localArtworkPathResolver;

  /// Overrides provider construction for deterministic widget tests.
  @visibleForTesting
  final ImageProvider? Function(String artworkPath)? imageProviderResolver;
  final bool allowNetwork;
  final bool active;
  final double width;
  final double height;
  final BoxFit fit;
  final Alignment alignment;
  final Color fallbackColor;
  final Duration rotationInterval;
  final Duration fadeDuration;

  @override
  State<CyclingMediaBackdrop> createState() => _CyclingMediaBackdropState();
}

class _CyclingMediaBackdropState extends State<CyclingMediaBackdrop> with WidgetsBindingObserver {
  Timer? _rotationTimer;
  late List<String> _rotationPaths;
  late List<String> _fallbackPaths;
  final Set<String> _failedPaths = <String>{};
  final Set<String> _pendingProviderFailures = <String>{};
  int _rotationIndex = 0;
  int _fallbackIndex = 0;
  bool _lifecycleResumed = true;
  bool _tickerEnabled = true;
  bool _disableAnimations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycleResumed = switch (WidgetsBinding.instance.lifecycleState) {
      null || AppLifecycleState.resumed => true,
      _ => false,
    };
    _replacePaths();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_disableAnimations != disableAnimations) {
      _disableAnimations = disableAnimations;
    }
    _restartRotationTimer();
  }

  @override
  void didUpdateWidget(covariant CyclingMediaBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pathsChanged =
        widget.mediaKey != oldWidget.mediaKey ||
        !listEquals(widget.imagePaths, oldWidget.imagePaths) ||
        !listEquals(widget.fallbackImagePaths, oldWidget.fallbackImagePaths);
    if (pathsChanged) {
      _replacePaths();
    }
    if (pathsChanged || widget.active != oldWidget.active || widget.rotationInterval != oldWidget.rotationInterval) {
      _restartRotationTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleResumed = state == AppLifecycleState.resumed;
    if (_lifecycleResumed) {
      _restartRotationTimer();
    } else {
      _rotationTimer?.cancel();
      _rotationTimer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _replacePaths() {
    _rotationPaths = _uniquePaths(widget.imagePaths);
    final rotating = _rotationPaths.toSet();
    _fallbackPaths = _uniquePaths(widget.fallbackImagePaths).where((path) => !rotating.contains(path)).toList();
    _failedPaths.clear();
    _pendingProviderFailures.clear();
    _rotationIndex = 0;
    _fallbackIndex = 0;
  }

  static List<String> _uniquePaths(List<String> paths) {
    if (paths.isEmpty) return const [];
    final unique = <String>[];
    for (final path in paths) {
      if (path.isEmpty || unique.contains(path)) continue;
      unique.add(path);
    }
    return unique;
  }

  int get _usableRotationCount => _rotationPaths.where((path) => !_failedPaths.contains(path)).length;

  bool get _canRotate =>
      widget.active && _lifecycleResumed && _tickerEnabled && !_disableAnimations && _usableRotationCount > 1;

  void _restartRotationTimer() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
    if (!_canRotate) return;
    _rotationTimer = Timer(widget.rotationInterval, _handleRotationTimer);
  }

  void _handleRotationTimer() {
    _rotationTimer = null;
    if (!mounted) return;
    if (!_canRotate) return;
    _advanceRotation();
    _restartRotationTimer();
  }

  void _advanceRotation() {
    if (_rotationPaths.isEmpty) return;
    for (var offset = 1; offset <= _rotationPaths.length; offset++) {
      final next = (_rotationIndex + offset) % _rotationPaths.length;
      if (_failedPaths.contains(_rotationPaths[next])) continue;
      if (next == _rotationIndex) return;
      setState(() => _rotationIndex = next);
      return;
    }
  }

  String? get _currentPath {
    if (_rotationPaths.isNotEmpty && !_failedPaths.contains(_rotationPaths[_rotationIndex])) {
      return _rotationPaths[_rotationIndex];
    }
    for (var offset = 0; offset < _rotationPaths.length; offset++) {
      final index = (_rotationIndex + offset) % _rotationPaths.length;
      if (!_failedPaths.contains(_rotationPaths[index])) return _rotationPaths[index];
    }
    if (_fallbackPaths.isNotEmpty && !_failedPaths.contains(_fallbackPaths[_fallbackIndex])) {
      return _fallbackPaths[_fallbackIndex];
    }
    for (var offset = 0; offset < _fallbackPaths.length; offset++) {
      final index = (_fallbackIndex + offset) % _fallbackPaths.length;
      if (!_failedPaths.contains(_fallbackPaths[index])) return _fallbackPaths[index];
    }
    return null;
  }

  void _handleImageError(Object? key) {
    final path = key is String ? key : null;
    if (!mounted || path == null || _failedPaths.contains(path)) return;
    setState(() {
      _failedPaths.add(path);
      _pendingProviderFailures.remove(path);
      final rotationPosition = _rotationPaths.indexOf(path);
      if (rotationPosition >= 0) {
        for (var offset = 1; offset <= _rotationPaths.length; offset++) {
          final next = (rotationPosition + offset) % _rotationPaths.length;
          if (_failedPaths.contains(_rotationPaths[next])) continue;
          _rotationIndex = next;
          break;
        }
      } else {
        final fallbackPosition = _fallbackPaths.indexOf(path);
        if (fallbackPosition >= 0) {
          for (var offset = 1; offset <= _fallbackPaths.length; offset++) {
            final next = (fallbackPosition + offset) % _fallbackPaths.length;
            if (_failedPaths.contains(_fallbackPaths[next])) continue;
            _fallbackIndex = next;
            break;
          }
        }
      }
    });
    _restartRotationTimer();
  }

  ImageProvider? _providerFor(BuildContext context, String path) {
    final providerOverride = widget.imageProviderResolver;
    if (providerOverride != null) return providerOverride(path);

    final size = MediaQuery.sizeOf(context);
    final width = widget.width.isFinite && widget.width > 0 ? widget.width : size.width;
    final height = widget.height.isFinite && widget.height > 0 ? widget.height : size.height;
    final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
    final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: (width * dpr).round(),
      displayHeight: (height * dpr).round(),
      imageType: ImageType.art,
    );

    final localPath = widget.localArtworkPathResolver?.call(path);
    if (localPath != null) {
      final file = File(localPath);
      if (file.existsSync()) {
        return MediaImageHelper.boundedDecode(FileImage(file), memWidth: memWidth, memHeight: memHeight);
      }
    }
    if (!widget.allowNetwork) return null;

    final imageUrl = MediaImageHelper.getOptimizedImageUrl(
      client: widget.client,
      thumbPath: path,
      maxWidth: width,
      maxHeight: height,
      devicePixelRatio: dpr,
      imageType: ImageType.art,
    );
    if (imageUrl.isEmpty) return null;
    return MediaImageHelper.serverArtworkProvider(imageUrl: imageUrl, memWidth: memWidth, memHeight: memHeight);
  }

  void _reportMissingProvider(String path) {
    if (!_pendingProviderFailures.add(path)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleImageError(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = _currentPath;
    final provider = path == null ? null : _providerFor(context, path);
    if (path != null && provider == null) _reportMissingProvider(path);
    final fadeDuration = _disableAnimations ? Duration.zero : DevicePerformance.reducedDuration(widget.fadeDuration);

    return _BackdropArtworkCrossfade(
      artworkKey: (widget.mediaKey, path),
      imageErrorKey: path,
      image: provider,
      duration: fadeDuration,
      fit: widget.fit,
      alignment: widget.alignment,
      fallbackColor: widget.fallbackColor,
      onImageError: _handleImageError,
    );
  }
}

class _BackdropArtworkCrossfade extends StatefulWidget {
  const _BackdropArtworkCrossfade({
    required this.artworkKey,
    required this.imageErrorKey,
    required this.image,
    required this.duration,
    required this.fit,
    required this.alignment,
    required this.fallbackColor,
    required this.onImageError,
  });

  final Object? artworkKey;
  final Object? imageErrorKey;
  final ImageProvider? image;
  final Duration duration;
  final BoxFit fit;
  final Alignment alignment;
  final Color fallbackColor;
  final ValueChanged<Object?> onImageError;

  @override
  State<_BackdropArtworkCrossfade> createState() => _BackdropArtworkCrossfadeState();
}

class _BackdropArtworkCrossfadeState extends State<_BackdropArtworkCrossfade> with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late Object? _currentKey = widget.artworkKey;
  late ImageProvider? _base = widget.image;
  late Object? _baseErrorKey = widget.imageErrorKey;
  ImageProvider? _incoming;
  Object? _incomingErrorKey;
  bool _incomingIsColor = false;
  bool _fadeStarted = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant _BackdropArtworkCrossfade oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fade.duration = widget.duration;
    if (widget.artworkKey == _currentKey) {
      if (widget.image != null && widget.image != _base && _incoming == null) {
        _base = widget.image;
        _baseErrorKey = widget.imageErrorKey;
      }
      return;
    }

    _currentKey = widget.artworkKey;
    if (widget.image != null && widget.image == _base) {
      _baseErrorKey = widget.imageErrorKey;
      _dropIncoming();
      return;
    }

    setState(() {
      _fade.stop();
      _fade.value = 0;
      _fadeStarted = false;
      _incoming = widget.image;
      _incomingErrorKey = widget.imageErrorKey;
      _incomingIsColor = widget.image == null;
      if (_incoming == null) _startFade();
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _startFade() {
    if (_fadeStarted) return;
    _fadeStarted = true;
    _fade.forward().whenComplete(_promoteIncoming);
  }

  void _promoteIncoming() {
    if (!mounted) return;
    setState(() {
      _base = _incoming;
      _baseErrorKey = _incomingErrorKey;
      _dropIncoming();
    });
  }

  void _dropIncoming() {
    _incoming = null;
    _incomingErrorKey = null;
    _incomingIsColor = false;
    _fadeStarted = false;
    _fade.value = 0;
  }

  void _reportError(Object? imageErrorKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onImageError(imageErrorKey);
    });
  }

  Widget _image(ImageProvider provider, Object? imageErrorKey, {Animation<double>? opacity}) {
    final incoming = opacity != null;
    return Image(
      key: incoming ? ValueKey<ImageProvider>(provider) : null,
      image: provider,
      fit: widget.fit,
      alignment: widget.alignment,
      excludeFromSemantics: true,
      gaplessPlayback: true,
      opacity: opacity,
      frameBuilder: !incoming
          ? null
          : (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null || wasSynchronouslyLoaded) {
                _startFade();
              }
              return child;
            },
      errorBuilder: (context, error, stackTrace) {
        _reportError(imageErrorKey);
        return incoming ? const SizedBox.shrink() : ColoredBox(color: widget.fallbackColor);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_base != null) _image(_base!, _baseErrorKey) else ColoredBox(color: widget.fallbackColor),
        if (_incoming != null) _image(_incoming!, _incomingErrorKey, opacity: _fade),
        if (_incomingIsColor)
          AnimatedBuilder(
            animation: _fade,
            builder: (context, _) =>
                ColoredBox(color: widget.fallbackColor.withValues(alpha: widget.fallbackColor.a * _fade.value)),
          ),
      ],
    );
  }
}
