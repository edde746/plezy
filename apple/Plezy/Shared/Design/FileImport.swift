import Foundation

/// The largest file an import reads (the player's shaders, as Android's `AndroidFiles.MAX_IMPORT_BYTES`); a bigger
/// one is refused as unreadable before it fills memory, as a video picked by mistake and read whole would.
private let maxImportBytes = 32 << 20

/// The text of a file picked in the open dialog to import, read off the main thread; nil when it can't be read, is
/// over `maxImportBytes` or isn't UTF-8.
func importedText(_ url: URL) async -> String? {
    guard let data = await importedData(url) else { return nil }
    return String(data: data, encoding: .utf8)
}

/// The bytes of a file picked in the open dialog (an artwork upload), read off the main thread; nil when it can't be
/// read or is over `maxImportBytes` (read no further than a byte past them).
func importedData(_ url: URL) async -> Data? {
    await Task.detached(priority: .userInitiated) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let file = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? file.close() }
        guard let data = try? file.read(upToCount: maxImportBytes + 1) ?? Data(), data.count <= maxImportBytes else { return nil }
        return data
    }.value
}
