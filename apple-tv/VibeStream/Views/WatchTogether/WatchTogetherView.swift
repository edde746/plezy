import SwiftUI

struct WatchTogetherView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = WatchTogetherViewModel()

    var body: some View {
        NavigationStack {
            if viewModel.isInSession {
                activeSessionView
            } else {
                createJoinView
            }
        }
    }

    @ViewBuilder
    private var createJoinView: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Watch Together")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Watch in sync with friends")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Create session
            Button {
                Task {
                    let displayName = appState.activeUser?.displayName ?? "Apple TV"
                    let peerId = "wt-\(appState.clientIdentifier.prefix(8))"
                    await viewModel.createSession(displayName: displayName, peerId: peerId)
                }
            } label: {
                Label("Create Session", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            // Join session
            VStack(spacing: 16) {
                Text("Or join an existing session:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("Session Code", text: $viewModel.joinCode)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: 300)
                    .textInputAutocapitalization(.characters)

                Button("Join") {
                    Task {
                        let displayName = appState.activeUser?.displayName ?? "Apple TV"
                        let peerId = "wt-\(UUID().uuidString.prefix(8))"
                        await viewModel.joinSession(displayName: displayName, peerId: peerId)
                    }
                }
                .disabled(viewModel.joinCode.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            Spacer()
        }
        .padding(60)
        .navigationTitle("Watch Together")
    }

    @ViewBuilder
    private var activeSessionView: some View {
        VStack(spacing: 30) {
            // Session code
            VStack(spacing: 8) {
                Text("Session Code")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(viewModel.sessionCode ?? "")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .tracking(6)

                Text("Share this code with friends to join")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            // Participants
            VStack(alignment: .leading, spacing: 16) {
                Text("Participants (\(viewModel.participants.count))")
                    .font(.title3)
                    .fontWeight(.semibold)

                ForEach(viewModel.participants) { participant in
                    HStack(spacing: 12) {
                        Image(systemName: participant.isHost ? "crown.fill" : "person.fill")
                            .foregroundStyle(participant.isHost ? .yellow : .secondary)
                            .accessibilityHidden(true)
                        Text(participant.displayName)
                            .font(.body)
                        if participant.isHost {
                            Text("Host")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.yellow.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(participant.displayName)\(participant.isHost ? ", Host" : "")")
                }
            }
            .frame(maxWidth: 500)

            Spacer()

            // Leave button
            Button("Leave Session", role: .destructive) {
                viewModel.leaveSession()
            }
            .buttonStyle(.bordered)
        }
        .padding(60)
        .navigationTitle("Watch Together")
    }
}
