import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../sources/source_database.dart';
import '../sources/source_models.dart';
import '../sources/source_transport.dart';
import 'discovery_choice.dart';

/// Optional OpenAI-compatible reranker. It receives an ephemeral, restricted
/// view of already-authorized choices and can only reorder opaque local IDs.
class DiscoveryAiConfig {
  const DiscoveryAiConfig({required this.endpoint, required this.model, required this.apiKey, required this.enabled});

  final String endpoint;
  final String model;
  final String apiKey;
  final bool enabled;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'endpoint': endpoint,
    'model': model,
    'apiKey': apiKey,
    'enabled': enabled,
  };

  factory DiscoveryAiConfig.fromJson(Map<String, dynamic> value) {
    if (value['version'] != 1) return const DiscoveryAiConfig(endpoint: '', model: '', apiKey: '', enabled: false);
    return DiscoveryAiConfig(
      endpoint: value['endpoint'] is String ? value['endpoint'] as String : '',
      model: value['model'] is String ? value['model'] as String : '',
      apiKey: value['apiKey'] is String ? value['apiKey'] as String : '',
      enabled: value['enabled'] == true,
    );
  }

  bool get isConfigured {
    try {
      _chatEndpoint(endpoint);
      return model.trim().isNotEmpty &&
          model.length <= 120 &&
          !model.contains(RegExp(r'[\r\n]')) &&
          apiKey.length <= 4096 &&
          !apiKey.contains(RegExp(r'[\r\n]'));
    } on FormatException {
      return false;
    }
  }
}

class DiscoveryReranker {
  DiscoveryReranker(this._repository, {this.clientFactory});

  static const preferenceKey = 'discovery.ai-reranker.v1';
  static const maxCandidates = 24;
  static const _deadline = Duration(seconds: 8);
  static const _maxResponseBytes = 48 * 1024;
  final SourceRepository _repository;

  /// Optional transport seam for tests and custom HTTP client policies.
  final http.Client Function()? clientFactory;

  Future<DiscoveryAiConfig> load(String profileId) async =>
      DiscoveryAiConfig.fromJson(await _repository.privatePreference(profileId, preferenceKey));

  Future<void> save(String profileId, DiscoveryAiConfig config) async {
    if (!config.isConfigured) throw const FormatException('Invalid discovery AI configuration');
    await _repository.savePrivatePreference(profileId, preferenceKey, config.toJson());
  }

  Future<void> disable(String profileId) async {
    final current = await load(profileId);
    await _repository.savePrivatePreference(
      profileId,
      preferenceKey,
      DiscoveryAiConfig(
        endpoint: current.endpoint,
        model: current.model,
        apiKey: current.apiKey,
        enabled: false,
      ).toJson(),
    );
  }

  Future<void> clear(String profileId) => _repository.forgetPreference(profileId, preferenceKey);

