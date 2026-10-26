# Linux packaging adapter

Upstream: flutter_inappwebview 6.2.0-beta.3, https://github.com/pichillilorenzo/flutter_inappwebview/releases/tag/v6.2.0-beta.3

Dart implementation and assets are unmodified. Only pubspec.yaml omits the optional Linux WPE plugin and upstream development tools. The newer bridge-origin/main-frame restrictions remain enabled on Android, iOS, macOS and Windows. Linux publications use the same sandboxed Foliate engine in the system browser through a session-scoped loopback bridge, implemented in PlezyNG. This avoids imposing WPE WebKit, which is unavailable on the existing Ubuntu release build image, on every PlezyNG installation.

When upgrading, refresh the package and retain this manifest-only difference until WPE packaging is supported and tested. License: upstream Apache-2.0 in LICENSE.
