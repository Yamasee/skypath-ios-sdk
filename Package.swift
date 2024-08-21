// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SkyPath",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "SkyPathSDK", targets: ["SkyPathSDKTarget"])
    ],
    dependencies: [
        .package(url: "https://github.com/Yamasee/GEOSwift", from: "10.2.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v2.2.4/SkyPathSDK.xcframework.zip",
            checksum: "1f4997e21ed539b1b9b43ecdfe4d994bfe8b1b0578f73a681082f34784ef8f96"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "GEOSwift", package: "GEOSwift")
            ])
    ]
)
