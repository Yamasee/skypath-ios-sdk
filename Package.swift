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
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v2.2.1/SkyPathSDK.xcframework.zip",
            checksum: "3900152b3b05f9c1783197fe0533fc0db8a60b1de6da2f3904791109e53f0417"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "geos", package: "geos")
            ])
    ]
)
