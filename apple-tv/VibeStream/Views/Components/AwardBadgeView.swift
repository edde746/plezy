import SwiftUI

struct AwardBadgeView: View {
    let badge: AwardBadge
    var contentYear: Int? = nil

    private var displayText: String {
        if let year = badge.ceremonyYear(from: contentYear) {
            return "\(year) \(badge.text)"
        }
        return badge.text
    }

    var body: some View {
        Text(displayText)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(.white.opacity(0.2))
                    .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1))
            )
    }
}
