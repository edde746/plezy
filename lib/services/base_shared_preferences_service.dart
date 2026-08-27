import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

import '../utils/app_logger.dart';
import 'prefs_recovery.dart';
import 'sensitive_prefs.dart';

/// Base class for services that use SharedPreferences singleton pattern.
///
/// This class handles the boilerplate for singleton initialization and
/// SharedPreferences lifecycle management. Subclasses should:
/// 1. Create a private named constructor (e.g., SettingsService._())
/// 2. Implement their own getInstance() method that calls BaseSharedPreferencesService.initializeInstance()
/// 3. Optionally override onInit() for post-initialization setup
abstract class BaseSharedPreferencesService {
  static final Map<Type, BaseSharedPreferencesService> _instances = {};
  static final Map<Type, Future<BaseSharedPreferencesService>> _initializations = {};
  static int _resetGeneration = 0;
  // Single shared cache across all subclasses so writes from one service are
  // visible to reads from another without per-instance cache divergence.
  static Future<SharedPreferencesWithCache>? _cacheFuture;
  static Future<SharedPreferencesWithCache> Function() _cacheLoader = _loadSharedCache;

  late SharedPreferencesWithCache _cache;

  BaseSharedPreferencesService();

  SharedPreferencesWithCache get prefs => _cache;

  /// Initialize the preferences instance.
  ///
  /// This method handles:
  /// - Singleton instance management
  /// - One-time migration from the legacy SharedPreferences API to the
  ///   SharedPreferencesAsync-backed cache (idempotent across launches)
  /// - Calling onInit() hook for subclass-specific setup
  static Future<T> initializeInstance<T extends BaseSharedPreferencesService>(T Function() constructor) {
    final initialized = _instances[T];
    if (initialized != null) return Future<T>.value(initialized as T);

    final inFlight = _initializations[T];
    if (inFlight != null) return inFlight.then((instance) => instance as T);

    final generation = _resetGeneration;
    final initialization = () async {
      final instance = constructor();
      instance._cache = await sharedCache();
      await instance.onInit();
      if (generation != _resetGeneration) {
        return initializeInstance<T>(constructor);
      }
      _instances[T] = instance;
      return instance;
    }();
    _initializations[T] = initialization;
    return initialization.whenComplete(() {
      if (identical(_initializations[T], initialization)) {
        _initializations.remove(T);
      }
    });
  }

