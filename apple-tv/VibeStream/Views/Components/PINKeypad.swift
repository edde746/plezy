import SwiftUI

struct PINKeypad: View {
    let title: String
    var subtitle: String?
    var onSubmit: (String) -> Void
    var onCancel: () -> Void

    @State private var digits: [String] = []
    @State private var shake = false
    private let maxDigits = 4

    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // PIN dots
            HStack(spacing: 20) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    Circle()
                        .fill(index < digits.count ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .scaleEffect(index < digits.count ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: digits.count)
                }
            }
            .offset(x: shake ? -10 : 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(digits.count) of \(maxDigits) digits entered")

            // Number grid: 1-9, then 0
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 16) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            digitButton(number)
                        }
                    }
                }

                // Bottom row: Delete, 0, Cancel
                HStack(spacing: 16) {
                    Button {
                        if !digits.isEmpty {
                            digits.removeLast()
                        }
                    } label: {
                        Image(systemName: "delete.backward")
                            .font(.title3)
                            .frame(width: 100, height: 70)
                    }
                    .accessibilityLabel("Delete")

                    digitButton(0)

                    Button("Cancel") {
                        onCancel()
                    }
                    .frame(width: 100, height: 70)
                }
            }
        }
        .padding(60)
    }

    private func digitButton(_ number: Int) -> some View {
        Button {
            guard digits.count < maxDigits else { return }
            digits.append(String(number))
            if digits.count == maxDigits {
                let pin = digits.joined()
                onSubmit(pin)
            }
        } label: {
            Text("\(number)")
                .font(.title)
                .fontWeight(.medium)
                .frame(width: 100, height: 70)
        }
    }

    func showError() {
        digits = []
        withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
            shake = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shake = false
        }
    }
}
