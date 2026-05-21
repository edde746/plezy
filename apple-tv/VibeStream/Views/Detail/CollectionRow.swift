import SwiftUI

struct CollectionRow: View {
    let title: String
    let items: [PlexMetadata]
    let baseURL: String
    let token: String
    let onSelect: (PlexMetadata) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(items) { item in
                        MediaCard(
                            item: item,
                            baseURL: baseURL,
                            token: token,
                            width: 200,
                            onSelect: { onSelect(item) }
                        )
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 10)
            }
            .focusSection()
        }
    }
}
