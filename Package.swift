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
        .package(url: "https://github.com/Yamasee/GEOSwift.git", from: "11.1.0"),
        .package(url: "https://github.com/mapbox/turf-swift", from: "4.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v3.0.9/SkyPathSDK.xcframework.zip",
            checksum: "83521f4b1ed3e42470ffaa4950fd5957f5478dde2d36a55fbf02889eca66a9e3"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "GEOSwift", package: "GEOSwift"),
                .product(name: "Turf", package: "turf-swift")
            ])
    ]
)
