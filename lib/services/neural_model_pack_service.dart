import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/motion_processing_mode.dart';
import '../utils/app_logger.dart';

/// Installs the opt-in ANVIL model packs used by the Plezy Motion Engine.
///
/// The compact 540p Performance graph is bundled and copied to app-private
/// storage on demand. Balanced and Quality graphs are downloaded from a pinned
/// upstream revision and checked by size and SHA-256 before native use.
abstract final class NeuralModelPackService {
  static const _repositoryRevision = 'fa97e30f6aabe897bd4f6f82d971ad607f5d61fa';
  static const _repository = 'https://huggingface.co/NihilDigit/anvil';
  static const _androidFilterRevision = '1efc82739f6f7034cd63e7ee8b3ec5431df27467';

  static const _performanceModel = _NeuralModelPack(
    id: 'anvil-s-540p',
    revision: _repositoryRevision,
    assetPath: 'assets/motion_models/anvil-s-540p.onnx',
    filename: 'anvil-s-540p.onnx',
    bytes: 3431923,
    sha256: '6b599d7b13c848ce7608d5e6fa1de8ec0adea8477d29a57be69d71daf808ce84',
  );

  static const _balancedModel = _NeuralModelPack(
    id: 'anvil-s-1080p',
    revision: _repositoryRevision,
    url: '$_repository/resolve/$_repositoryRevision/onnx/D_unet_v3bs_nomv_1080p.onnx',
    filename: 'D_unet_v3bs_nomv_1080p.onnx',
    bytes: 3441349,
    sha256: '65e871aed25b331e3a3747cf9019942121a94af71997476f5804a24b768cd0d8',
  );

  static const _qualityModel = _NeuralModelPack(
    id: 'anvil-m-1080p',
    revision: _repositoryRevision,
    url: '$_repository/resolve/$_repositoryRevision/onnx/D_unet_v3bm_nomv_1080p.onnx',
    filename: 'D_unet_v3bm_nomv_1080p.onnx',
    bytes: 10677524,
    sha256: '261f95a17c865b45e4d7e2be3439d91b47315bef96e32d46f3cfc785941774fd',
  );

  // The upstream Android HTP build publishes a compiled context for the
  // Snapdragon 8 Gen 3 (Hexagon V75). It is a separate artifact from the ONNX
  // graph: QNN cannot consume that graph as a serialized context, and this
  // binary must never be used on a different HTP generation.
  static const _androidHtpV75Context = _NeuralModelPack(
    id: 'anvil-s-1080p-qnn-v75',
    revision: _androidFilterRevision,
    url:
        'https://raw.githubusercontent.com/NihilDigit/mpv-android-anvil/$_androidFilterRevision/'
        'app/src/main/assets/anvil/context.serialized.bin',
    filename: 'context.serialized.bin',
    bytes: 2363392,
    sha256: '86b6557a03ca751b3a21176d2905dee24c1bcbd8b3d052c6f984608ce08ea491',
  );

  static final Map<String, Future<File>> _inFlight = {};

  /// Resolve the selected preset to its pinned local ONNX model.
  /// Performance uses a bundled 540p ANVIL-S graph; Balanced uses the
  /// upstream 1080p ANVIL-S graph; Quality uses the larger ANVIL-M graph.
  static Future<File> ensureInstalled(NeuralInterpolationPreset preset) =>
      _ensureInstalledMemoized(_modelForPreset(preset));

  /// Return an already verified pack, or begin installing it without holding
  /// the playback startup path. Neural playback can take effect on the next
  /// open after this background download completes.
  static Future<File?> installedOrStartInstall(NeuralInterpolationPreset preset) async {
    final model = _modelForPreset(preset);
    final support = await getApplicationSupportDirectory();
    final destination = File(p.join(support.path, 'motion-models', model.id, model.revision, model.filename));
    if (await _isValid(destination, model)) return destination;
    if (model.assetPath != null) return _ensureInstalledMemoized(model);

    final pending = _ensureInstalledMemoized(model);
    unawaited(
      pending.catchError((Object error, StackTrace stackTrace) {
        appLogger.w('Neural model pack ${model.id} could not be installed', error: error, stackTrace: stackTrace);
        return destination;
      }),
    );
    return null;
  }

  static _NeuralModelPack _modelForPreset(NeuralInterpolationPreset preset) => switch (preset) {
    NeuralInterpolationPreset.performance => _performanceModel,
    NeuralInterpolationPreset.balanced => _balancedModel,
    NeuralInterpolationPreset.quality => _qualityModel,
  };

  /// Return the context variant for a Qualcomm target and neural preset.
  /// The current measured targets use 720p on V69 and 1080p on V73/V75.
  static String androidContextModelId(String resolution, NeuralInterpolationPreset preset) {
    final model = preset == NeuralInterpolationPreset.quality ? 'anvil-m' : 'anvil-s';
    return '$model-$resolution';
  }

