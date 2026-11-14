import Foundation

enum BuildInfo {
  static var stamp: String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String ?? "?"
    let build = info?["CFBundleVersion"] as? String ?? "?"
    return "v\(version) (\(build))"
  }
}
