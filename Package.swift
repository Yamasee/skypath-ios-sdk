// swift-tools-version: 5.8
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
        .package(url: "https://github.com/GEOSwift/geos.git", exact: "8.1.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v2.2.0/SkyPathSDK.xcframework.zip",
            checksum: "103668383b77436898b83a1c895a0ecc07759519e4708abe86f6aa253b0b32d5"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "geos", package: "geos")
            ])
    ]
)
