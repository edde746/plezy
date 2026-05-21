import Foundation

enum APIKeys {
    static var tmdbAPIKey: String {
        // Read from Info.plist if available (set via build configuration)
        if let key = Bundle.main.infoDictionary?["TMDB_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        // Obfuscated fallback (XOR with 0x42)
        let encoded: [UInt8] = [
            0x27, 0x77, 0x20, 0x20, 0x7B, 0x20, 0x24, 0x24,
            0x71, 0x7A, 0x21, 0x7B, 0x74, 0x73, 0x74, 0x73,
            0x72, 0x23, 0x77, 0x21, 0x73, 0x21, 0x70, 0x7A,
            0x77, 0x75, 0x7B, 0x26, 0x23, 0x70, 0x26, 0x24
        ]
        let xorKey: UInt8 = 0x42
        return String(bytes: encoded.map { $0 ^ xorKey }, encoding: .utf8) ?? ""
    }

    static var omdbAPIKey: String {
        if let key = Bundle.main.infoDictionary?["OMDB_API_KEY"] as? String, !key.isEmpty {
            return key
        }
        // Obfuscated fallback (XOR with 0x42)
        let encoded: [UInt8] = [
            0x24, 0x75, 0x73, 0x7a, 0x24, 0x74, 0x71, 0x75
        ]
        let xorKey: UInt8 = 0x42
        return String(bytes: encoded.map { $0 ^ xorKey }, encoding: .utf8) ?? ""
    }
}
