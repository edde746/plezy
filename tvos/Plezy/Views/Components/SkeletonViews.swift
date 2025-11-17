//
//  SkeletonViews.swift
//  Beacon tvOS
//
//  Skeleton loading views for better perceived performance
//

import SwiftUI

// MARK: - Skeleton Base Components

struct SkeletonBox: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @State private var isAnimating = false

    init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.2),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Media Card Skeleton

struct MediaCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Poster
            SkeletonBox(width: 300, height: 450, cornerRadius: 10)

            // Title
            SkeletonBox(width: 250, height: 20, cornerRadius: 4)

            // Subtitle
            SkeletonBox(width: 180, height: 16, cornerRadius: 4)
        }
        .frame(width: 300)
    }
}

// MARK: - Landscape Card Skeleton

struct LandscapeCardSkeleton: View {
    var body: some View {
        HStack(spacing: 20) {
            // Background art
            SkeletonBox(width: 600, height: 338, cornerRadius: 10)

            // Info
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBox(width: 200, height: 24, cornerRadius: 4)
                SkeletonBox(width: 300, height: 20, cornerRadius: 4)
                SkeletonBox(width: 250, height: 16, cornerRadius: 4)
            }

            Spacer()
        }
        .frame(width: 1000, height: 338)
    }
}

// MARK: - Library Grid Skeleton

struct LibraryGridSkeleton: View {
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 30)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 40) {
            ForEach(0..<12, id: \.self) { _ in
                MediaCardSkeleton()
            }
        }
        .padding(80)
    }
}

// MARK: - Hero Carousel Skeleton

struct HeroCarouselSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Background
            SkeletonBox(width: nil, height: 600, cornerRadius: 0)
                .overlay(
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()

                        // Title
                        SkeletonBox(width: 400, height: 60, cornerRadius: 8)

                        // Metadata
                        HStack(spacing: 12) {
                            SkeletonBox(width: 80, height: 20, cornerRadius: 4)
                            SkeletonBox(width: 60, height: 20, cornerRadius: 4)
                            SkeletonBox(width: 100, height: 20, cornerRadius: 4)
                        }

                        // Summary
                        VStack(spacing: 8) {
                            SkeletonBox(width: 600, height: 16, cornerRadius: 4)
                            SkeletonBox(width: 550, height: 16, cornerRadius: 4)
                            SkeletonBox(width: 580, height: 16, cornerRadius: 4)
                        }

                        // Buttons
                        HStack(spacing: 16) {
                            SkeletonBox(width: 120, height: 50, cornerRadius: 8)
                            SkeletonBox(width: 120, height: 50, cornerRadius: 8)
                        }
                    }
                    .padding(80)
                )
        }
    }
}

// MARK: - Content Row Skeleton

struct ContentRowSkeleton: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Row title
            SkeletonBox(width: 200, height: 28, cornerRadius: 4)
                .padding(.horizontal, 80)

            // Horizontal scroll of cards
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(0..<6, id: \.self) { _ in
                        MediaCardSkeleton()
                    }
                }
                .padding(.horizontal, 80)
            }
        }
    }
}

// MARK: - Detail View Skeleton

struct MediaDetailSkeleton: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 30) {
                // Back button
                SkeletonBox(width: 100, height: 40, cornerRadius: 8)
                    .padding(.top, 40)

                // Main content
                HStack(alignment: .top, spacing: 40) {
                    // Poster
                    SkeletonBox(width: 400, height: 600, cornerRadius: 15)

                    // Info
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        SkeletonBox(width: 600, height: 48, cornerRadius: 8)

                        // Metadata
                        HStack(spacing: 15) {
                            SkeletonBox(width: 60, height: 24, cornerRadius: 4)
                            SkeletonBox(width: 80, height: 24, cornerRadius: 4)
                            SkeletonBox(width: 100, height: 24, cornerRadius: 4)
                        }

                        // Summary
                        VStack(spacing: 8) {
                            SkeletonBox(width: 700, height: 20, cornerRadius: 4)
                            SkeletonBox(width: 680, height: 20, cornerRadius: 4)
                            SkeletonBox(width: 650, height: 20, cornerRadius: 4)
                            SkeletonBox(width: 620, height: 20, cornerRadius: 4)
                        }
                        .padding(.top, 10)

                        // Genres
                        HStack(spacing: 10) {
                            SkeletonBox(width: 100, height: 32, cornerRadius: 16)
                            SkeletonBox(width: 120, height: 32, cornerRadius: 16)
                            SkeletonBox(width: 90, height: 32, cornerRadius: 16)
                        }

                        // Buttons
                        HStack(spacing: 20) {
                            SkeletonBox(width: 150, height: 55, cornerRadius: 8)
                            SkeletonBox(width: 180, height: 55, cornerRadius: 8)
                        }
                        .padding(.top, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Home View Skeleton

struct HomeViewSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Hero carousel skeleton
                HeroCarouselSkeleton()

                // Content rows
                ForEach(0..<3, id: \.self) { index in
                    ContentRowSkeleton(title: "Row \(index)")
                }
            }
        }
    }
}

#Preview("Media Card Skeleton") {
    ZStack {
        Color.black.ignoresSafeArea()
        MediaCardSkeleton()
    }
}

#Preview("Home Skeleton") {
    ZStack {
        Color.black.ignoresSafeArea()
        HomeViewSkeleton()
    }
}

#Preview("Detail Skeleton") {
    MediaDetailSkeleton()
}