  /// Shared preferences cache used app-wide. Runs the legacy → async
  /// migration on first call; subsequent calls return the same future.
  /// Use this from services that don't extend [BaseSharedPreferencesService].
  static Future<SharedPreferencesWithCache> sharedCache() {
    final cached = _cacheFuture;
    if (cached != null) return cached;

    late final Future<SharedPreferencesWithCache> loading;
    loading = _cacheLoader().then(
      (cache) => cache,
      onError: (Object error, StackTrace stackTrace) {
        // Do not poison every later startup with one transient plugin/storage
        // failure. Identity keeps a superseding/reset load intact while all
        // concurrent callers continue to share this attempt.
        if (identical(_cacheFuture, loading)) _cacheFuture = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _cacheFuture = loading;
    return loading;
  }

  static Future<SharedPreferencesWithCache> _loadSharedCache() async {
    // Validate before the plugin reads anything: the desktop backends memoise
    // the document they parse and never re-read it, so a store rejected only
    // after the fact could not be repaired in-process (#1732).
    await PrefsRecovery.assertStoreReadable();
    try {
      return await _openSharedCache();
    } catch (error, stackTrace) {
      // The preflight accepted this document and the plugin still rejected it.
      // Classify by re-reading the bytes, never by the error's type: the
      // desktop backends surface a UTF-8 decode failure as a
      // `FileSystemException`, which is indistinguishable from a denied or
      // locked file, and a permission error must never be offered a
      // destructive repair. A null result means the document on disk is fine,
      // so whatever went wrong keeps its own type and its own path.
      final damage = await PrefsRecovery.describeCurrentStoreDamage(reopenSafe: false);
      if (damage == null) rethrow;
      // The plugin has now cached something we cannot reason about. Repair can
      // still quarantine the file, but the process has to restart afterwards.
      appLogger.e('Preference store could not be parsed', error: error, stackTrace: stackTrace);
      throw damage;
    }
  }

  static Future<SharedPreferencesWithCache> _openSharedCache() async {
    final legacy = await SharedPreferences.getInstance();
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: legacy,
      sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
      migrationCompletedKey: 'plezy_legacy_prefs_migrated_v1',
    );
    return SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  }

  /// Quarantines an *unparseable* store, opens a fresh one and reseeds every
  /// credential that could be salvaged.
  ///
  /// Never call this without an explicit user decision: it resets settings,
  /// and any credential that could not be salvaged is gone. The salvaged vault
  /// key is written before this future completes, which is what makes the
  /// reseed safe — `CredentialVault` memoises the first key it sees, so a
  /// single read landing before the seed would generate a replacement and
  /// permanently orphan every token stored in the database. Nothing can read
  /// preferences until [sharedCache] resolves, so doing the work here closes
  /// that window entirely.
  ///
  /// Only valid for [CorruptPreferenceStoreException]. The desktop plugins
  /// memoise the parsed document in a private `_cachedPreferences` map and
  /// never re-read it without an explicit reload; that map is only empty here
  /// because the parse threw before it could be populated. Use
  /// [dropUnreadableCredential] for a store that parsed but holds one
  /// unreadable value — quarantining that one would reopen onto the stale
  /// in-memory map and write the bad value straight back.
  static Future<PrefsRepairOutcome> repairCorruptStore({bool reopenSafe = true}) async {
    final (:salvaged, :backupPath, :shape) = await PrefsRecovery.quarantine();
    // Conservative by construction: the warning is dropped only for bytes
    // proven to contain nothing. What the salvage recovered cannot stand in
    // for that — a store truncated mid-value matches no entry at all while
    // still holding most of a vault key in plaintext.
    final backupHoldsCredentials = !(shape?.allZero ?? false);

    _resetGeneration++;
    _initializations.clear();
    _instances.clear();

    if (!reopenSafe) {
      // The plugin memoised the bad document before it threw, so reopening
      // would hand that copy back and the first write would persist it over
      // the repaired file. Write the salvage straight to disk for the next
      // process instead, and leave this one's store closed.
      //
      // Nothing may write a preference before that restart or the plugin's
      // stale map would overwrite the seed; the caller keeps the app on the
      // failure screen precisely so nothing does.
      final seeded = await PrefsRecovery.seedStore(salvaged);
      appLogger.w('Preference store quarantined; a restart is required before it can be reopened');
      return PrefsRepairOutcome(
        backupPath: backupPath,
        backupHoldsCredentials: backupHoldsCredentials,
        vaultKeySalvaged: seeded && salvaged.vaultKey != null,
        sessionsLost: seeded ? salvaged.losses : salvaged.losses + salvaged.sessions.length,
        requiresRestart: true,
      );
    }

    _cacheFuture = null;
    late final Future<SharedPreferencesWithCache> repaired;
    repaired = _cacheLoader()
        .then((cache) async {
          final vaultKey = salvaged.vaultKey;
          if (vaultKey != null) await cache.setString(credentialVaultKeyPref, vaultKey);
          for (final entry in salvaged.sessions.entries) {
            await cache.setString(entry.key, entry.value);
          }
          return cache;
        })
        .onError<Object>((error, stackTrace) {
          // The same self-healing reset `sharedCache` installs, for the same
          // reason. Without it a reopen that fails *after* the store was
          // already quarantined would leave a permanently rejected future in
          // `_cacheFuture`, and every later retry would replay that stale error
          // for the rest of the process — with the on-disk cause already gone.
          if (identical(_cacheFuture, repaired)) _cacheFuture = null;
          Error.throwWithStackTrace(error, stackTrace);
        });
    _cacheFuture = repaired;
    await repaired;

    return PrefsRepairOutcome(
      backupPath: backupPath,
      backupHoldsCredentials: backupHoldsCredentials,
      vaultKeySalvaged: salvaged.vaultKey != null,
      sessionsLost: salvaged.losses,
    );
  }

  /// Removes one credential preference whose stored type is unreadable.
  ///
  /// The store itself parsed here, so the plugin's `_cachedPreferences` map is
  /// already populated and a quarantine-and-reopen would hand back that stale
  /// map and persist the bad value again. Delete through the live cache
  /// instead: that updates both the in-memory map and the file, and leaves
  /// every other credential in place.
  ///
  /// The file is *copied* first, not moved — it is still the app's live store,
  /// and the copy is the only record of the pre-repair state.
  static Future<PrefsRepairOutcome> dropUnreadableCredential(String key) async {
    final backupPath = await PrefsRecovery.backupStore();

    final cache = await sharedCache();
    await cache.remove(key);

    // Force `onInit` to run again against the repaired store; the cache future
    // stays as-is because the store was never reopened.
    _resetGeneration++;
    _initializations.clear();
    _instances.clear();

    appLogger.w('Removed unreadable credential preference "$key"');
    return PrefsRepairOutcome(
      backupPath: backupPath,
      // The vault key survives unless it was the unreadable value itself.
      vaultKeySalvaged: key != credentialVaultKeyPref,
      sessionsLost: key == credentialVaultKeyPref ? 0 : 1,
    );
  }

  @visibleForTesting
  static void setCacheLoaderForTesting(Future<SharedPreferencesWithCache> Function() loader) {
    _cacheFuture = null;
    _cacheLoader = loader;
  }

  /// Drop all cached singleton instances and the shared cache future so the
  /// next `getInstance()` call rebuilds against the current
  /// `SharedPreferences.setMockInitialValues(...)`. Test-only.
  @visibleForTesting
  static void resetForTesting() {
    _resetGeneration++;
    _initializations.clear();
    _instances.clear();
    _cacheFuture = null;
    _cacheLoader = _loadSharedCache;
  }

  /// Reads a stored value, tolerating one whose type no longer matches the
  /// declaration.
  ///
  /// `SharedPreferencesWithCache.getX` is an `as T?` cast, so a value written
  /// by an older build, hand-edited, or partially recovered throws `TypeError`
  /// rather than returning null. A value we cannot read is indistinguishable
  /// from one that was never written, so drop the key and fall back to the
  /// declared default instead of letting it propagate — before #1732 a single
  /// mistyped preference could fail the entire startup gate.
  ///
  /// Credential slots are exempt: silently dropping one would sign the user
  /// out with no explanation. Those raise
  /// [UnreadableSensitivePreferenceException], which the startup gate
  /// classifies as repairable so the user gets the same consented repair as an
  /// unparseable store.
  T? _readTolerant<T>(String key, T? Function() read) => readPreferenceTolerantly(_cache, key, read);

  /// Nullable reads routed through [readPreferenceTolerantly]. Use these
  /// instead of `prefs.getX(...)` wherever a mistyped stored value must not
  /// throw — which is everywhere except a call site that deliberately probes
  /// two types to migrate between them.
  String? readNullableString(String key) => readTolerantString(_cache, key);
  bool? readNullableBool(String key) => _readTolerant(key, () => _cache.getBool(key));
  int? readNullableInt(String key) => _readTolerant(key, () => _cache.getInt(key));

  /// Typed read helpers — return the stored value or [defaultValue] when missing.
  bool readBool(String key, {bool defaultValue = false}) =>
      _readTolerant(key, () => _cache.getBool(key)) ?? defaultValue;
  int readInt(String key, {int defaultValue = 0}) => _readTolerant(key, () => _cache.getInt(key)) ?? defaultValue;
  double readDouble(String key, {double defaultValue = 0.0}) =>
      _readTolerant(key, () => _cache.getDouble(key)) ?? defaultValue;
  String readString(String key, {String defaultValue = ''}) => readNullableString(key) ?? defaultValue;
  List<String> readStringList(String key, {List<String> defaultValue = const []}) =>
      _readTolerant(key, () => _cache.getStringList(key)) ?? defaultValue;

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
  final Map<String, Pref<dynamic>> _listenablePrefs = {};

  ValueNotifier<T> listenable<T>(Pref<T> pref) => pref.bindListenable(this);

  /// Type-erased [Listenable] accessor for combining multiple prefs into a
  /// `Listenable.merge`. Dispatches through [Pref.bindListenable] so the
  /// underlying notifier is created with the pref's concrete type.
  Listenable listenableOf(Pref<Object?> pref) => pref.bindListenable(this);

  /// Push current stored values into every active listenable. Used after bulk
  /// operations that bypass [write] (reset/import/direct SharedPreferences writes).
  void refreshActiveListenables() {
    for (final pref in _listenablePrefs.values.toList(growable: false)) {
      pref.refreshListenable(this);
    }
  }

  /// Hook for subclass-specific initialization after SharedPreferences is ready.
  ///
  /// Override this method to perform any setup that requires access to
  /// SharedPreferences (e.g., registering values with other services).
  Future<void> onInit() async {}
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

  /// Get-or-create the [ValueNotifier] for this pref. Virtual-dispatched via
  /// the runtime [Pref] subclass so the notifier carries the concrete `T`,
  /// even when called through a `Pref<Object?>` reference (used by
  /// [BaseSharedPreferencesService.listenableOf]).
  ValueNotifier<T> bindListenable(BaseSharedPreferencesService svc) {
    final existing = svc._listenables[key];
    svc._listenablePrefs[key] = this;
    if (existing != null) return existing as ValueNotifier<T>;
    final notifier = ValueNotifier<T>(readFrom(svc));
    svc._listenables[key] = notifier;
    return notifier;
  }

  /// If a listenable exists for this key, push the current stored value into
  /// it. Used after bulk operations (reset, import) that bypass [writeTo].
  /// No-op when no listener has been registered.
  void refreshListenable(BaseSharedPreferencesService svc) {
    final n = svc._listenables[key];
    if (n != null) (n as ValueNotifier<T>).value = readFrom(svc);
  }
}

class BoolPref extends Pref<bool> {
  final bool defaultValue;

