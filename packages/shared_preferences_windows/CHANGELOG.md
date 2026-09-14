## 2.4.1 (Plezy vendored patch)

Vendored from pub.dev `shared_preferences_windows` 2.4.1. Upstream writes the whole
preference document with a bare `writeAsStringSync`, which truncates the live
file before writing it, so every preference write has a window in which the
only copy on disk is empty or half-written. A crash inside that window leaves a
store that fails to parse on every later launch — and it holds the
credential-vault key, so the loss is not recoverable by rewriting it. This is
the corruption behind Plezy issue #1732.

The local patch stages the document to a sibling `.tmp`, flushes it, then
renames it over the target, and sweeps a stale staging file once the canonical
document has been read cleanly. The published example app is not vendored.

When updating, reapply both PLEZY DELTA blocks in `lib/shared_preferences_windows.dart`
and see `provenance.json` for the full refresh contract.

## 2.4.1

* Fixes `getStringList` returning immutable list.
* Fixes `getStringList` cast error.
* Updates minimum supported SDK version to Flutter 3.19/Dart 3.3.

## 2.4.0

* Adds `SharedPreferencesAsyncWindows` API.
* Updates minimum supported SDK version to Flutter 3.16/Dart 3.2.

## 2.3.2

* Updates `package:file` version constraints.

## 2.3.1

* Adds pub topics to package metadata.
* Updates minimum supported SDK version to Flutter 3.7/Dart 2.19.

## 2.3.0

* Adds `clearWithParameters` and `getAllWithParameters` methods.
* Updates minimum supported SDK version to Flutter 3.3/Dart 2.18.

## 2.2.0

* Adds `getAllWithPrefix` and `clearWithPrefix` methods.

## 2.1.5

* Clarifies explanation of endorsement in README.
* Aligns Dart and Flutter SDK constraints.

## 2.1.4

* Updates links for the merge of flutter/plugins into flutter/packages.
* Updates minimum Flutter version to 3.0.

## 2.1.3

* Updates code for stricter lint checks.

## 2.1.2

* Updates code for stricter lint checks.
* Updates code for `no_leading_underscores_for_local_identifiers` lint.
* Updates minimum Flutter version to 2.10.

## 2.1.1

* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 2.1.0

* Deprecated `SharedPreferencesWindows.instance` in favor of `SharedPreferencesStorePlatform.instance`.

## 2.0.4

* Removes dependency on `meta`.

## 2.0.3

* Removed obsolete `pluginClass: none` from pubpsec.
* Fixes newly enabled analyzer options.

## 2.0.2

* Updated installation instructions in README.

## 2.0.1

* Add `implements` to pubspec.yaml.
* Add `registerWith` to the Dart main class.

## 2.0.0

* Migrate to null-safety.

## 0.0.2+3

* Remove 'ffi' dependency.

## 0.0.2+2

* Relax 'ffi' version constraint.

## 0.0.2+1

* Update Flutter SDK constraint.

## 0.0.2

* Update integration test examples to use `testWidgets` instead of `test`.

## 0.0.1+3

* Remove unused `test` dependency.

## 0.0.1+2

* Check in windows/ directory for example/

## 0.0.1+1

* Add iOS stub for compatibility with 1.17 and earlier.

## 0.0.1

* Initial release to support shared_preferences on Windows.
