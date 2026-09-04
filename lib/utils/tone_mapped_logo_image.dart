import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'app_logger.dart';
import 'logo_tone.dart';

/// Remap target for logo artwork rendered over [surface].
///
/// Channel logos and clear logos are usually white-on-transparent marks
/// designed for dark UIs; on a light backdrop they vanish (issue #2197), so
/// light backdrops recolor light-toned logos toward [foreground]. Dark
/// backdrops — dark theme cards and scrims, or the light theme's inverted
/// focus card — render the original artwork. Pass the result to
/// `OptimizedMediaImage.logoToneTarget` / `ClearLogoImage.logoToneTarget`.
Color? logoToneTargetFor({required Color surface, required Color foreground}) {
  return surface.computeLuminance() > 0.5 ? foreground : null;
}

/// Cache key for [ToneMappedLogoImage]: the wrapped provider's key plus the
/// remap target and policy, so plain, light-adapted, and
/// differently-configured variants of the same artwork occupy distinct
/// [ImageCache] entries.
@immutable
class ToneMappedLogoKey {
  const ToneMappedLogoKey._(this._providerCacheKey, this._targetArgb, this._remapMixed);

  final Object _providerCacheKey;
  final int _targetArgb;
  final bool _remapMixed;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ToneMappedLogoKey &&
        other._providerCacheKey == _providerCacheKey &&
        other._targetArgb == _targetArgb &&
        other._remapMixed == _remapMixed;
  }

  @override
  int get hashCode => Object.hash(_providerCacheKey, _targetArgb, _remapMixed);
}

/// Recolors light-toned channel logos for legibility on light surfaces.
///
/// Broadcast channel logos are white-on-transparent marks designed for dark
/// UIs; on the light theme's white cards they vanish (issue #2197). This
/// provider decodes through [imageProvider] (normally the bounded
/// [ResizeImage] built by `MediaImageHelper.serverArtworkProvider`), then —
/// once per [ImageCache] entry — reads the single decoded frame back,
/// classifies it with [analyzeLogoTone], and for light-toned frames bakes a
/// [remapLightNeutral] copy targeting [target]. Dark or self-backed logos,
/// animated images, and anything that fails to analyze decode unchanged.
///
/// The readback and remap are a one-time per-entry cost at logo decode sizes
/// (≈65k pixels bounded by the guide cell budget); nothing runs per frame.
@immutable
class ToneMappedLogoImage extends ImageProvider<ToneMappedLogoKey> {
  const ToneMappedLogoImage(this.imageProvider, {required this.target, this.remapMixed = true});

  /// The provider performing the actual fetch and bounded decode.
  final ImageProvider imageProvider;

  /// The theme foreground color light-toned pixels are remapped toward.
  final Color target;

  /// Whether [LogoTone.lightMixed] frames — light content beside significant
  /// color — are remapped too. The guide's tiny channel cells want maximum
  /// legibility and keep this on; hero surfaces pass false so a mark whose
  /// color is part of its identity (a red-outline wordmark, a colored badge)
  /// renders untouched. [LogoTone.lightMonochrome] and
  /// [LogoTone.lightAccented] always remap.
  final bool remapMixed;

  /// Frames larger than this decode unchanged: channel logos are bounded far
  /// below it, so hitting the cap means the provider was applied to full-size
  /// artwork by mistake, and a multi-megapixel readback is not worth it.
  static const int _maxRemapPixels = 1 << 20;

  @override
  Future<ToneMappedLogoKey> obtainKey(ImageConfiguration configuration) {
    Completer<ToneMappedLogoKey>? completer;
    // If the inner obtainKey completes synchronously, result is filled in
    // before the completer is created, preserving the synchronous path the
    // ImageCache relies on to avoid flicker (same dance as ResizeImage).
    SynchronousFuture<ToneMappedLogoKey>? result;
    imageProvider.obtainKey(configuration).then((Object key) {
      final mappedKey = ToneMappedLogoKey._(key, target.toARGB32(), remapMixed);
      if (completer == null) {
        result = SynchronousFuture<ToneMappedLogoKey>(mappedKey);
      } else {
        completer.complete(mappedKey);
      }
    });
    if (result != null) {
      return result!;
    }
    completer = Completer<ToneMappedLogoKey>();
    return completer.future;
  }

