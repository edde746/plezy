import Foundation

/// Tracks recently played items for quick replay from the idle screen
class RecentlyPlayedManager: ObservableObject {
    static let shared = RecentlyPlayedManager()

    private let storageKey = "recentlyPlayed"
    private let maxItems = 10

    @Published var items: [RecentItem] = []

    init() {
        load()
    }

    struct RecentItem: Identifiable, Codable, Equatable {
        let ratingKey: String
        let title: String
        let type: RecentItemType // album, artist, station
        let thumb: String?
        let timestamp: Date

        var id: String { ratingKey }

        // Synthesized Equatable compares all fields
    }

    enum RecentItemType: String, Codable {
        case album
        case artist
        case station
    }

    /// Record a recently played item
    func record(ratingKey: String, title: String, type: RecentItemType, thumb: String? = nil) {
        let item = RecentItem(ratingKey: ratingKey, title: title, type: type, thumb: thumb, timestamp: Date())

        // Remove existing entry with same ratingKey
        items.removeAll { $0.ratingKey == ratingKey }

        // Insert at front
        items.insert(item, at: 0)

        // Trim to max
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }

        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([RecentItem].self, from: data) else { return }
        items = saved
    }
}
