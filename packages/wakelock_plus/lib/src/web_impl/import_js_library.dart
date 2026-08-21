import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

/// This is an implementation of the `import_js_library` plugin that is used
/// until that plugin is migrated to null safety.
/// See https://github.com/florent37/flutter_web_import_js_library/pull/6#issuecomment-735349208.

/// Imports a JS script file from the given [url] given the relative
/// [flutterPluginName].
Future<void> importJsLibrary({required String url, String? flutterPluginName}) async {
  if (flutterPluginName == null) {
    return _importJSLibraries([url]);
  } else {
    return _importJSLibraries([_libraryUrl(url, flutterPluginName)]);
  }
}

String _libraryUrl(String url, String pluginName) {
  // Added suggested changes as per
  // https://github.com/fluttercommunity/wakelock_plus/issues/19#issuecomment-2301963609
  if (url.startsWith('./')) {
    url = url.replaceFirst('./', '');
  }

  if (url.startsWith('assets/')) {
    if (const bool.fromEnvironment('WEB_PLUGIN_TESTS', defaultValue: false)) {
      // Flutter tests running on Chrome just need to use the library path
      // without pre-pending "assets/".
      //
      // In other words, don't use the asset manager since it's not currently
      // supported for Chrome-based Flutter tests.
      //
      // See https://github.com/flutter/flutter/issues/159879 for more details.
      // TODO: Remove the workaround once test asset support is added
      //       for tests running in Chrome.
      return 'packages/$pluginName/$url';
    }
    return ui_web.assetManager.getAssetUrl('packages/$pluginName/$url');
  }

  return url;
}

Future? _importRunning;
Map<String, String> _loadedLibraries = {};
int _nextLibraryId = 0;

web.HTMLScriptElement _createScriptTag(String library) {
  final scriptId = 'imported-js-library-${_nextLibraryId++}';
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..type = 'text/javascript'
    ..charset = 'utf-8'
    ..async = true
    ..src = library
    ..id = scriptId;
  return script;
}

/// Injects a bunch of libraries in the `<head>` and returns a
/// Future that resolves when all load.
Future<void> _importJSLibraries(List<String> libraries) async {
  // we add the library to _loadedLibraries asynchronously, so we need locking.
  // Dart uses voluntary preemption, so everything between two `await`s can be
  // considered locked
  while (_importRunning != null) {
    await _importRunning;
  }
  final importLockCompleter = Completer();
  _importRunning = importLockCompleter.future;
  final loading = <Future<void>>[];
  final head = web.document.head;

  for (final library in libraries) {
    if (!_isImported(library)) {
      final scriptTag = _createScriptTag(library);
      head!.appendChild(scriptTag);
      final completer = Completer();
      loading.add(completer.future);

      unawaited(
        scriptTag.onLoad.first.then((_) {
          _loadedLibraries[library] = scriptTag.id;
          completer.complete();
        }),
      );
      unawaited(scriptTag.onError.first.then((event) => completer.completeError(Exception('Error loading: $library'))));
    }
  }

  try {
    await Future.wait(loading, eagerError: true);
  } finally {
    // first "unlock" future, then complete the completer for anyone already waiting.
    // I'm not sure if `.complete()` is yielding execution, so this is the safe order
    _importRunning = null;
    importLockCompleter.complete();
  }
}

bool _isImported(String url) {
  final head = web.document.head!;
  return _isLoaded(head, url);
}

bool _isLoaded(web.HTMLHeadElement head, String url) {
  final scriptId = _loadedLibraries[url];
  if (scriptId == null) {
    return false;
  }
  return head.querySelector('#$scriptId') != null;
}
