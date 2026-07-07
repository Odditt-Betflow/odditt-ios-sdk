// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OddittSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "OddittSDK", targets: ["OddittSDK"]),
    ],
    targets: [
        .target(
            name: "OddittSDK",
            path: "Sources/OddittSDK"
        ),
        .testTarget(
            name: "OddittSDKTests",
            dependencies: ["OddittSDK"],
            path: "Tests/OddittSDKTests"
        ),
    ]
)
