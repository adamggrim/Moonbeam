// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Moonbeam",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Moonbeam",
            targets: ["Moonbeam"]),
    ],
    targets: [
        .target(
            name: "Moonbeam",
            dependencies: []),
    ]
)
