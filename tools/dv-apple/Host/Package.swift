// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PlezyNGDVExperiment",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18)],
    products: [
        .library(name: "DVExperimentCore", targets: ["DVExperimentCore"]),
        .executable(name: "PlezyNGDVExperiment", targets: ["PlezyNGDVExperiment"]),
    ],
    dependencies: [
        .package(path: "../sources/aether", traits: ["DualLayerDolbyVision"]),
    ],
    targets: [
        .target(name: "DVExperimentCore", dependencies: [
            .product(name: "AetherEngine", package: "aether"),
        ]),
        .executableTarget(name: "PlezyNGDVExperiment", dependencies: ["DVExperimentCore"]),
    ]
)
