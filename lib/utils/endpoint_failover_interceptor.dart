import '../utils/app_logger.dart';

/// Maintains the list of endpoints we can cycle through when one fails.
class EndpointFailoverManager {
  EndpointFailoverManager(List<String> urls) {
    _setEndpoints(urls);
  }

  late List<String> _endpoints;
  int _currentIndex = 0;

  /// Incremented every time the active endpoint changes. Requests stamped with
  /// an older generation should not trigger additional failover cascades.
  int _generation = 0;
  int get generation => _generation;

  List<String> get endpoints => List.unmodifiable(_endpoints);

  String get current => _endpoints[_currentIndex];

  bool get hasFallback => _currentIndex < _endpoints.length - 1;

  /// Move to the next endpoint, returning its URL or null if exhausted.
  String? moveToNext() {
    if (!hasFallback) return null;
    _currentIndex++;
    _generation++;
    return _endpoints[_currentIndex];
  }

  /// Reset back to the first (preferred) endpoint. Called when all endpoints
  /// are exhausted so the next failure cycle starts from the best candidate.
  void resetToFirst() {
    if (_currentIndex != 0) {
      _currentIndex = 0;
      _generation++;
      appLogger.d('Failover endpoint list reset to first candidate');
    }
  }

  /// Replace the endpoint list and optionally set the active endpoint.
  void reset(List<String> urls, {String? currentBaseUrl}) {
    _setEndpoints(urls);
    if (currentBaseUrl != null) {
      final index = _endpoints.indexOf(currentBaseUrl);
      _currentIndex = index >= 0 ? index : 0;
    } else {
      _currentIndex = 0;
    }
    _generation++;
  }

  void _setEndpoints(List<String> urls) {
    final sanitized = <String>[];
    final seen = <String>{};
    for (final url in urls) {
      if (url.isEmpty || seen.contains(url)) continue;
      seen.add(url);
      sanitized.add(url);
    }
    if (sanitized.isEmpty) {
      throw ArgumentError('At least one endpoint is required');
    }
    _endpoints = sanitized;
    _currentIndex = _currentIndex.clamp(0, _endpoints.length - 1);
  }
}
