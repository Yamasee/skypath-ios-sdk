//
//  YamaseeViewController.swift
//  Demo
//
//  Created by Alex Kovalov on 20.10.2020.
//  Copyright © 2020 Yamasee. All rights reserved.
//

import UIKit
import Yamasee

class YamaseeViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocationManager.shared.startUpdatingLocation()
        
        setupYamasee()
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            loginPartner()
        case 1:
            logout()
        case 2:
            startSimulation()
        case 3:
            stopSimulation()
        case 4:
            getAirports()
        case 5:
            getAircrafts()
        case 6:
            contact()
        case 7:
            devicePosition()
        case 8:
            requestTurbulenceAlertTiles()
        case 9:
            getTurbulence()
        case 10:
            getWeather()
        case 11:
            submitWeatherReport()
        default:
            break
        }
    }
}

// MARK: - YAMASEE

let altRange = Measurement(value: 0 * 1000, unit: UnitLength.feet)...Measurement(value: 52 * 1000, unit: UnitLength.feet)
let timeSpan: Int = 360

extension YamaseeViewController {
    
    func setupYamasee() {
        
        let apiKey = "API_KEY"
        let baseUrl = "BASE_URL"
        
        YamaseeCore.shared.setLogger(isOn: true, errorOn: true, infoOn: true, warningOn: true, networkOn: true)
        YamaseeCore.shared.delegate = self
        YamaseeCore.shared.start(apiKey: apiKey, baseUrl: baseUrl, env: .development)
        YamaseeCore.shared.setPushSimulatedEnabled(false)
    }
    
    func loginPartner() {
        
        guard !YamaseeCore.shared.isLoggedIn() else {
            AlertManager.showMessage(with: "Already logged in")
            return
        }
        
        Loader.show()
        
        let userId = "USER_ID" // your any user id
        let companyId = "COMPANY_ID" // provided by Yamasee
        
        YamaseeCore.shared.partnerLogin(userId: userId, companyId: companyId) { success, error in
            
            Loader.hide()
            
            if let error = error {
                AlertManager.showErrorMessage(with: error.localizedDescription)
                return
            }
            guard success else {
                AlertManager.showErrorMessage(with: "Login failed")
                return
            }
            AlertManager.showMessage(with: "Success")
        }
    }
    
    func logout() {
        
        if YamaseeCore.shared.isLoggedIn() {
            YamaseeCore.shared.logout()
            AlertManager.showMessage(with: "Success")
        }
        stopSimulation()
    }
    
    func startSimulation() {
        
        YamaseeCore.shared.setSimulatorMode(isLocationSimulatorOn: true)
    }
    
    func stopSimulation() {
        
        YamaseeCore.shared.setSimulatorMode(isLocationSimulatorOn: false)
    }
    
    func simulateLocation() {
        
        //        YamaseeCore.shared.simulatedLocation(location: location)
    }
    
    func getAirports() {
        
        let airports: [Airport] = YamaseeCore.shared.airports()
        print(airports)
        
        let json: String = YamaseeCore.shared.airports() // GeoJSON
        print(json)
    }
    
    func getAircrafts() {
        
        let aircrafts = YamaseeCore.shared.aircrafts()
        print(aircrafts.map { $0.description })
        
        let aircraft = YamaseeCore.shared.aircraft()
        print("set aircraft: \(String(describing: aircraft))")
        
        YamaseeCore.shared.setAircraft("B733")
    }
    
    func contact() {
        
        let text = ""
        let email = ""
        
        guard !text.isEmpty, !email.isEmpty else {
            AlertManager.showErrorMessage(with: "Error: text or email is empty")
            return
        }
        
        Loader.show()
        YamaseeCore.shared.contact(email: email, message: text) { success, error in
            Loader.hide()
            
            guard error == nil else {
                AlertManager.showErrorMessage(with: error?.localizedDescription)
                return
            }
            guard success else {
                AlertManager.showErrorMessage(with: "Unknown")
                return
            }
            AlertManager.showMessage(with: "Sent")
        }
    }
    
