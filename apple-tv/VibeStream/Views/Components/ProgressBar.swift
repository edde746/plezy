import SwiftUI

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.clear)
                    .glassMaterial(in: Capsule())

                Capsule()
                    .fill(.tint)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Watched \(Int(progress * 100)) percent")
        .accessibilityValue("\(Int(progress * 100))%")
    }
}
