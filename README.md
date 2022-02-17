![SkyPath.io | The world’s leading turbulence and auto-PIREPS data source](./docs-logo.png)
![Version](https://img.shields.io/github/v/release/Yamasee/skypath-ios-sdk)
![Cocoapods](https://img.shields.io/cocoapods/v/SkyPath)
![Cocoapods platforms](https://img.shields.io/cocoapods/p/SkyPath)
  
## SkyPath iOS SDK

SkyPath's goal is delivery of accurate real-time turbulence data, based on crowdsourcing [https://skypath.io](https://skypath.io/)

## Contents

- [Description](#description)
- [Requirements](#requirements)
- [Migration Guides](#migration-guides)
- [Installation](#installation)
- [Quick Start Guide](/Documentation/Quick%20Start%20Guide.md)
- [Documentation](https://yamasee.github.io/skypath-ios-sdk)
- [License](#license)

## Description

SkyPath iOS SDK enables rapid and seamless integration of SkyPath technology into existing iOS apps. The SDK doesn’t assume anything regarding the app UI, and supplies needed abstraction for SkyPath push and pull server REST API communication, turbulence measurements, and turbulence alerts.

## Requirements

- iOS 12.0+
- Xcode 13.0+
- Swift 5.0+

#### Background Mode

The location can be used while the app is in the background to keep tracking and alert turbulence. <br>
Add `Background Modes` capability in `Signing & Capabilities` and enable `Location updates` mode. <br>
Make sure the  `Privacy - Location When In Use Usage Description` description is provided in the Info.plist of the project. 


## Migration Guides

- [SkyPath 2.0 Migration Guide](/Documentation/SkyPath%202.0%20Migration%20Guide.md)

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate SkyPath into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'SkyPath', '~> 2.0-beta1'
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

To integrate SkyPath into your Xcode project using Swift Package Manager, add it to the dependencies value of your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/Yamasee/skypath-ios-sdk.git", .upToNextMajor(from: "2.0-beta1"))
]
```

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate SkyPath into your project manually.

- Download `SkyPathSDK.xcframework`
- Copy `SkyPathSDK.xcframework` to a project directory
- In Xcode project target in `General` tab, in `Frameworks, Libraries, and Embedded Content` tap "Add items", choose a `SkyPathSDK.xcframework` file. Make sure the added framework "Embed" value is set to `Embed & Sign`

## License

Copyright © Yamasee LTD 2022. All rights reserved. 
See [Terms & Conditions](https://skypath.io/terms/).
