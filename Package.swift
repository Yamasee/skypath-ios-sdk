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
            checksum: "48dd04efc8005b4f6be872697e6db7670f5e55427d7baff81f89608e1071fa08"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "geos", package: "geos")
            ])
    ]
)
