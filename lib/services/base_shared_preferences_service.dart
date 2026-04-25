import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

/// Base class for services that use SharedPreferences singleton pattern.
///
/// This class handles the boilerplate for singleton initialization and
/// SharedPreferences lifecycle management. Subclasses should:
/// 1. Create a private named constructor (e.g., SettingsService._())
/// 2. Implement their own getInstance() method that calls BaseSharedPreferencesService.initializeInstance()
/// 3. Optionally override onInit() for post-initialization setup
abstract class BaseSharedPreferencesService {
  static final Map<Type, BaseSharedPreferencesService> _instances = {};
  // Single shared cache across all subclasses so writes from one service are
  // visible to reads from another without per-instance cache divergence.
  static Future<SharedPreferencesWithCache>? _cacheFuture;

  late SharedPreferencesWithCache _cache;

  /// Protected constructor for subclasses
  BaseSharedPreferencesService();

  /// Access to the underlying preferences cache.
  SharedPreferencesWithCache get prefs => _cache;

  /// Initialize the preferences instance.
  ///
  /// This method handles:
  /// - Singleton instance management
  /// - One-time migration from the legacy SharedPreferences API to the
  ///   SharedPreferencesAsync-backed cache (idempotent across launches)
  /// - Calling onInit() hook for subclass-specific setup
  static Future<T> initializeInstance<T extends BaseSharedPreferencesService>(T Function() constructor) async {
    if (_instances[T] == null) {
      final instance = constructor();
      _instances[T] = instance;
      instance._cache = await _ensureCache();
      await instance.onInit();
    }
    return _instances[T] as T;
  }

  static Future<SharedPreferencesWithCache> _ensureCache() {
    return _cacheFuture ??= () async {
      final legacy = await SharedPreferences.getInstance();
      await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
        legacySharedPreferencesInstance: legacy,
        sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
        migrationCompletedKey: 'plezy_legacy_prefs_migrated_v1',
      );
      return SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    }();
  }

  /// Typed read helpers — return the stored value or [defaultValue] when missing.
  bool readBool(String key, {bool defaultValue = false}) => _cache.getBool(key) ?? defaultValue;
  int readInt(String key, {int defaultValue = 0}) => _cache.getInt(key) ?? defaultValue;
  double readDouble(String key, {double defaultValue = 0.0}) => _cache.getDouble(key) ?? defaultValue;
  String readString(String key, {String defaultValue = ''}) => _cache.getString(key) ?? defaultValue;
  List<String> readStringList(String key, {List<String> defaultValue = const []}) =>
      _cache.getStringList(key) ?? defaultValue;

  /// Typed write helpers — symmetric with the read helpers above; use these
  /// instead of `prefs.setX(...)` so call sites stay terse.
  Future<void> writeBool(String key, bool value) => _cache.setBool(key, value);
  Future<void> writeInt(String key, int value) => _cache.setInt(key, value);
  Future<void> writeDouble(String key, double value) => _cache.setDouble(key, value);
  Future<void> writeString(String key, String value) => _cache.setString(key, value);
  Future<void> writeStringList(String key, List<String> value) => _cache.setStringList(key, value);

  /// Decode a JSON string to a Map with error handling.
  ///
  /// If [legacyStringOk] is true and the value is a plain string (not valid
  /// JSON), returns `{'key': jsonString, 'descending': false}` for legacy
  /// library sort compatibility.
  Map<String, dynamic> decodeJsonStringToMap(String jsonString, {bool legacyStringOk = false}) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (legacyStringOk) {
        return {'key': jsonString, 'descending': false};
      }
      return {};
    }
  }

  /// Read a value typed by [pref]; falls back to its `defaultValue`.
  T read<T>(Pref<T> pref) => pref.readFrom(this);

  /// Write a value typed by [pref]. Pushes the post-transform value into any
  /// listenable previously vended for this key so widgets rebuild automatically.
  Future<void> write<T>(Pref<T> pref, T value) async {
    await pref.writeTo(this, value);
    final n = _listenables[pref.key];
    if (n != null) (n as ValueNotifier<T>).value = read(pref);
  }

  /// Lazy per-key [ValueNotifier]. Use with [ValueListenableBuilder] to rebuild
  /// when the value changes. Notifiers live for the app lifetime — do not
  /// dispose them.
  final Map<String, ValueNotifier<dynamic>> _listenables = {};

  ValueNotifier<T> listenable<T>(Pref<T> pref) {
    return (_listenables[pref.key] ??= ValueNotifier<T>(read(pref))) as ValueNotifier<T>;
  }

  /// Hook for subclass-specific initialization after SharedPreferences is ready.
  ///
  /// Override this method to perform any setup that requires access to
  /// SharedPreferences (e.g., registering values with other services).
  Future<void> onInit() async {
    // Default implementation does nothing
  }
}

