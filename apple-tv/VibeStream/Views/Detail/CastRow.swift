import SwiftUI

private struct CastMemberCard: View {
    let role: PlexRole
    let token: String
    let baseURL: String
    let isFocused: Bool
    let iconSize: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            if let thumb = role.thumb {
                PlexImage(
                    path: thumb,
                    token: token,
                    baseURL: baseURL,
                    width: iconSize,
                    aspectRatio: 1
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(.white, lineWidth: isFocused ? 4 : 0)
                )
            } else {
                Circle()
                    .fill(.quaternary)
                    .frame(width: iconSize, height: iconSize)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                    }
                    .overlay(
                        Circle()
                            .strokeBorder(.white, lineWidth: isFocused ? 4 : 0)
                    )
                    .accessibilityHidden(true)
            }

            Text(role.displayName)
                .font(.caption)
                .lineLimit(1)
                .frame(width: iconSize)

            if let roleName = role.displayRole {
                Text(roleName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: iconSize)
            }
        }
        .scaleEffect(isFocused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(role.displayRole != nil ? "\(role.displayName) as \(role.displayRole!)" : role.displayName)
    }
}

struct CastRow: View {
    let roles: [PlexRole]
    let baseURL: String
    let token: String
    @Binding var lastFocusedIndex: Int?
    var iconSize: CGFloat = 120
    var onSelect: ((PlexRole) -> Void)? = nil

    @FocusState private var focusedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cast & Crew")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(Array(roles.enumerated()), id: \.element.id) { index, role in
                        CastMemberCard(
                            role: role,
                            token: token,
                            baseURL: baseURL,
                            isFocused: focusedIndex == index,
                            iconSize: iconSize
                        )
                        .focusable()
                        .focused($focusedIndex, equals: index)
                        .onPlayPauseCommand { onSelect?(role) }
                        .onTapGesture { onSelect?(role) }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
            }
            .defaultFocus($focusedIndex, lastFocusedIndex ?? 0)
            .focusSection()
            .onChange(of: focusedIndex) { _, newValue in
                if let newValue { lastFocusedIndex = newValue }
            }
        }
    }
}
