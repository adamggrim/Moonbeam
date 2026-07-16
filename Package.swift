// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Moonbeam",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "Moonbeam",
            targets: ["Moonbeam"]),
    ],
    targets: [
        .target(
            name: "MoonbeamShared",
            dependencies: []),
        .target(
            name: "Moonbeam",
            dependencies: ["MoonbeamShared"],
            resources: [
                .process("Shaders")
            ]),
    ],
    swiftLanguageModes: [.v6]
)