  /// Lazily-resolved default for values that depend on state unavailable at
  /// static-init time (e.g. async TV detection). Wins over [defaultValue].
  final bool Function()? defaultValueProvider;
  final void Function(bool)? onWrite;
  const BoolPref(super.key, {this.defaultValue = false, this.defaultValueProvider, this.onWrite});
  @override
  bool readFrom(BaseSharedPreferencesService svc) =>
      svc.readBool(key, defaultValue: defaultValueProvider?.call() ?? defaultValue);
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
  String? readFrom(BaseSharedPreferencesService svc) => svc.readNullableString(key);
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

/// Stores an enum by its [Enum.name]; falls back to the default when the
/// stored string doesn't match any value in [values].
///
/// Exactly one of [defaultValue] / [defaultValueProvider] must be given; the
/// provider form resolves at read time, for defaults that depend on state
/// unavailable at static-init time (e.g. async TV detection).
class EnumPref<T extends Enum> extends Pref<T> {
  final List<T> values;
  final T? defaultValue;
  final T Function()? defaultValueProvider;
  const EnumPref(super.key, {required this.values, this.defaultValue, this.defaultValueProvider})
    : assert((defaultValue != null) != (defaultValueProvider != null));
  T get _default => defaultValueProvider?.call() ?? defaultValue!;
  @override
  T readFrom(BaseSharedPreferencesService svc) {
    final stored = svc.readNullableString(key);
    if (stored == null) return _default;
    return values.firstWhere((v) => v.name == stored, orElse: () => _default);
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, T value) => svc.writeString(key, value.name);
}

/// Like [EnumPref] but null = key absent. An absent key or a stored string
/// that no longer matches any value in [values] reads as null; writing null
/// removes the key.
class NullableEnumPref<T extends Enum> extends Pref<T?> {
  final List<T> values;
  const NullableEnumPref(super.key, {required this.values});
  @override
  T? readFrom(BaseSharedPreferencesService svc) {
    final stored = svc.readNullableString(key);
    if (stored == null) return null;
    for (final v in values) {
      if (v.name == stored) return v;
    }
    return null;
  }

