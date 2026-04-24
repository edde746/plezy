// Pure-Swift tvOS implementation of the legacy plugins.flutter.io/path_provider
// channel. Replaces path_provider_foundation's FFI-based Dart impl, which
// requires the objective_c package's dylib and isn't linked on tvOS.

import Foundation

#if os(iOS) || os(tvOS)
  import Flutter

  public class PathProviderPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
      let channel = FlutterMethodChannel(
        name: "plugins.flutter.io/path_provider",
        binaryMessenger: registrar.messenger()
      )
      let instance = PathProviderPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      // On tvOS apps have no persistent writable storage; only the Caches
      // directory is writable (and can be evicted anytime). Docs, Support, and
      // Library all return dummy paths that fail on write. Route them into
      // Caches subdirectories so plugins expecting a writable path work.
      #if os(tvOS)
      let tvosCache = pathIn(.cachesDirectory)
      func tvosSubdir(_ name: String) -> String? {
        guard let base = tvosCache else { return nil }
        let p = (base as NSString).appendingPathComponent(name)
        try? FileManager.default.createDirectory(
          atPath: p, withIntermediateDirectories: true)
        return p
      }

      switch call.method {
      case "getTemporaryDirectory":
        result(tvosCache)
      case "getApplicationSupportDirectory":
        result(tvosSubdir("ApplicationSupport"))
      case "getApplicationDocumentsDirectory":
        result(tvosSubdir("Documents"))
      case "getApplicationCacheDirectory":
        result(tvosSubdir("AppCache"))
      case "getLibraryDirectory":
        result(tvosSubdir("Library"))
      case "getDownloadsDirectory":
        result(tvosSubdir("Downloads"))
      default:
        result(FlutterMethodNotImplemented)
      }
      #else
      switch call.method {
      case "getTemporaryDirectory":
        result(pathIn(.cachesDirectory))
      case "getApplicationSupportDirectory":
        let path = pathIn(.applicationSupportDirectory)
        if let p = path {
          try? FileManager.default.createDirectory(
            atPath: p, withIntermediateDirectories: true)
        }
        result(path)
      case "getApplicationDocumentsDirectory":
        result(pathIn(.documentDirectory))
      case "getApplicationCacheDirectory":
        let path = pathIn(.cachesDirectory)
        if let p = path {
          try? FileManager.default.createDirectory(
            atPath: p, withIntermediateDirectories: true)
        }
        result(path)
      case "getLibraryDirectory":
        result(pathIn(.libraryDirectory))
      case "getDownloadsDirectory":
        result(pathIn(.downloadsDirectory))
      default:
        result(FlutterMethodNotImplemented)
      }
      #endif
    }

    private func pathIn(_ directory: FileManager.SearchPathDirectory) -> String? {
      NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true).first
    }
  }
#endif