    func devicePosition() {
        
        guard !YamaseeCore.shared.isInPosition() else {
            AlertManager.showErrorMessage(with: "Device is already in position")
            return
        }
        
        YamaseeCore.shared.setAngle()
        
        AlertManager.showErrorMessage(with: "Device set in position")
    }
    
    func requestTurbulenceAlertTiles() {
        
        guard let location = LocationManager.shared.location else {
            return
        }
        
        let altitude: Measurement<UnitLength> = Measurement(value: location.altitude, unit: .meters)
        let timeSpan: Int = 360
        
        var turbulences: [TurbulenceItem] = []
        
        let tiles = YamaseeCore.shared.getAlertTiles(
            lat: location.coordinate.latitude,
            long: location.coordinate.longitude,
            altitude: altitude,
            heading: Measurement(value: location.course, unit: .degrees),
            timeSpan: timeSpan)
        turbulences = [tiles.alertTilesAbove, tiles.alertTilesAtAlt, tiles.alertTilesBelow].flatMap { $0 }
        
        print(turbulences)
    }
    
    func getTurbulence() {
        
        let json = YamaseeCore.shared.getTurbulenceGeoJson(altRange: altRange,
                                                           timeSpan: timeSpan,
                                                           zoomLevel: 1)
        print(json)
        
        let localTurbulenceTiles = YamaseeCore.shared.getOwnTurbulence(altRange: altRange,
                                                                       timeSpan: timeSpan,
                                                                       zoomLevel: 1)
        print(localTurbulenceTiles)
    }
    
    func getWeather() {
        
        var weatherItems: [Weather] = YamaseeCore.shared.getWeather(
            types: [.cb, .lightning],
            altRange: altRange,
            timeSpan: timeSpan,
            zoomLevel: 1)
        weatherItems += YamaseeCore.shared.getWeather(
            types: [.shear],
            altRange: altRange,
            timeSpan: timeSpan,
            zoomLevel: 1)
        weatherItems += YamaseeCore.shared.getOwnWeather(
            types: [.cb, .lightning],
            altRange: altRange,
            timeSpan: timeSpan,
            zoomLevel: 1)
        weatherItems += YamaseeCore.shared.getOwnWeather(
            types: [.shear],
            altRange: altRange,
            timeSpan: timeSpan,
            zoomLevel: 1)
        
        print(weatherItems)
    }
    
    func submitWeatherReport() {
        
        guard let location = LocationManager.shared.location else {
            return
        }
        
        YamaseeCore.shared.reportWeather(type: .shear, at: location)
        YamaseeCore.shared.reportWeather(type: .cb, at: location)
        YamaseeCore.shared.reportWeather(type: .lightning, at: location)
    }
}

// MARK: - YamaseeCoreDelegate

extension YamaseeViewController: YamaseeCoreDelegate {
    
    public func newTurbulenceData(serverUpdateTime: Int) {
        print("YM: newTurbulenceData serverUpdateTime: \(serverUpdateTime)")
    }
    
    public func newTrafficData(serverUpdateTime: Int) {
        print("YM: newTrafficData serverUpdateTime: \(serverUpdateTime)")
    }
    
    public func deviceAngleStatusChanged(isInAngle: Bool) {
        print("YM: deviceAngleStatusChanged isInAngle: \(isInAngle)")
    }
    
    func turbulenceDetected(newTurbulence: TurbulenceItem) {
        print("YM: turbulenceDetected newTurbulence: \(newTurbulence)")
    }
    
    func locationUpdated(to location: YMLocation) {
        print("YM: locationUpdated location: \(location)")
        
        if location.state == .dr {
            print("YM: in DR state")
        }
    }
    
    func ownTurbulenceChanged() {
        print("YM: own turbulence changed")
    }
    
    func newWeatherData(serverUpdateTime: Int) {
        print("YM: newWeatherData serverUpdateTime: \(serverUpdateTime)")
    }
    
    func ownWeatherChanged() {
        print("YM: own weather changed")
    }
    
    func airborneStatus(isAirborne: Bool) {
        print("YM: airborne status changed: \(isAirborne)")
    }
    
    func newAirportsData() {
        print("YM: new airports data")
    }
    
    func loginStatus(isLoggedIn: Bool) {
        print("YM: logged in status changed to: \(isLoggedIn)")
    }
}
