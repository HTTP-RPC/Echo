// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Echo",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Echo",
            targets: ["Echo"])
    ],
    targets: [
        .target(
            name: "Echo",
            dependencies: []),
        .testTarget(
            name: "EchoTests",
            dependencies: ["Echo"],
            resources: [
                .process("test.jpg"),
                .process("test.txt")
            ])
    ]
)
