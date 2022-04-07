// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SkyPath",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SkyPath",
            targets: ["SkyPath"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "SkyPath",
            path: "./SkyPathSDK.xcframework"
        )
    ]
)