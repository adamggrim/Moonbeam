// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Moonbeam",
    platforms: [
        .iOS(.v18)
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
    ],
    swiftLanguageModes: [.v6]
)