  /// Return an installed, verified V75/ANVIL-S context or start its download
  /// without blocking playback. Other target and model combinations are
  /// generated from the pinned ANVIL source and installed as APK assets.
  static Future<File?> installedOrStartAndroidHtpContext(String architecture, String modelId) async {
    if (architecture != 'v75' || modelId != 'anvil-s-1080p') return null;

    final support = await getApplicationSupportDirectory();
    final destination = File(
      p.join(
        support.path,
        'motion-models',
        _androidHtpV75Context.id,
        _androidHtpV75Context.revision,
        _androidHtpV75Context.filename,
      ),
    );
    if (await _isValid(destination, _androidHtpV75Context)) return destination;

    final pending = _ensureInstalledMemoized(_androidHtpV75Context);
    unawaited(
      pending.catchError((Object error, StackTrace stackTrace) {
        appLogger.w(
          'Neural model pack ${_androidHtpV75Context.id} could not be installed',
          error: error,
          stackTrace: stackTrace,
        );
        return destination;
      }),
    );
    return null;
  }

  static Future<File> _ensureInstalledMemoized(_NeuralModelPack model) {
    final pending = _inFlight[model.id];
    if (pending != null) return pending;

    final install = _ensureInstalled(model).whenComplete(() => _inFlight.remove(model.id));
    _inFlight[model.id] = install;
    return install;
  }

  static Future<File> _ensureInstalled(_NeuralModelPack model) async {
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'motion-models', model.id, model.revision));
    final destination = File(p.join(directory.path, model.filename));
    if (await _isValid(destination, model)) return destination;

    if (await destination.exists()) await destination.delete();
    await directory.create(recursive: true);

    final partial = File('${destination.path}.partial');
    if (model.assetPath case final assetPath?) {
      return _installBundledAsset(destination, partial, model, assetPath);
    }
    final url = model.url;
    if (url == null) throw StateError('Neural model pack has no source.');
    final uri = Uri.parse(url);
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', uri)).timeout(const Duration(minutes: 2));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Neural model download failed with status ${response.statusCode}.');
      }
      if (response.contentLength != null && response.contentLength != model.bytes) {
        throw const FormatException('Neural model pack size does not match its pinned manifest.');
      }

      final digestOutput = _DigestOutput();
      final digestInput = sha256.startChunkedConversion(digestOutput);
      final output = partial.openWrite();
      var outputClosed = false;
      var receivedBytes = 0;
      try {
        await for (final chunk in response.stream.timeout(const Duration(seconds: 45))) {
          receivedBytes += chunk.length;
          if (receivedBytes > model.bytes) {
            throw const FormatException('Neural model pack exceeds its pinned manifest size.');
          }
          digestInput.add(chunk);
          output.add(chunk);
        }
        if (receivedBytes != model.bytes) {
          throw const FormatException('Neural model pack size does not match its pinned manifest.');
        }

        digestInput.close();
        await output.flush();
        await output.close();
        outputClosed = true;

        if (digestOutput.value.toString() != model.sha256) {
          throw const FormatException('Neural model pack checksum does not match its pinned manifest.');
        }

        await partial.rename(destination.path);
      } catch (_) {
        if (!outputClosed) {
          try {
            await output.close();
          } catch (_) {
            // Keep the download or validation error as the reported failure.
          }
        }
        rethrow;
      }
      return destination;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<File> _installBundledAsset(
    File destination,
    File partial,
    _NeuralModelPack model,
    String assetPath,
  ) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (bytes.length != model.bytes || sha256.convert(bytes).toString() != model.sha256) {
        throw const FormatException('Bundled Neural model pack does not match its pinned manifest.');
      }
      await partial.writeAsBytes(bytes, flush: true);
      await partial.rename(destination.path);
      return destination;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  static Future<bool> _isValid(File file, _NeuralModelPack model) async {
    if (!await file.exists() || await file.length() != model.bytes) return false;
    final digestOutput = _DigestOutput();
    final digestInput = sha256.startChunkedConversion(digestOutput);
    await for (final chunk in file.openRead()) {
      digestInput.add(chunk);
    }
    digestInput.close();
    return digestOutput.value.toString() == model.sha256;
  }
}

final class _DigestOutput implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value ?? (throw StateError('SHA-256 digest was not finalized.'));

  @override
  void add(Digest digest) {
    if (_value != null) throw StateError('SHA-256 digest was finalized more than once.');
    _value = digest;
  }

  @override
  void close() {}
}

final class _NeuralModelPack {
  final String id;
  final String revision;
  final String? url;
  final String? assetPath;
  final String filename;
  final int bytes;
  final String sha256;

  const _NeuralModelPack({
    required this.id,
    required this.revision,
    this.url,
    this.assetPath,
    required this.filename,
    required this.bytes,
    required this.sha256,
  }) : assert((url == null) != (assetPath == null));
}
