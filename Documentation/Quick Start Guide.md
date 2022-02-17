## Quick Start Guide

#### 1. Install

Use [Requirements](/README.md#requirements) and [Installation](/README.md#installation) sections instructions to add SkyPath iOS SDK to the project.

Also, see [Documentation](/README.md) for a complete API reference.

Add `import SkyPathSDK`.

#### 2. Setup Delegate

Implement `SkyPathDelegate` methods.

```swift
extension Controller: SkyPathDelegate {

    func didUpdateRecordingStatus(to recording: Bool) {
    
        if recording {
            print("SkyPath did start recording")
        } else {
            print("SkyPath did stop recording")
            
            // Call `start()` again to continue recording if needed.
        }		
    }
    
    func didReceiveNewTurbulenceData() {
    
        print("SkyPath did receive new turbulence data")

        // Query for the updated turbulence and show on the map. 
        // See `Get Turbulence` section of this guide.
    }
    
    func didFailToFetchNewData(with error: SPError) {
   	
        print("SkyPath did fail to fetch new data with error: " + error.localizedDescription)
    }
    
    func didChangeDevicePosition(_ inPosition: Bool, horizontal: Bool) {
    
        print("SkyPath device is \(inPosition ? "" : "not ")in position and \(horizontal ? "" : "not ")horizontal")
        
        // Turbulence data is not tracked when device in not in position or is horizontal. 
        // Consider to show a notice here to properly position device in the cradle.
    }
}
```

Set `SkyPathDelegate` object.

```swift
SkyPath.shared.delegate = delegate
```

#### 3. Configure Data

These params have default values, so you can skip it and back to this step later when will have more specific requirements.

All these parameters can be updated at any time.

Set `DataHistoryTime`, it's en enum with cases: `halfHour`, `hour`, `twoHours`, `fourHours`, `sixHours`. Default is `twoHours`.

```swift
SkyPath.shared.dataHistoryTime = .twoHours
```

Set `DataUpdateFrequency`, it's an enum with cases: `none`, `minimal`, `medium`, `fast`. Default is `fast`.


```swift
SkyPath.shared.dataUpdateFrequency = .fast
```

Configure `DataQuery` data types to fetch from the server. Available types are: `turbulence`, `traffic`, `pireps`. Default is `turbulence`. By default all severities of turbulence will be fetched.

```swift
SkyPath.shared.dataQuery.types = .turbulence
SkyPath.shared.dataQuery.sevs = TurbulenceSeverity.allCases
```

Configure `DataQuery` geo fence to fetch from the server. By default data is fetched for the whole world.

```swift
let route: [CLLocationCoordinate2D] = []
SkyPath.shared.dataQuery.route = route
SkyPath.shared.dataQuery.widthAround = 20 // Nautical Miles
// or 
let polygon: [CLLocationCoordinate2D] = []
SkyPath.shared.dataQuery.polygon = polygon
```

#### 3. Setup Aircraft

Turbulence severity can be different for each aircraft type. Set a current a/c type using supported types from the SDK. `SkyPath.shared.aircraft` is `nil` by default. An a/c type is required to be set.

```swift
if let aircraft = SkyPath.shared.aircraft(byId: acId) {
    SkyPath.shared.aircraft = aircraft
}
```
When you don't have an a/c type id, filter all available aircrafts to find appropriate.

```swift
if let aircraft = SkyPath.shared.aircrafts().first(where: { $0.id == "B38M" }) {
    SkyPath.shared.aircraft =  aircraft
}
```

#### 4. Start Recording

Now you can start recording and receiving data. 

```swift
SkyPath.shared.start(
    apiKey: "SKYPATH_API_KEY", // provided by SkyPath
    airline: "AIRLINE_ICAO", // ICAO code of the airline
    userId: "USER_ID") // airline user account id
{ error in    
    if let error = error {
        print(error)
    }
}
```
If parameters are correct, the completion block will be called without an error and `didUpdateRecordingStatus(to:)` delegate method will be called with `true`. Otherwise, the `error` will identify why it can't be started. 

Stop all SDK activities when needed. A new call of `start()` method is required after stopping when need to continue recording and receiving data.

```swift
SkyPath.shared.stop()
```

#### 5. Start Flight

Provide a current flight information. This data is required.

```swift
let flight = Flight(
    dep: "ICAO",
    dest: "ICAO",
    fnum: "FLIGHT_NUMBER")
SkyPath.shared.startFlight(flight)
```
And when flight is ended:

```swift
SkyPath.shared.endFlight()
```


#### 6. Get Turbulence

Use `TurbulenceQuery` to specify how you would like to filter data and how to receive the result - as a GeoJSON or as an array of models. See `TurbulenceQuery` and `TurbulenceResult` docs for more details.
It will query locall cached data received previously per the configuration.

```swift
let query = TurbulenceQuery(
    type: .server,
    altRange: 0...52_000, // feet
    resultOptions: .geoJSON)
    
let result = SkyPath.shared.turbulence(with: query)
switch result {
case .success(let turbResult):
    let geoJSON = turbResult.geoJSON
    map.updateTurbulence(with: geoJSON)
case .failure(let error):
    print(error)
}
```

#### 7. Recording Simulation Testing (optional)

Enable simulation mode during testing. Use it only in development environment by setting `env` parameter in `SkyPath.shared.start(...)`.

```swift
SkyPath.shared.enableSimulation(true)
SkyPath.shared.enablePushSimulated(true)
```

Provide a custom location.

```swift
SkyPath.shared.simulatedLocation(location)
```

Trigger a simulated turbulence event.

```swift
SkyPath.shared.simulateTurbulence(sev: .moderate)
```

#### 8. Configure Logging (optional)

SDK has an internal logging to help with debugging and solve issues. To see more or less SkyPath logs in console configure the logging level.

```swift
SkyPath.shared.logger.level = .verbose
```

You can disable logging completely if needed, but not recommended.

```swift
SkyPath.shared.logger.enabled = false
```

Get log files urls to export.

```swift
let fileUrls = SkyPath.shared.logger.logFileUrls()
```


#### Troubleshooting

- App Store review team rejected the app due to background location mode.

	> Guideline 2.5.4 - Performance - Software Requirements
	
	> Your app declares support for location in the UIBackgroundModes key in your Info.plist file but does not have any features that require persistent location. Apps that declare support for location in the UIBackgroundModes key in your Info.plist file must have features that require persistent location.

	Apple can request a video of how the background location is used in the app. The SkyPath SDK uses it to record turbulence data and fetch the data from the server while app is running in the background. Make a few minutes video that shows the following:

	1. Use a development SkyPath server environment
	1. Simulate a flight in the application, provide a simulated location to the SkyPath SDK
	2. Simulate a turbulence in the SkyPath SDK
	3. Fly for a few minutes showing the web version where the tracked turbulence will appear in the area where the flight was simulated

	Feel free to contact us, if you have any issues. 

