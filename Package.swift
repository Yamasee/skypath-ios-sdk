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
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v2.2.2/SkyPathSDK.xcframework.zip",
            checksum: "4500bcf9e9b3a6930f48144e6e5e863d995642c82d91e463f726a4bf46417c6c"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "GEOSwift", package: "GEOSwift")
            ])
    ]
)
