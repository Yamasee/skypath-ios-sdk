// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SkyPath",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "SkyPathSDK", targets: ["SkyPathSDKTarget"])
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/turf-swift", from: "4.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v3.0.3/SkyPathSDK.xcframework.zip",
            checksum: "191368ffcfd43e30b2c348cd9cb66e62fc6ce7bbbc8d621b0de381c3da8cdad6"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "Turf", package: "turf-swift")
            ])
    ]
)