import SwiftUI

struct SessionOverlay: View {
    let participants: [WatchSession.Participant]
    let sessionCode: String
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            VStack {
                HStack {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 12) {
                        // Session info
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .accessibilityHidden(true)
                            Text(sessionCode)
                                .font(.caption)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Session code: \(sessionCode)")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassMaterial(in: Capsule())

                        // Participant list
                        ForEach(participants) { participant in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(participant.isHost ? .yellow : .green)
                                    .frame(width: 8, height: 8)
                                    .accessibilityHidden(true)
                                Text(participant.displayName)
                                    .font(.caption2)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(participant.displayName)\(participant.isHost ? ", Host" : "")")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .glassMaterial(in: Capsule())
                        }
                    }
                    .padding(20)
                }

                Spacer()
            }
            .transition(.move(edge: .trailing))
            .animation(.easeInOut, value: isVisible)
        }
    }
}
