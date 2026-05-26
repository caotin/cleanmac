// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CleanMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CleanMacCore", targets: ["CleanMacCore"]),
        .executable(name: "CleanMac", targets: ["CleanMacApp"])
    ],
    targets: [
        .target(name: "CleanMacCore"),
        .executableTarget(
            name: "CleanMacApp",
            dependencies: ["CleanMacCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CleanMacCoreTests",
            dependencies: ["CleanMacCore"]
        )
    ]
)