  @override
  Future<void> writeTo(BaseSharedPreferencesService svc, T? value) async {
    if (value == null) {
      await svc.prefs.remove(key);
    } else {
      await svc.writeString(key, value.name);
    }
  }
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
    final s = svc.readNullableString(key);
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

/// Reads a preference, tolerating a stored value whose type no longer matches
/// the declaration.
///
/// `SharedPreferencesWithCache.getX` is an `as T?` cast, so a value written by
/// an older build, hand-edited, or partially recovered throws `TypeError`
/// rather than returning null. A value we cannot read is indistinguishable
/// from one that was never written, so drop the key and fall back to the
/// declared default instead of letting it propagate — before #1732 a single
/// mistyped preference could fail the entire startup gate.
///
/// Credential slots are exempt: silently dropping one would sign the user out
/// with no explanation. Those raise [UnreadableSensitivePreferenceException],
/// which the startup gate classifies as repairable so the user gets the same
/// consented repair as an unparseable store.
///
/// Takes the cache directly so the credential stores — which hold a
/// [SharedPreferencesWithCache] rather than a [BaseSharedPreferencesService] —
/// get the same treatment as the settings layer.
T? readPreferenceTolerantly<T>(SharedPreferencesWithCache cache, String key, T? Function() read) {
  try {
    return read();
  } on TypeError catch (error, stackTrace) {
    if (isSensitivePrefKey(key)) {
      appLogger.e('Credential preference "$key" is unreadable', error: error, stackTrace: stackTrace);
      Error.throwWithStackTrace(UnreadableSensitivePreferenceException(key, error), stackTrace);
    }
    appLogger.w('Dropping preference "$key" with an unreadable stored type', error: error, stackTrace: stackTrace);
    unawaited(
      cache.remove(key).catchError((Object e, StackTrace s) {
        appLogger.d('Could not drop unreadable preference "$key"', error: e, stackTrace: s);
      }),
    );
    return null;
  }
}

/// Tolerant string read for a bare [SharedPreferencesWithCache].
String? readTolerantString(SharedPreferencesWithCache cache, String key) =>
    readPreferenceTolerantly(cache, key, () => cache.getString(key));
