![SkyPath: Turbulence alert system](./docs-logo.jpg)
[![Version](https://img.shields.io/github/v/release/Yamasee/skypath-ios-sdk)]()
  
# SkyPath by Yamasee iOS SDK

SkyPath's goal is delivery of accurate real-time turbulence data, based on crowdsourcing [https://skypath.app](https://skypath.app/)

## Description

Yamasee supplies its partners who wish to integrate SkyPath technology, an iOS SDK that enables rapid and seamless integration into existing iOS apps. The SDK doesn’t assume anything regarding the app UI, and supplies needed abstraction for SkyPath push and pull server REST API communication, turbulence measurements, and turbulence alerts.

SDK API [documentation](https://yamasee.github.io/skypath-ios-sdk)

## Requirements

- iOS 11.0+
- Xcode 12.5+
- Swift 5.0+

## Installation


### Manually

You can integrate SkyPath into your project manually. 

- Download Yamasee.xcframework
- Copy Yamasee.xcframework to a project directory
- In Xcode project target in `General` tab, in `Frameworks, Libraries, and Embedded Content` tap "Add items", choose a Yamasee.xcframework file. Make sure the added framework "Embed" value is set to `Embed & Sign`
- `import Yamasee` where needed


#### Background Modes

The location can be used while the app is in background to keep tracking and alert turbulence. The `Location updates` background mode is needed.<br>
Make sure the  `Privacy - Location When In Use Usage Description` description is provided in the Info.plist of the project. 


## Usage

#### Setup

You need to get an API key and server URL from Yamasee to use the SDK. <br>
You can [contact us] (https://skypath.app/contact/) and request a demo. <br>

The SDK has an entry point class `YamaseeCore`, start the SDK early on app launch (for example in application did finish delegate method) before making other API calls.

```swift
YamaseeCore.shared.start(
	apiKey: "YAMASEE_API_KEY",
	baseUrl: "YAMASEE_BASE_URL",
	env: .development | .production)
```

#### Login

You need to identify the user in the system by login as a partner, where `userId` is a pilot identifier, and `companyId` is provided to you by Yamasee.

```swift
guard !YamaseeCore.shared.isLoggedIn() else {
	return
}
YamaseeCore.shared.partnerLogin(
	userId: userId, 
	companyId: companyId) { [weak self] success, error in
            
	if let error = error {
		print(error.localizedDescription)
	} else if success {
		print("logged in successfully")
	} else {
		print("failed to login")
	}
}

// logout when needed
YamaseeCore.shared.logout()
```

#### Turbulence

SDK provides turbulence data in a GeoJSON format and as an array of models.

```swift
let json = YamaseeCore.shared.getTurbulenceGeoJson(
	altRange: altRange,
	timeSpan: timeSpan)
```
```swift
let turbItems = YamaseeCore.shared.getTurbulence(
	altRange: altRange,
	timeSpan: timeSpan)                     
```

To update how SDK updates data you can configure `DataMode`. For example, to save network traffic when you don't need SkyPath latest data, you can set SDK to `writeOnly` mode.

```swift
YamaseeCore.shared.dataMode = .writeOnly
```

#### Turbulence Alerts

Get turbulence alerts ahead.

```swift
let altitude: Measurement<UnitLength> = Measurement(value: location.altitude, unit: .meters)
        
let tiles = YamaseeCore.shared.getAlertTiles(
	lat: location.coordinate.latitude,
	long: location.coordinate.longitude,
	altitude: altitude,
	heading: Measurement(value: location.course, unit: .degrees),
	timeSpan: timeSpan)

let turbulences: [TurbulenceItem] = [
	tiles.alertTilesAbove, 
	tiles.alertTilesAtAlt, 
	tiles.alertTilesBelow]
	.flatMap { $0 }
```

#### Weather 

The following weather data types are supported: clouds, lightning, wind-shear.

```swift
let weather: [Weather] = YamaseeCore.shared.getWeather(
	types: [.cb, .lightning, .shear],
	altRange: Constants.Altitude.maxRangeFeet,
	timeSpan: timeSpan)
```

Report wheather example

```swift
YamaseeCore.shared.reportWeather(
	type: .cb,
	location: location)
```

#### Aircraft

To identify aircraft in the system set it from predefined in the SDK.

```swift
// get all available aircraft types
let aircrafts = YamaseeCore.shared.aircrafts()

// choose appropriate and set an aircraft
YamaseeCore.shared.setAircraft(aircraft)
```

#### Angle Position

To properly track the current tubulence the device should be correctly position in the cradle.<br>
You also will be notified by `YamaseeCoreDelegate` calls that angle position changed and should be set again.

```swift
if !YamaseeCore.shared.isInPosition() {
	showAngleCalibrationNotification()
}

// when pilot tap "Set" button call
YamaseeCore.shared.setAngle()
```
        
#### Simulation

Use simulation mode functions to test

```swift
// enter simulation mode
YamaseeCore.shared.setSimulatorMode(isLocationSimulatorOn: true)
YamaseeCore.shared.setPushSimulatedEnabled(env != .production)

// set custom location for simulation
YamaseeCore.shared.simulatedLocation(location)

// exit simulation mode
YamaseeCore.shared.setSimulatorMode(isLocationSimulatorOn: false)
```

#### Logger

You can use logger to get more debug logs in a console.

```swift
YamaseeCore.shared.setLogger(
	isOn: true, 
	isSymbol: true, 
	errorOn: true, 
	infoOn: true, 
	warningOn: true, 
	networkOn: true) { message in
		print(message)
}
```


## License

Copyright © Yamasee LTD 2021. All rights reserved. 
See [Terms & Conditions](https://skypath.app/terms/).
