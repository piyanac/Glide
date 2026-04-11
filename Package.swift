// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Glide",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "Glide",
            targets: ["Glide"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Glide",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "GlideTests",
            dependencies: ["Glide"]
        ),
    ]
)
