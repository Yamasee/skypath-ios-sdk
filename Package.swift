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
        .package(url: "https://github.com/mapbox/turf-swift", from: "4.0.0"),
        .package(url: "https://github.com/GEOSwift/geos", from: "9.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v3.0.19/SkyPathSDK.xcframework.zip",
            checksum: "b51e1b2686a3bccac5b1f055b777d814443a19595aae9b8b244c493ec7d6c99a"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "Turf", package: "turf-swift"),
                .product(name: "geos", package: "geos")

            ])
    ]
)