  /// Returns a reordered copy, or null when the model result should be ignored.
  /// The caller keeps its deterministic baseline when this returns null.
  Future<List<DiscoveryChoice>?> reorder({
    required String profileId,
    required List<DiscoveryChoice> baseline,
    required List<String> Function(DiscoveryChoice) genresFor,
    required String mediaFamily,
    required int? maxMinutes,
    required String? genre,
    required String? mood,
    required String familiarity,
    required bool Function() stillCurrent,
  }) async {
    if (baseline.length < 2 || !stillCurrent()) return null;
    SourceTransport? transport;
    Completer<void>? abort;
    Timer? deadline;
    try {
      final config = await load(profileId);
      if (!stillCurrent() || !config.enabled || !config.isConfigured) return null;
      final candidates = baseline
          .where((choice) => choice.sourceId == null && !_hasRestrictedRating(choice.mediaItem?.contentRating))
          .take(maxCandidates)
          .toList(growable: false);
      if (candidates.length < 2) return null;

      // Provider-visible IDs never cross the wire. Map c0..c23 back locally.
      final localIds = {for (var index = 0; index < candidates.length; index++) 'c$index': candidates[index]};
      final payload = [
        for (final entry in localIds.entries)
          {
            'id': entry.key,
            'title': _bounded(entry.value.title, 120),
            'type': entry.value.type.name,
            'genres': genresFor(entry.value).take(8).map((value) => _bounded(value, 48)).toList(growable: false),
            'moods': (entry.value.mediaItem?.moods ?? const <String>[])
                .take(6)
                .map((value) => _bounded(value, 32))
                .toList(growable: false),
          },
      ];
      final endpoint = _chatEndpoint(config.endpoint);
      transport = SourceTransport(client: clientFactory?.call(), allowHttp: true);
      abort = Completer<void>();
      deadline = Timer(_deadline, () {
        if (!abort!.isCompleted) abort.complete();
      });
      final response = await transport
          .send(
            'POST',
            endpoint,
            abort: abort.future,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (config.apiKey.trim().isNotEmpty) 'Authorization': 'Bearer ${config.apiKey.trim()}',
            },
            body: jsonEncode({
              'model': config.model.trim(),
              'temperature': 0,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'Reorder only the provided candidate IDs for the user’s current discovery moment. Return JSON exactly as {"order":["c0"]}. Do not invent IDs or add explanation.',
                },
                {
                  'role': 'user',
                  'content': jsonEncode({
                    'moment': {
                      'media': _bounded(mediaFamily, 24),
                      'maxMinutes': maxMinutes?.clamp(1, 600),
                      'genre': genre == null ? null : _bounded(genre, 48),
                      'mood': mood == null ? null : _bounded(mood, 32),
                      'familiarity': _bounded(familiarity, 24),
                    },
                    'candidates': payload,
                  }),
                },
              ],
            }),
          )
          .timeout(_deadline);
      if (!stillCurrent() || response.statusCode < 200 || response.statusCode >= 300) return null;
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(_deadline)) {
        if (bytes.length + chunk.length > _maxResponseBytes) {
          if (!abort.isCompleted) abort.complete();
          return null;
        }
        bytes.addAll(chunk);
      }
      if (!stillCurrent()) return null;
      final envelope = sourceMap(jsonDecode(utf8.decode(bytes)));
      final choices = sourceList(envelope['choices']);
      if (choices.isEmpty) return null;
      final message = sourceMap(sourceMap(choices.first)['message']);
      final content = message['content'];
      if (content is! String || content.length > 16 * 1024) return null;
      final result = sourceMap(jsonDecode(content));
      final rawOrder = sourceList(result['order']);
      if (rawOrder.length < 2 || rawOrder.length > maxCandidates * 2) return null;
      final seen = <String>{};
      final reordered = <DiscoveryChoice>[];
      for (final rawId in rawOrder) {
        if (rawId is! String || !localIds.containsKey(rawId) || !seen.add(rawId)) continue;
        reordered.add(localIds[rawId]!);
      }
      if (reordered.length < 2 || !stillCurrent()) return null;
      reordered.addAll(localIds.entries.where((entry) => !seen.contains(entry.key)).map((entry) => entry.value));
      final rerankedIds = candidates.map((choice) => choice.id).toSet();
      var nextCandidate = 0;
      return baseline
          .map((choice) => rerankedIds.contains(choice.id) ? reordered[nextCandidate++] : choice)
          .toList(growable: false);
    } on Object {
      return null;
    } finally {
      deadline?.cancel();
      if (abort != null && !abort.isCompleted) abort.complete();
      transport?.close();
    }
  }
}

Uri _chatEndpoint(String value) {
  final uri = Uri.tryParse(value.trim());
  final loopback = uri != null && const {'localhost', '127.0.0.1', '::1'}.contains(uri.host.toLowerCase());
  if (uri == null ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.scheme != 'https' && !(uri.scheme == 'http' && loopback)) ||
      uri.toString().length > 1024 ||
      uri.pathSegments.any((segment) => segment == '.' || segment == '..')) {
    throw const FormatException('Discovery AI endpoint must use HTTPS or loopback HTTP');
  }
  var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
  if (path.endsWith('/chat/completions')) return uri;
  if (path.endsWith('/v1')) {
    path = '$path/chat/completions';
  } else {
    path = '$path/v1/chat/completions';
  }
  return uri.replace(path: path);
}

String _bounded(String value, int limit) {
  final normalized = value
      .replaceAll(RegExp(r'https?://\S+', caseSensitive: false), '[link]')
      .replaceAll(RegExp(r'[\u0000-\u001f\u007f]'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalized.substring(0, normalized.length > limit ? limit : normalized.length);
}

bool _hasRestrictedRating(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return false;
  return const {'r', 'nc-17', 'tv-ma', '18', '18+', 'x', 'xxx', 'adult', 'adults only'}.contains(normalized) ||
      normalized.contains('adults only');
}
