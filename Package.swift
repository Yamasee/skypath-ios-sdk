// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SkyPath",
    platforms: [
        .iOS(.v13)
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