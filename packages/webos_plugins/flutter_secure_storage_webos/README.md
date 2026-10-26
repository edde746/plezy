# flutter_secure_storage_webos

The webOS implementation of [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage).

## Supported platforms

This plugin is supported on webOS 26 media or above.

## Usage

This package is not an _endorsed_ implementation of `flutter_secure_storage`.
Therefore, you have to include `flutter_secure_storage_webos` alongside `flutter_secure_storage` as dependencies in your `pubspec.yaml` file.

**pubspec.yaml:**

```yaml
dependencies:
  flutter_secure_storage: ^9.2.3
  flutter_secure_storage_webos:
    git:
      url: https://github.com/lg-flutter-webos/plugins.git
      path: packages/flutter_secure_storage
      ref: main
```

**Import:**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
```

For detailed usage, see https://pub.dev/packages/flutter_secure_storage#getting-started.

## Required configurations

Add the following ACGs to your `appinfo.json`:

```json
"requiredACG": [
  "securitykey.operation"
]
```

## Example

See the [example application](example/lib/main.dart) for a complete usage demonstration.

## API Reference

See the [API Reference](API_REFERENCE.md) for webOS-specific behavior details.

## Limitations

- Platform-specific options (`IOSOptions`, `AndroidOptions`, `WebOptions`) are ignored on webOS.
- Data is stored in a local SQLite database with AES-256-CBC encryption, not in a system keychain/keystore.
