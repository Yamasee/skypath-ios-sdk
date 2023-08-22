# SkyPath 2.0 Migration Guide
SkyPath 2.0 is the latest major release of SkyPath written in Swift. As a major release, following Semantic Versioning conventions, 2.0 introduces API-breaking changes.

This guide is provided in order to ease the transition of existing applications using SkyPath 1.x to the 2.0 APIs.

Where possible, Xcode will provide an automatic "fix-it".

## What you need to do

##### Essensials

1. The framework file `Yamasee.xcframework` has been renamed to `SkyPathSDK.xcframework`, so please remove `Yamasee.xcframework` from the project and follow [Installation](/README.md#intallation) guide. 

2. Replace `import Yamasee` with `import SkyPathSDK` in code. Make sure to do a `Clean Build Folder` in Xcode 

3. Rename `YamaseeCore` with `SkyPath` and `YamaseeCoreDelegate` with `SkyPathDelegate`

4. Update `YamaseeCore` method `start(apiKey:baseUrl:env:)` with the new `SkyPath` method `start(apiKey:airline:userId:env:completion)` with all parameters required. If you used `partnerLogin(userId:companyId:completionHandler)` you don't need it anymore, the new start API does everything needed in terms of authentication. Check `StartError` passed in completion to check if start was successful. The server base url has been moved to `Environment` enum associated value which is now optional if no proxy server is used. 

5. Rename `YamaseeCore.logout()` to `SkyPath.stop()`
 
6. `YamaseeCoreDelegate.loginStatus(isLoggedIn:)` replaced with `SkyPathDelegate.didUpdateRecordingStatus(to:)`

7. Set appropriate data update frequency `SkyPath.dataUpdateFrequency` before calling `SkyPath.shared.start(...)`. `SkyPath.dataUpdateFrequency` can be changed at any time.
 
##### Turbulence 
 
- Use `SkyPath.turbulence(with:)` only to get turbulence data, because the following deprecated methods have been removed:<br>
`YamaseeCore.getTurbulenceGeoJson(altRange:timeSpan:zoomLevel:excludeTiles:aggregate:)`<br>
`YamaseeCore.getTurbulence(altRange:timeSpan:zoomLevel:excludeTiles:aggregate:)`<br>
`YamaseeCore.getOwnTurbulenceGeoJson(altRange:timeSpan:zoomLevel:aggregate:)`<br>
`YamaseeCore.getOwnTurbulence(altRange:timeSpan:zoomLevel:aggregate:)`<br>
`YamaseeCore.turbulence(inTile:altRange:timeSpan:own:)`

- Rename `TurbulenceSeverity` cases to camel case with lowercased first letter. For example `None` to `none`, `ModerateSevere` to `moderateSevere`. <br>
Make sure to update all places including switch cases (which can not trigger an error but only a warning that switch must be exhaustive)

##### Alerts

- Use `SkyPath.alerts(with:)` only to get turbulence alerts, because the following deprecated methods have been removed:<br>
`YamaseeCore.getAlert(lat:long:altitude:heading:timeSpan:distance:unit:angleSpan:)`<br>
`YamaseeCore.getAlertTiles(lat:long:altitude:heading:timeSpan:distance:angleSpan:)`<br>
`YamaseeCore.getRouteAlerts(route:widthAround:unit:altitude:timeSpan:)`

- You also can use a new auto monitoring alerts feature by using `SkyPath.startMonitoringAlerts(with:)` and `SkyPath.stopMonitoringAlerts()`

##### Aircraft

- The following deprecated methods have been removed:<br>
`YamaseeCore.setAircraft(aircraft:)`<br>
`YamaseeCore.getAircraft()`<br>
`YamaseeCore.getAircraftTypes()`<br>
and replaced with `SkyPath.aircraft` variable

- `Aircraft` field `aircraft` renamed to `id` and `description` renamed to `title`

##### SkyPathDelegate

- `ownWeatherChanged()` has been suppressed by `newWeatherData(serverUpdateTime:)`, so only last will be called

- `newTurbulenceData(serverUpdateTime:)` has been renamed to `didReceiveNewTurbulenceData()`

- `turbulenceDetected(newTurbulence:)` renamed to `detectedTurbulence(_:)`

- `ownTurbulenceChanged()` has been suppressed by `detectedTurbulence(_:)`

- `newTrafficData(serverUpdateTime:)` renamed to `didReceiveNewTrafficData()`

- `newWeatherData(serverUpdateTime:)` renamed to `didReceiveNewWeatherData()`

- `newAirportsData()` renamed to `didReceiveNewAirportsData()`

- `newAlert(_:)` renamed to `didReceiveAlert(_:)`

##### Device Position

- Device position angle is now automatically set, so you don't need to use such methods as `SkyPath.shared.setAngle()`, `SkyPath.shared.resetAngle()`, `SkyPath.shared.isInPosition()` and `SkyPath.shared.isCurrentPositionSteady()`, so they were removed.

##### Other
 
- `YMLogger` renamed to `Logger` and it's accessible now by `YamaseeCore.shared.logger` instead of `Logger.shared`. Deprecated method `setLogger(isOn:errorOn:infoOn:warningOn:networkOn:onLog:)` has been removed

- `YMLocation` renamed to `SPLocation` and `YMLocationState` to `SPLocationState`

- `YMError` renamed to `SPError` and `PartnerLoginError` with `LoginError` renamed to `StartError` 

- `YamaseeCoreDelegate.serverReachabilityUpdate(isReachable:)` renamed to `SkyPathDelegate.serverReachabilityUpdated(to:)`

- The following deprecated methods have been removed:<br>
`YamaseeCore.setFlightNumber(_)`<br>
`YamaseeCore.setFlightNumber(flightNumber:)`
<br>and replaced with <br>
`SkyPath.startFlight(_:)`

-  `YamaseeCore.setSimulatorMode(isLocationSimulatorOn:)` renamed to `SkyPath.enableSimulation(_:)`

- Previously altitude and distance values were passed as `Measurement` value. Now it's simplified to pass actual `Double` value or range for altitudes in feet and distance in nautical miles. 