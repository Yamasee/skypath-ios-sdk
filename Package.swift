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
        .package(url: "https://github.com/GEOSwift/geos", from: "9.0.0"),
        .package(url: "https://github.com/Yamasee/swift-protobuf", from: "1.32.0")
    ],
    targets: [
        .binaryTarget(
            name: "SkyPathSDK",
            url: "https://github.com/Yamasee/skypath-ios-sdk/releases/download/v3.1.2/SkyPathSDK.xcframework.zip",
            checksum: "35cdf71593a940f898006e35bf6137cd5ec2acd8f9673c8beed073f5e097ff4b"),
        .target(
            name: "SkyPathSDKTarget",
            dependencies: [
                .target(name: "SkyPathSDK"),
                .product(name: "Turf", package: "turf-swift"),
                .product(name: "geos", package: "geos"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ])
    ]
)
