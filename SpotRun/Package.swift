// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpotRun",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "SpotRunCore",
            targets: ["SpotRunCore"]
        )
    ],
    targets: [
        .target(
            name: "SpotRunCore",
            dependencies: []
        ),
        .testTarget(
            name: "SpotRunCoreTests",
            dependencies: ["SpotRunCore"]
        )
    ]
)
