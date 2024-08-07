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
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v2.2.3/SkyPathSDK.xcframework.zip",
            checksum: "8269561788ad751f55c26d73775dd95bc50e4320d08004b02959662b70a7b9eb"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "GEOSwift", package: "GEOSwift")
            ])
    ]
)
