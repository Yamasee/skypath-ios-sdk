// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SkyPath",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "SkyPathSDK", targets: ["SkyPathSDKTarget"])
    ],
    dependencies: [
        .package(url: "https://github.com/mapbox/turf-swift", exact: "4.0.0"),
        .package(url: "https://github.com/GEOSwift/geos", from: "9.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v4.0.1/SkyPathSDK.xcframework.zip",
            checksum: "0ee2e60ed8b06f29ec9071ff13503af03bd2efe1dd1c4a51f126ad09baedc5ea"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "Turf", package: "turf-swift"),
                .product(name: "geos", package: "geos")
            ],
            path: "Sources/SkyPathSDKTarget"
        )
    ]
)
