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
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v3.0.5/SkyPathSDK.xcframework.zip",
            checksum: "043f7b0226eeb8d1ff9ce23e036c616f61456d4c549e86a1cd0e72b8d536d400"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "Turf", package: "turf-swift")
            ])
    ]
)