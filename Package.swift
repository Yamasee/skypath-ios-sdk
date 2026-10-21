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
        .package(url: "https://github.com/mapbox/turf-swift", exact: "4.0.0"),
        .package(url: "https://github.com/GEOSwift/geos", from: "9.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v3.1.4/SkyPathSDK.xcframework.zip",
            checksum: "87ea88814dac6ab9156246e59c293d3e476a8addfa80f01ad5773499e05e62de"),
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
