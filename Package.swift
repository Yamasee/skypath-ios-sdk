// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "SkyPath",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SkyPathSDK",
            targets: ["SkyPathSDK"])
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            path: "./SkyPathSDK.xcframework"
        )
    ]
)