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
            url: "https://github.com/MazeDev7/MPVKit",
            revision: "0d0931fbbb25a3483a7edb46babd3f2f55abeefc"
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
