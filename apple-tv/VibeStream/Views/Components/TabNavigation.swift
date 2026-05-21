import SwiftUI

struct TabNavigation<Content: View>: View {
    let tabs: [String]
    @Binding var selectedIndex: Int
    let content: (Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, title in
                        Button {
                            selectedIndex = index
                        } label: {
                            Text(title)
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    selectedIndex == index ? Color.accentColor.opacity(0.2) : .clear
                                )
                                .clipShape(Capsule())
                        }
                        .accessibilityAddTraits(selectedIndex == index ? .isSelected : [])
                    }
                }
                .focusSection()
                .padding(.horizontal, 50)
            }
            .padding(.vertical, 10)

            // Content
            content(selectedIndex)
        }
    }
}
