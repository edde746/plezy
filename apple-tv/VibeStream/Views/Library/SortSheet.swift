import SwiftUI

struct SortSheet: View {
    let sorts: [PlexSort]
    let activeSort: String?
    let isDescending: Bool
    var onApply: (String, Bool) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Sort By")
                .font(.headline)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(sorts.enumerated()), id: \.element.id) { index, sort in
                        if index > 0 {
                            Divider().opacity(0.3)
                        }
                        SortSheetRow(action: {
                            if activeSort == sort.key {
                                onApply(sort.key, !isDescending)
                            } else {
                                onApply(sort.key, sort.isDefaultDescending)
                            }
                        }) {
                            HStack {
                                Text(sort.title)
                                Spacer()
                                if activeSort == sort.key {
                                    Image(systemName: isDescending ? "arrow.down" : "arrow.up")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(40)
    }
}

private struct SortSheetRow<Content: View>: View {
    var action: () -> Void
    @ViewBuilder var content: Content

    @FocusState private var isFocused: Bool

    var body: some View {
        content
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isFocused ? 0.2 : 0))
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .focusable()
            .focused($isFocused)
            .onTapGesture { action() }
            .onPlayPauseCommand { action() }
    }
}
