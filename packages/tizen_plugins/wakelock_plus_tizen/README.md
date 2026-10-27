# wakelock_plus_tizen

[![pub package](https://img.shields.io/pub/v/wakelock_plus_tizen.svg)](https://pub.dev/packages/wakelock_plus_tizen)

The Tizen implementation of [`wakelock_plus`](https://pub.dev/packages/wakelock_plus).

## Usage

This package is not an _endorsed_ implementation of `wakelock_plus`. Therefore, you have to include `wakelock_plus_tizen` alongside `wakelock_plus` as dependencies in your `pubspec.yaml` file.

```yaml
dependencies:
  wakelock_plus: ^1.2.8
  wakelock_plus_tizen: ^2.0.0
```

Then you can import `wakelock_plus` in your Dart code:

```dart
import 'package:wakelock_plus/wakelock_plus.dart';
```

For detailed usage, see https://pub.dev/packages/wakelock_plus#usage.
