import Foundation

struct AwardBadge: Codable, Equatable {
    let text: String
    let tier: Int

    /// Computes the ceremony year from the content's release year.
    /// Film awards (Oscar, Globe, BAFTA) happen the year after release.
    /// TV awards (Emmy) and festivals (Cannes) happen the same year.
    func ceremonyYear(from contentYear: Int?) -> Int? {
        guard let contentYear else { return nil }
        switch tier {
        case 1, 2, 5, 6, 7: // Oscar, Golden Globe, BAFTA
            return contentYear + 1
        case 3, 4: // Emmy
            return contentYear
        case 8: // Cannes
            return contentYear
        default:
            return nil
        }
    }
}
