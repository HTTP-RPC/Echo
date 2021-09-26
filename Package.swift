// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "Kilo",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
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
            dependencies: ["Kilo"],
            resources: [
                .process("test.jpg"),
                .process("test.txt")
            ])
    ]
)
