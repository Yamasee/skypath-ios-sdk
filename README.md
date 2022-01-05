![SkyPath: Turbulence alert system](./docs-logo.jpg)
[![Version](https://img.shields.io/github/v/release/Yamasee/skypath-ios-sdk)]()
  
# SkyPath iOS SDK

SkyPath's goal is delivery of accurate real-time turbulence data, based on crowdsourcing [https://skypath.io](https://skypath.io/)

## Description

SkyPath iOS SDK enables rapid and seamless integration of SkyPath technology into existing iOS apps. The SDK doesn’t assume anything regarding the app UI, and supplies needed abstraction for SkyPath push and pull server REST API communication, turbulence measurements, and turbulence alerts.

SDK API [documentation](https://yamasee.github.io/skypath-ios-sdk)

## Requirements

- iOS 12.0+
- Xcode 13.0+
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

You need to get an API key and server URL to use the SDK. <br>
You can [contact us] (https://skypath.io/contact/) and request a demo. <br>

The SDK has an entry point class `YamaseeCore`, start the SDK early on app launch (for example in application did finish delegate method) before making other API calls.

```swift
YamaseeCore.shared.start(
	apiKey: "YAMASEE_API_KEY",
	baseUrl: "YAMASEE_BASE_URL",
	env: .development | .production)
```

#### Login

You need to identify the user in the system by login as a partner, where `userId` is a pilot identifier, and `companyId` is provided to you.

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

#### Flight

Provide current flight information via `startFlight(_:)`. 

```swift
let flight = Flight(
	dep: "ICAO",
	dest: "ICAO",
	fnum: "FLIGHT_NUMBER")
		
YamaseeCore.shared.startFlight(flight)
```
When flight is ended call `endFlight()`.

```swift
YamaseeCore.shared.endFlight()
```


#### Turbulence

Use `TurbulenceQuery` to specify how you would like to filter data and how to receive the result - as a GeoJSON or as an array of models. See `TurbulenceQuery` and `TurbulenceResult` docs for more details.

```swift
let query = TurbulenceQuery(
	type: .server,
	timeSpan: timeSpan,
	altRange: altRange,
	resultOptions: .items,
	excludeTiles: excludeTiles,
	aggregate: aggregate)

let result = YamaseeCore.shared.turbulence(with: query)

switch result {
	case .success(let result):
		print(result.items)
	case .failure(let error):
		print(error)
}
```

To update how SDK updates data you can configure `DataMode`. For example, to save network traffic when you don't need SkyPath latest data, you can set SDK to `writeOnly` mode.

```swift
YamaseeCore.shared.dataMode = .writeOnly
```

Specify how much time of initial data should be fetched on start. To reduce network traffic you can set less time. If set new time higher than previous during app running the initial data will be refetched immediately.

```swift
YamaseeCore.shared.dataHistoryTime = .halfHour
```

#### Turbulence Alerts

Use `AlertQuery` to get turbulence alerts ahead. See `AlertQuery` and `AlertResult` docs for more details. Route coordinates and beam modes are supported.

```swift
let altitude: Measurement<UnitLength> = Measurement(value: location.altitude, unit: .meters)
	
let query = AlertQuery(
	altitude: altitude,
	timeSpan: timeSpan,
	coordinates: route.map { $0.coordinate },
	widthAround: widthAround)

let result = YamaseeCore.shared.alerts(with: query)

switch result {
	case .success(let result):
		print(result)
	case .failure(let error):
		print(error)
}
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

Disable logging if needed

```swift
YMLogger.shared.enabled = false
```
Get log files urls to export for debug

```swift
let fileUrls = YMLogger.shared.logFileUrls()
```


## License

Copyright © Yamasee LTD 2022. All rights reserved. 
See [Terms & Conditions](https://skypath.io/terms/).
