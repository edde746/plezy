import Foundation

enum BuildInfo {
    static var stamp: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "v\(v) Mar08-1811"
    }
}
