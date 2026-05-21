import SwiftUI

struct InlineTrackPicker: View {
    let title: String
    let tracks: [TrackItem]
    let highlightedIndex: Int

    @Namespace private var glassNamespace

    struct TrackItem: Identifiable {
        let id: Int
        let label: String
        let detail: String?
        let isActive: Bool
        let isForced: Bool
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            trackRow(track, isHighlighted: index == highlightedIndex)
                                .id(track.id)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    scrollToHighlighted(proxy: proxy, animated: false)
                }
                .onChange(of: highlightedIndex) { _, _ in
                    scrollToHighlighted(proxy: proxy, animated: true)
                }
            }
        }
        .padding(.bottom, 12)
        .frame(width: 420)
        .frame(maxHeight: 380)
        .glassMaterial(in: RoundedRectangle(cornerRadius: 16), effectID: "inline-picker", namespace: glassNamespace)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func scrollToHighlighted(proxy: ScrollViewProxy, animated: Bool) {
        guard highlightedIndex < tracks.count else { return }
        let id = tracks[highlightedIndex].id
        if animated {
            withAnimation(.easeInOut(duration: 0.15)) {
                proxy.scrollTo(id, anchor: .center)
            }
        } else {
            proxy.scrollTo(id, anchor: .center)
        }
    }

    private func trackRow(_ track: TrackItem, isHighlighted: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(track.label)
                        .font(.body)
                        .foregroundStyle(.white)
                    if track.isForced {
                        Text("Forced")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                if let detail = track.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
            if track.isActive {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHighlighted ? .white.opacity(0.25) : .clear)
                .padding(.horizontal, 8)
        )
    }
}
