import SwiftUI

struct ContinueWatchingRow: View {
    let items: [PlexMetadata]
    let baseURL: String
    let token: String
    var onItemSelected: ((PlexMetadata) -> Void)?
    var onItemLongPressed: ((PlexMetadata) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Continue Watching")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(items) { item in
                        ContinueWatchingCard(
                            item: item,
                            baseURL: baseURL,
                            token: token,
                            onSelect: { onItemSelected?(item) },
                            onLongPress: { onItemLongPressed?(item) }
                        )
                    }
                }
                .focusSection()
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
            }
        }
    }
}
