//
//  FullScreenHeroView.swift
//  Beacon tvOS
//
//  Full-screen hero background layout with overlaid navigation and content
//  Based on Apple's tvOS media catalog app patterns
//

import SwiftUI

// MARK: - Mock Data Models

struct MockMediaItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let progress: Double?

    static let heroItems = [
        MockMediaItem(
            title: "The Last of Us",
            description: "After a global pandemic destroys civilization, a hardened survivor takes charge of a 14-year-old girl who may be humanity's last hope.",
            imageName: "tv.fill",
            progress: nil
        ),
        MockMediaItem(
            title: "Breaking Bad",
            description: "A high school chemistry teacher diagnosed with inoperable lung cancer turns to manufacturing and selling methamphetamine.",
            imageName: "film.fill",
            progress: 0.65
        ),
        MockMediaItem(
            title: "Succession",
            description: "The Roy family is known for controlling the biggest media and entertainment company in the world.",
            imageName: "person.3.fill",
            progress: nil
        )
    ]

    static let continueWatchingItems = [
        MockMediaItem(
            title: "Stranger Things",
            description: "S4, E1: The Hellfire Club",
            imageName: "tv.fill",
            progress: 0.45
        ),
        MockMediaItem(
            title: "The Crown",
            description: "S3, E5: Coup",
            imageName: "crown.fill",
            progress: 0.75
        ),
        MockMediaItem(
            title: "The Mandalorian",
            description: "S2, E8: The Rescue",
            imageName: "star.fill",
            progress: 0.20
        ),
        MockMediaItem(
            title: "Better Call Saul",
            description: "S5, E3: The Guy For This",
            imageName: "briefcase.fill",
            progress: 0.60
        )
    ]
}

// MARK: - Main Full-Screen Hero View (Demo)
// NOTE: This is a demo/reference file showing the full-screen hero pattern.
// The actual implementation is in HomeView.swift

struct FullScreenHeroView: View {
    @State private var currentHeroIndex = 0
    @Namespace private var focusNamespace

    var body: some View {
        ZStack {
            // Layer 1: Full-screen hero background (fills entire screen)
            HeroBackgroundCarouselView(
                items: MockMediaItem.heroItems,
                currentIndex: $currentHeroIndex
            )

            // Layer 2: Overlaid content (navigation + continue watching)
            VStack(spacing: 0) {
                // NOTE: Top navigation would go here in real implementation
                // Using TopNavigationMenu from HomeView.swift with TabCoordinator
                Color.clear.frame(height: 100)

                Spacer()

                // Continue Watching row near bottom
                ContinueWatchingRow(items: MockMediaItem.continueWatchingItems)
                    .focusSection()
                    .padding(.bottom, 80)
            }

            // Layer 3: Hero overlay with Play button and metadata
            VStack {
                Spacer()

                HeroOverlayView(
                    item: MockMediaItem.heroItems[currentHeroIndex],
                    onPlay: {
                        print("Play tapped for: \(MockMediaItem.heroItems[currentHeroIndex].title)")
                    },
                    onNext: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentHeroIndex = (currentHeroIndex + 1) % MockMediaItem.heroItems.count
                        }
                    },
                    onPrevious: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentHeroIndex = currentHeroIndex > 0 ? currentHeroIndex - 1 : MockMediaItem.heroItems.count - 1
                        }
                    }
                )
                .focusSection()
                .padding(.bottom, 280) // Position above Continue Watching
            }
        }
        .ignoresSafeArea()
        .focusScope(focusNamespace)
    }
}

// MARK: - Hero Background Carousel View

