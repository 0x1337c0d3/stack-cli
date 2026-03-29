// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "stack-cli",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "stack-cli", targets: ["stack-cli"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "1.3.1")),
    ],
    targets: [
        .executableTarget(
            name: "stack-cli",
            dependencies: ["StackLibrary"]
        ),
        .target(
            name: "StackLibrary",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "StackTests",
            dependencies: ["StackLibrary"]
        ),
    ]
)
