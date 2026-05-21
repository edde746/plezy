// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VibeStream",
    platforms: [
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "VibeStream",
            targets: ["VibeStream"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/MazeDev7/MPVKitAM",
            revision: "42dcc3123000361d0be54fbaec981043b77e1e05"
        ),
    ],
    targets: [
        .target(
            name: "VibeStream",
            dependencies: [
                .product(name: "MPVKit", package: "MPVKit"),
            ],
            path: "VibeStream",
            exclude: ["TopShelf/Info.plist"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .process("Resources/Localizable.xcstrings"),
                .process("Resources/Ratings")
            ]
        ),
        .testTarget(
            name: "VibeStreamTests",
            dependencies: ["VibeStream"],
            path: "VibeStreamTests"
        ),
    ]
)