/// Typed preference declaration. Pair with [BaseSharedPreferencesService.read]
/// and [BaseSharedPreferencesService.write] to remove per-setting `?? default`
/// boilerplate.
abstract class Pref<T> {
  final String key;
  const Pref(this.key);

  /// Implementation hook — call [BaseSharedPreferencesService.read] instead.
  T readFrom(BaseSharedPreferencesService svc);

  /// Implementation hook — call [BaseSharedPreferencesService.write] instead.
  Future<void> writeTo(BaseSharedPreferencesService svc, T value);
}

class BoolPref extends Pref<bool> {
  final bool defaultValue;
  final void Function(bool)? onWrite;
  const BoolPref(super.key, {this.defaultValue = false, this.onWrite});
  @override
  bool readFrom(BaseSharedPreferencesService svc) => svc.readBool(key, defaultValue: defaultValue);
  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, bool value) async {
    await svc.writeBool(key, value);
    onWrite?.call(value);
  }
}

class IntPref extends Pref<int> {
  final int defaultValue;
  final int Function(int)? transform;
  const IntPref(super.key, {this.defaultValue = 0, this.transform});
  @override
  int readFrom(BaseSharedPreferencesService svc) {
    final raw = svc.readInt(key, defaultValue: defaultValue);
    return transform == null ? raw : transform!(raw);
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, int value) =>
      svc.writeInt(key, transform == null ? value : transform!(value));
}

class DoublePref extends Pref<double> {
  final double defaultValue;
  final double Function(double)? transform;
  const DoublePref(super.key, {this.defaultValue = 0.0, this.transform});
  @override
  double readFrom(BaseSharedPreferencesService svc) {
    final raw = svc.readDouble(key, defaultValue: defaultValue);
    return transform == null ? raw : transform!(raw);
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, double value) =>
      svc.writeDouble(key, transform == null ? value : transform!(value));
}

class StringPref extends Pref<String> {
  final String defaultValue;
  const StringPref(super.key, {this.defaultValue = ''});
  @override
  String readFrom(BaseSharedPreferencesService svc) => svc.readString(key, defaultValue: defaultValue);
  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, String value) => svc.writeString(key, value);
}

/// Like [StringPref] but null = key absent. [transform] runs on write; if it
/// returns null the key is removed.
class NullableStringPref extends Pref<String?> {
  final String? Function(String?)? transform;
  const NullableStringPref(super.key, {this.transform});
  @override
  String? readFrom(BaseSharedPreferencesService svc) => svc.prefs.getString(key);
  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, String? value) async {
    final normalized = transform == null ? value : transform!(value);
    if (normalized == null) {
      await svc.prefs.remove(key);
    } else {
      await svc.writeString(key, normalized);
    }
  }
}

class StringListPref extends Pref<List<String>> {
  final List<String> defaultValue;
  const StringListPref(super.key, {this.defaultValue = const []});
  @override
  List<String> readFrom(BaseSharedPreferencesService svc) => svc.readStringList(key, defaultValue: defaultValue);
  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, List<String> value) => svc.writeStringList(key, value);
}

/// Stores an enum by its [Enum.name]; falls back to [defaultValue] when the
/// stored string doesn't match any value in [values].
class EnumPref<T extends Enum> extends Pref<T> {
  final List<T> values;
  final T defaultValue;
  const EnumPref(super.key, {required this.values, required this.defaultValue});
  @override
  T readFrom(BaseSharedPreferencesService svc) {
    final stored = svc.prefs.getString(key);
    if (stored == null) return defaultValue;
    return values.firstWhere((v) => v.name == stored, orElse: () => defaultValue);
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, T value) => svc.writeString(key, value.name);
}

/// Stores an arbitrary value as a JSON-encoded string. Decode failures and
/// missing keys both fall back to [defaultValue].
class JsonPref<T> extends Pref<T> {
  final T defaultValue;
  final String Function(T) encode;
  final T Function(dynamic) decode;
  JsonPref(super.key, {required this.defaultValue, required this.encode, required this.decode});

  @override
  T readFrom(BaseSharedPreferencesService svc) {
    final s = svc.prefs.getString(key);
    if (s == null) return defaultValue;
    try {
      return decode(json.decode(s));
    } catch (_) {
      return defaultValue;
    }
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, T value) => svc.writeString(key, encode(value));
}
