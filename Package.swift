// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CodexUsageMeter",
    platforms: [.macOS(.v14), .watchOS(.v10)],
    products: [
        .executable(name: "CodexUsageMeter", targets: ["CodexUsageMeterApp"]),
        .library(name: "CodexUsageMeterCore", targets: ["CodexUsageMeterCore"]),
        .library(name: "CodexUsageMeterWatch", targets: ["CodexUsageMeterWatch"]),
    ],
    targets: [
        .executableTarget(
            name: "CodexUsageMeterApp",
            dependencies: ["CodexUsageMeterCore"]),
        .target(name: "CodexUsageMeterCore"),
        .target(
            name: "CodexUsageMeterWatch",
            dependencies: ["CodexUsageMeterCore"]),
        .testTarget(
            name: "CodexUsageMeterCoreTests",
            dependencies: ["CodexUsageMeterCore"]),
        .testTarget(
            name: "CodexUsageMeterAppTests",
            dependencies: ["CodexUsageMeterApp"]),
    ])
