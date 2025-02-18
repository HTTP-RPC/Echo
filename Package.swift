// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Echo",
    platforms: [
        .iOS(.v16)
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
