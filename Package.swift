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
        .package(url: "https://github.com/GEOSwift/GEOSwift", from: "11.1.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v3.0.0/SkyPathSDK.xcframework.zip",
            checksum: "3b04a90911ae556b3cf616874c422b87022827568cb79db27e9c8eac034a4373"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "GEOSwift", package: "GEOSwift")
            ])
    ]
)