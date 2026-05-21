import SwiftUI

struct SidebarHeaderView: View {
    @Environment(AppState.self) private var appState
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: currentTime)
    }

    var body: some View {
        HStack {
            // User photo + name
            HStack(spacing: 10) {
                if let thumb = appState.activeUser?.thumb, let url = URL(string: thumb) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundStyle(.secondary)
                }

                Text(appState.activeUser?.displayName ?? "User")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            // Current time
            Text(timeString)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.5))
        }
        .onReceive(timer) { time in
            currentTime = time
        }
    }
}