/// Full-screen background carousel that fills the entire tvOS screen
struct HeroBackgroundCarouselView: View {
    let items: [MockMediaItem]
    @Binding var currentIndex: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sliding background images
                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        // Mock background with SF Symbol (replace with actual image in production)
                        ZStack {
                            // Gradient background
                            LinearGradient(
                                colors: gradientColors(for: index),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            // Large icon as placeholder
                            Image(systemName: item.imageName)
                                .font(.system(size: 400))
                                .foregroundColor(.white.opacity(0.1))
                                .offset(x: 200, y: -100)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .offset(x: -CGFloat(currentIndex) * geometry.size.width)
                .animation(.easeInOut(duration: 0.6), value: currentIndex)

                // Dark gradient overlay for readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.85)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }

    private func gradientColors(for index: Int) -> [Color] {
        let colorSets: [[Color]] = [
            [Color.beaconBlue, Color.beaconPurple],
            [Color.beaconPurple, Color.beaconMagenta],
            [Color.beaconMagenta, Color.beaconOrange]
        ]
        return colorSets[index % colorSets.count]
    }
}

// MARK: - Hero Overlay View

/// Overlay with title, description, and focusable Play button
struct HeroOverlayView: View {
    let item: MockMediaItem
    let onPlay: () -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void

    @FocusState private var isPlayButtonFocused: Bool
    @FocusState private var isPreviousButtonFocused: Bool
    @FocusState private var isNextButtonFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            Text(item.title)
                .font(.system(size: 76, weight: .bold, design: .default))
                .foregroundColor(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 4)

            // Description
            Text(item.description)
                .font(.system(size: 28, weight: .regular, design: .default))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
                .frame(maxWidth: 1000, alignment: .leading)
                .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 2)

            // Buttons row
            HStack(spacing: 20) {
                // Previous button
                Button(action: onPrevious) {
                    HStack(spacing: 12) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Previous")
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .foregroundColor(.white)
                }
                .buttonStyle(.clearGlass)
                .focused($isPreviousButtonFocused)

                // Play button (primary focus)
                Button(action: onPlay) {
                    HStack(spacing: 12) {
                        Image(systemName: item.progress != nil ? "play.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))

                        if let progress = item.progress {
                            // Show progress indicator
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 50, height: 6)

                                Capsule()
                                    .fill(Color.beaconGradient)
                                    .frame(width: 50 * progress, height: 6)
                            }

                            let percentLeft = Int((1.0 - progress) * 100)
                            Text("\(percentLeft)% left")
                                .font(.system(size: 24, weight: .semibold))
                        } else {
                            Text("Play")
                                .font(.system(size: 24, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                }
                .buttonStyle(.clearGlass)
                .focused($isPlayButtonFocused)
                .prefersDefaultFocus(in: focusNamespace)

                // Next button
                Button(action: onNext) {
                    HStack(spacing: 12) {
                        Text("Next")
                            .font(.system(size: 24, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.white)
                }
                .buttonStyle(.clearGlass)
                .focused($isNextButtonFocused)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 90)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @Namespace private var focusNamespace
}

// MARK: - Top Menu View (Demo Version)
// NOTE: This is a demo file. The actual TopNavigationMenu and TopMenuItem
// are defined in HomeView.swift and use TabCoordinator for real navigation.

// MARK: - Continue Watching Row

/// Horizontal row of Continue Watching items overlaid near bottom
struct ContinueWatchingRow: View {
    let items: [MockMediaItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section title
            Text("Continue Watching")
                .font(.system(size: 40, weight: .bold, design: .default))
                .foregroundColor(.white)
                .padding(.horizontal, 90)
                .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)

            // Horizontal scrolling row
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 24) {
                    ForEach(items) { item in
                        DemoContinueWatchingCard(item: item)
                    }
                }
                .padding(.horizontal, 90)
            }
            .tvOSScrollClipDisabled()
        }
    }
}

struct DemoContinueWatchingCard: View {
    let item: MockMediaItem

    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: {
            print("Selected: \(item.title)")
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Card image
                ZStack {
                    // Mock background
                    RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.beaconPurple, Color.beaconMagenta],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Icon placeholder
                    Image(systemName: item.imageName)
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))

                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cornerRadiusXLarge, style: .continuous))

                    // Title on card
                    VStack {
                        Spacer()
                        HStack {
                            Text(item.title)
                                .font(.system(size: 22, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                                .padding(20)
                            Spacer()
                        }
                    }
                }
                .frame(width: 400, height: 225)
                .shadow(
                    color: .black.opacity(isFocused ? 0.8 : 0.6),
                    radius: isFocused ? 40 : 20,
                    x: 0,
                    y: isFocused ? 20 : 10
                )

                // Progress bar
                if let progress = item.progress {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.regularMaterial)
                            .opacity(0.4)
                            .frame(width: 400, height: 5)

                        Capsule()
                            .fill(Color.beaconGradient)
                            .frame(width: 400 * progress, height: 5)
                            .shadow(color: Color.beaconMagenta.opacity(0.6), radius: 4, x: 0, y: 0)
                    }
                    .padding(.top, 8)
                }

                // Description below card
                Text(item.description)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .frame(width: 400, alignment: .leading)
                    .padding(.top, 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focusable()
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
        .onPlayPauseCommand {
            print("Play/Pause: \(item.title)")
        }
    }
}

// MARK: - Preview

#Preview {
    FullScreenHeroView()
}
