import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../mpv/player/player.dart';

/// Generates and manages an ambient lighting GLSL shader that fills letterbox/pillarbox
/// bars with a blurred, dimmed version of the video edges.
///
/// Uses video-aspect-override to fill the window (eliminating black bars), then
/// a GLSL shader composites the sharp original video centered at correct aspect
/// over a blurred background.
///
/// The shader uses MPV's built-in `input_size` and `target_size` uniforms to
/// dynamically compute the video rect position. On window resize, only
/// `video-aspect-override` needs updating — no shader regeneration required.
class AmbientLightingService {
  final Player _player;
  String? _shaderPath;
  bool _enabled = false;

  /// Brightness multiplier for the blurred background (0.0-1.0).
  static const double _brightness = 0.5;

  AmbientLightingService(this._player);

  bool get isEnabled => _enabled;
  bool get isSupported => _player.playerType == 'mpv';

  /// Enable ambient lighting effect.
  ///
  /// [videoAspect] - the source video's display aspect ratio (width/height).
  /// [outputAspect] - the player widget's aspect ratio (width/height).
  Future<void> enable(double videoAspect, double outputAspect) async {
    if (!isSupported) return;

    try {
      // Write static shader (only needs to happen once)
      _shaderPath ??= await _writeShaderToTemp(_generateShader());

      if (kDebugMode) {
        debugPrint('AmbientLightingService: Shader path: $_shaderPath');
      }

      // Set video-aspect-override to fill the entire output area
      await _player.setProperty('video-aspect-override', outputAspect.toString());

      // Append ambient lighting shader
      await _player.command(['change-list', 'glsl-shaders', 'append', _shaderPath!]);

      _enabled = true;

      if (kDebugMode) {
        debugPrint('AmbientLightingService: Enabled (video=$videoAspect, output=$outputAspect)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AmbientLightingService: Failed to enable: $e');
      }
    }
  }

  /// Disable ambient lighting effect and restore normal letterboxing.
  Future<void> disable() async {
    if (!_enabled) return;

    try {
      if (_shaderPath != null) {
        await _player.command(['change-list', 'glsl-shaders', 'remove', _shaderPath!]);
      }

      await _player.setProperty('video-aspect-override', 'no');

      _enabled = false;

      if (kDebugMode) {
        debugPrint('AmbientLightingService: Disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AmbientLightingService: Failed to disable: $e');
      }
    }
  }

  /// Re-append the ambient lighting shader to the chain.
  /// Called by ShaderService after it rebuilds the shader chain (clr + append).
  Future<void> reappendShader() async {
    if (!_enabled || _shaderPath == null) return;
    await _player.command(['change-list', 'glsl-shaders', 'append', _shaderPath!]);
  }

  /// Update video-aspect-override when the window resizes.
  /// The shader adapts automatically via dynamic `target_size` uniform.
  void updateOutputAspect(double outputAspect) {
    if (!_enabled) return;
    _player.setProperty('video-aspect-override', outputAspect.toString());
  }