  @override
  ImageStreamCompleter loadImage(ToneMappedLogoKey key, ImageDecoderCallback decode) {
    Future<ui.Codec> decodeToneMapped(ui.ImmutableBuffer buffer, {ui.TargetImageSizeCallback? getTargetSize}) async {
      final codec = await decode(buffer, getTargetSize: getTargetSize);
      if (codec.frameCount != 1) return codec;
      return _toneMapCodec(codec);
    }

    final completer = imageProvider.loadImage(key._providerCacheKey, decodeToneMapped);
    if (!kReleaseMode) {
      completer.debugLabel = '${completer.debugLabel} - ToneMapped(${target.toARGB32().toRadixString(16)})';
    }
    return completer;
  }

  /// Replaces a single-frame [codec] with a codec serving either the remapped
  /// frame or, when the frame should render unchanged or fails to analyze,
  /// the original frame. The engine codec's sole frame is consumed here, so
  /// the original codec is never handed back once decoding succeeded; a
  /// failing [ui.Codec.getNextFrame] propagates with the codec untouched and
  /// surfaces through the stream completer like any decode failure.
  Future<ui.Codec> _toneMapCodec(ui.Codec codec) async {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      ui.Image? remapped;
      try {
        remapped = await _remapImage(image);
      } catch (error, stackTrace) {
        // Best effort: a failed remap falls back to the original artwork,
        // which is exactly what renders today.
        appLogger.w('Logo tone remap failed', error: error, stackTrace: stackTrace);
      }
      final result = remapped ?? image.clone();
      codec.dispose();
      return _SingleFrameCodec(result);
    } finally {
      image.dispose();
    }
  }

  /// Returns the remapped frame, or null when the image should render
  /// unchanged. The raw-pixel descriptor decodes lazily, so the frame is
  /// pulled while the pixel buffer is still alive — the same lifetime dance
  /// as the engine's `decodeImageFromPixels`.
  Future<ui.Image?> _remapImage(ui.Image image) async {
    if (image.width * image.height > _maxRemapPixels) return null;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    if (data == null) return null;
    final tone = analyzeLogoTone(data, image.width, image.height, stride: 2);
    final remappable =
        tone == LogoTone.lightMonochrome ||
        tone == LogoTone.lightAccented ||
        (remapMixed && tone == LogoTone.lightMixed);
    if (!remappable) return null;

    final mapped = remapLightNeutral(data, targetArgb: target.toARGB32());
    final buffer = await ui.ImmutableBuffer.fromUint8List(mapped);
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: image.width,
      height: image.height,
      rowBytes: image.width * 4,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final remappedCodec = await descriptor.instantiateCodec();
    try {
      final frame = await remappedCodec.getNextFrame();
      return frame.image;
    } finally {
      remappedCodec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ToneMappedLogoImage &&
        other.imageProvider == imageProvider &&
        other.target == target &&
        other.remapMixed == remapMixed;
  }

  @override
  int get hashCode => Object.hash(imageProvider, target, remapMixed);

  @override
  String toString() => '${objectRuntimeType(this, 'ToneMappedLogoImage')}($imageProvider, target: $target)';
}

/// Serves one already-decoded frame, cloning it per pull so every caller owns
/// its copy. Replaces the engine codec after its lazy single frame has been
/// consumed for analysis; the engine's raw-pixel codecs decode lazily from
/// their descriptor, so they cannot outlive the disposal of their buffer the
/// way this wrapper can.
class _SingleFrameCodec implements ui.Codec {
  _SingleFrameCodec(this._image);

  final ui.Image _image;

  @override
  int get frameCount => 1;

  @override
  int get repetitionCount => 0;

  @override
  Future<ui.FrameInfo> getNextFrame() async => _SingleFrameInfo(_image.clone());

  @override
  void dispose() => _image.dispose();
}

class _SingleFrameInfo implements ui.FrameInfo {
  const _SingleFrameInfo(this.image);

  @override
  final ui.Image image;

  @override
  Duration get duration => Duration.zero;
}
