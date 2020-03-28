// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Kilo",
    products: [
        .library(
            name: "Kilo",
            targets: ["Kilo"])
    ],
    targets: [
        .target(
            name: "Kilo",
            dependencies: []),
        .testTarget(
            name: "KiloTests",
            dependencies: ["Kilo"])
    ]
)
