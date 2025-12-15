import 'package:shared_preferences/shared_preferences.dart';

/// Base class for services that use SharedPreferences singleton pattern.
///
/// This class handles the boilerplate for singleton initialization and
/// SharedPreferences lifecycle management. Subclasses should:
/// 1. Create a private named constructor (e.g., SettingsService._())
/// 2. Implement their own getInstance() method that calls BaseSharedPreferencesService.initializeInstance()
/// 3. Optionally override onInit() for post-initialization setup
abstract class BaseSharedPreferencesService {
  static final Map<Type, BaseSharedPreferencesService> _instances = {};
  late SharedPreferences _prefs;

  /// Protected constructor for subclasses
  BaseSharedPreferencesService();

  /// Access to SharedPreferences instance
  SharedPreferences get prefs => _prefs;

  /// Initialize the SharedPreferences instance
  ///
  /// This method handles:
  /// - Singleton instance management
  /// - SharedPreferences initialization
  /// - Calling onInit() hook for subclass-specific setup
  static Future<T> initializeInstance<T extends BaseSharedPreferencesService>(T Function() constructor) async {
    if (_instances[T] == null) {
      final instance = constructor();
      _instances[T] = instance;
      instance._prefs = await SharedPreferences.getInstance();
      await instance.onInit();
    }
    return _instances[T] as T;
  }

  /// Hook for subclass-specific initialization after SharedPreferences is ready.
  ///
  /// Override this method to perform any setup that requires access to
  /// SharedPreferences (e.g., registering values with other services).
  Future<void> onInit() async {
    // Default implementation does nothing
  }
}