  /// Generate a static multi-pass GLSL shader.
  ///
  /// Uses MPV's built-in `input_size` (video dimensions) and `target_size`
  /// (output dimensions) uniforms which update automatically on resize.
  /// No baked-in aspect constants — fully adaptive.
  ///
  /// Pipeline (all MAIN hooks):
  /// 1. Save original video as ORIGINAL
  /// 2. Downscale to 1/8 as SMALL (center 60% zoom)
  /// 3-5. Three Kawase blur passes at 1/8 -> BLUR8C
  /// 6. Downscale BLUR8C to 1/64 as TINY
  /// 7-8. Two more Kawase blur passes at 1/64 -> GLOW
  /// 9. Composite: video rect -> ORIGINAL, bars -> GLOW
  String _generateShader() {
    final br = _brightness.toStringAsFixed(2);
    final buf = StringBuffer();

    // Pass 1: Save original video
    buf.writeln('//!HOOK MAIN');
    buf.writeln('//!BIND HOOKED');
    buf.writeln('//!SAVE ORIGINAL');
    buf.writeln('//!DESC Ambient Lighting Save');
    buf.writeln('vec4 hook() {');
    buf.writeln('    return HOOKED_tex(HOOKED_pos);');
    buf.writeln('}');
    buf.writeln();

    // Pass 2: Downscale to 1/8 with center zoom.
    buf.writeln('//!HOOK MAIN');
    buf.writeln('//!BIND ORIGINAL');
    buf.writeln('//!SAVE SMALL');
    buf.writeln('//!WIDTH ORIGINAL.w 8 /');
    buf.writeln('//!HEIGHT ORIGINAL.h 8 /');
    buf.writeln('//!DESC Ambient Lighting Downscale');
    buf.writeln('vec4 hook() {');
    buf.writeln('    vec2 uv = ORIGINAL_pos * 0.6 + 0.2;');
    buf.writeln('    return ORIGINAL_tex(uv);');
    buf.writeln('}');
    buf.writeln();

    // Pass 3-5: Three Kawase blur passes at 1/8 resolution.
    const blur8Steps = [
      ('SMALL',  'BLUR8A', '2.0',  'Blur1'),
      ('BLUR8A', 'BLUR8B', '6.0',  'Blur2'),
      ('BLUR8B', 'BLUR8C', '12.0', 'Blur3'),
    ];
    for (final (input, output, offset, desc) in blur8Steps) {
      buf.writeln('//!HOOK MAIN');
      buf.writeln('//!BIND $input');
      buf.writeln('//!SAVE $output');
      buf.writeln('//!WIDTH $input.w');
      buf.writeln('//!HEIGHT $input.h');
      buf.writeln('//!DESC Ambient Lighting $desc');
      buf.writeln('vec4 hook() {');
      buf.writeln('    vec2 ps = ${input}_pt;');
      buf.writeln('    vec4 s = ${input}_tex(${input}_pos + vec2( $offset,  $offset) * ps)');
      buf.writeln('           + ${input}_tex(${input}_pos + vec2( $offset, -$offset) * ps)');
      buf.writeln('           + ${input}_tex(${input}_pos + vec2(-$offset,  $offset) * ps)');
      buf.writeln('           + ${input}_tex(${input}_pos + vec2(-$offset, -$offset) * ps);');
      buf.writeln('    return s * 0.25;');
      buf.writeln('}');
      buf.writeln();
    }

    // Pass 6: Downscale the already-blurred 1/8 texture to 1/64.
    buf.writeln('//!HOOK MAIN');
    buf.writeln('//!BIND BLUR8C');
    buf.writeln('//!SAVE TINY');
    buf.writeln('//!WIDTH BLUR8C.w 8 /');
    buf.writeln('//!HEIGHT BLUR8C.h 8 /');
    buf.writeln('//!DESC Ambient Lighting Downscale2');
    buf.writeln('vec4 hook() {');
    buf.writeln('    return BLUR8C_tex(BLUR8C_pos);');
    buf.writeln('}');
    buf.writeln();

    // Pass 7-8: Two more Kawase blur passes at 1/64 for maximum diffusion.
    const blur64Steps = [
      ('TINY',  'GLOW1', '3.0', 'Blur4'),
      ('GLOW1', 'GLOW',  '6.0', 'Blur5'),
    ];
    for (final (input, output, offset, desc) in blur64Steps) {
      buf.writeln('//!HOOK MAIN');
      buf.writeln('//!BIND $input');
      buf.writeln('//!SAVE $output');
      buf.writeln('//!WIDTH $input.w');
      buf.writeln('//!HEIGHT $input.h');
      buf.writeln('//!DESC Ambient Lighting $desc');
      buf.writeln('vec4 hook() {');
      buf.writeln('    vec2 ps = ${input}_pt;');
      buf.writeln('    vec4 s = ${input}_tex(${input}_pos + vec2( $offset,  $offset) * ps)');
      buf.writeln('           + ${input}_tex(${input}_pos + vec2( $offset, -$offset) * ps)');
      buf.writeln('           + ${input}_tex(${input}_pos + vec2(-$offset,  $offset) * ps)');
      buf.writeln('           + ${input}_tex(${input}_pos + vec2(-$offset, -$offset) * ps);');
      buf.writeln('    return s * 0.25;');
      buf.writeln('}');
      buf.writeln();
    }

    // Pass 9: Composite — no //!SAVE so this replaces MAIN.
    // Uses built-in input_size (video coded dims) and target_size (output dims)
    // to dynamically compute where the video rect sits. These auto-update on resize.
    buf.writeln('//!HOOK MAIN');
    buf.writeln('//!BIND ORIGINAL');
    buf.writeln('//!BIND GLOW');
    buf.writeln('//!DESC Ambient Lighting Composite');
    buf.writeln('vec4 hook() {');
    buf.writeln('    float vid_aspect = input_size.x / input_size.y;');
    buf.writeln('    float out_aspect = target_size.x / target_size.y;');
    buf.writeln();
    buf.writeln('    vec2 scale, off;');
    buf.writeln('    if (vid_aspect > out_aspect) {');
    buf.writeln('        float s = out_aspect / vid_aspect;');
    buf.writeln('        scale = vec2(1.0, s);');
    buf.writeln('        off = vec2(0.0, (1.0 - s) * 0.5);');
    buf.writeln('    } else {');
    buf.writeln('        float s = vid_aspect / out_aspect;');
    buf.writeln('        scale = vec2(s, 1.0);');
    buf.writeln('        off = vec2((1.0 - s) * 0.5, 0.0);');
    buf.writeln('    }');
    buf.writeln();
    buf.writeln('    vec2 vid_pos = (ORIGINAL_pos - off) / scale;');
    buf.writeln();
    buf.writeln('    if (all(greaterThanEqual(vid_pos, vec2(0.0))) &&');
    buf.writeln('        all(lessThanEqual(vid_pos, vec2(1.0)))) {');
    buf.writeln('        return ORIGINAL_tex(vid_pos);');
    buf.writeln('    }');
    buf.writeln();
    buf.writeln('    return GLOW_tex(ORIGINAL_pos) * $br;');
    buf.writeln('}');

    return buf.toString();
  }

  /// Write the shader to a temp file and return the path.
  Future<String> _writeShaderToTemp(String shader) async {
    final cacheDir = await getTemporaryDirectory();
    final shaderDir = Directory(path.join(cacheDir.path, 'shaders'));
    if (!shaderDir.existsSync()) {
      shaderDir.createSync(recursive: true);
    }
    final file = File(path.join(shaderDir.path, 'ambient_lighting.glsl'));
    await file.writeAsString(shader);
    return file.path;
  }
}
