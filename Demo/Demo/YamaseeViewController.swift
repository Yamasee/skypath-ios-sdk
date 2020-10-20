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
            login()
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
            forgotPassword()
        case 8:
            devicePosition()
        case 9:
            requestTurbulenceAlertTiles()
        case 10:
            getTurbulence()
        case 11:
            getWeather()
        case 12:
            submitWeatherReport()
        case 13:
            getFlights()
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
        
        let apiKey = "YAMASEE_API_KEY"
        let baseUrl = "YAMASEE_BASE_URL"
        let dataUrl = "YAMASEE_DATA_URL"
        
        YamaseeCore.shared.start(apiKey: apiKey, baseUrl: baseUrl, dataUrl: dataUrl)
        YamaseeCore.shared.setLogger(isOn: true, isSymbol: true, errorOn: true, infoOn: true, warningOn: true, networkOn: true) { message in
            print(message)
        }
        YamaseeCore.shared.setPushSimulatedEnabled(false)
        YamaseeCore.shared.delegate = self
    }
    
    func login() {
        
        guard !YamaseeCore.shared.isLoggedIn() else {
            AlertManager.showMessage(with: "Already logged in")
            return
        }
        
        Loader.show()
        
        YamaseeCore.shared.partnerLogin(userId: "Demo", companyId: "Yamasee") { success, error in
            
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
        YamaseeCore.shared.stopSimulationNoDR()
    }
    
    func simulateLocation() {
        
        //        YamaseeCore.shared.simulatedLocation(location: location)
    }
    
    func getAirports() {
        
        let airports: [Airport] = YamaseeCore.shared.getAirports()
        print(airports)
        
        let json: String = YamaseeCore.shared.getAirports() // GeoJSON
        print(json)
    }
    
    func getAircrafts() {
        
        let aircrafts = YamaseeCore.shared.getAircraftTypes()
        print(aircrafts.map { $0.description })
        
        let aircraft = YamaseeCore.shared.getAircraft()
        YamaseeCore.shared.setAircraft(aircraft: aircraft)
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
    
    func forgotPassword() {
        
        Loader.show()
        let userId = ""
        YamaseeCore.shared.forgotPassword(userId: userId) { _, error in
            
            Loader.hide()
            
            if let error = error {
                switch error {
                case .userIdInvalid:
                    break
                case .general(let error):
                    AlertManager.showErrorMessage(with: error.localizedDescription)
                    return
                @unknown default:
                    break
                }
            }
            AlertManager.showMessage(with: "Success")
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
        
        var weatherItems: [WeatherItem] = YamaseeCore.shared.getWeatherByTypes(
            weatherTypes: [.cb, .lightning],
            altRange: altRange,
            timeSpan: timeSpan,
            zoomLevel: 1)
        weatherItems += YamaseeCore.shared.getWeatherByTypes(
            weatherTypes: [.shear],
            altRange: altRange,
            timeSpan: timeSpan,
            zoomLevel: 1)
        weatherItems += YamaseeCore.shared.getOwnWeatherByTypes(
            weatherTypes: [.cb, .lightning],
            altRange: altRange,
            timeSpan: timeSpan,
            zoomLevel: 1)
        weatherItems += YamaseeCore.shared.getOwnWeatherByTypes(
            weatherTypes: [.shear],
            altRange: altRange,
            timeSpan: timeSpan,
            zoomLevel: 1)
        
        print(weatherItems)
    }
    
    func submitWeatherReport() {
        
        guard let coordinate = LocationManager.shared.location?.coordinate,
              let altitude = LocationManager.shared.location?.altitude else {
            return
        }
        
        YamaseeCore.shared.reportShear(lat: coordinate.latitude,
                                       lng: coordinate.longitude,
                                       alt: Measurement(value: altitude, unit: .meters))
        
        YamaseeCore.shared.reportCB(lat: coordinate.latitude,
                                    lng: coordinate.longitude,
                                    alt: Measurement(value: altitude, unit: .meters))
        
        YamaseeCore.shared.reportLightning(lat: coordinate.latitude,
                                           lng: coordinate.longitude,
                                           alt: Measurement(value: altitude, unit: .meters))
    }
    
    func getFlights() {
        
        YamaseeCore.shared.setFlightNumber(flightNumber: "")
        
        guard YamaseeCore.shared.isRoutingEnabled() else {
            return
        }
        
        let from = Int(Date().timeIntervalSince1970)
        let to = Int((Date() + 3 * 86_400).timeIntervalSince1970)
        
        YamaseeCore.shared.getFlights(from: from, to: to) { data, _, error in
            
            guard error == nil else {
                AlertManager.showErrorMessage(with: error?.localizedDescription)
                return
            }
            guard let data = data else {
                AlertManager.showErrorMessage(with: "Unknown")
                return
            }
            
            //            do {
            //                let flightPlans = try JSONDecoder().decode([FlightPlan].self, from: data)
            //            } catch {
            //                print(error)
            //            }
        }
    }
    
    //    private func getWaypoints(for flightPlan: FlightPlan, completion: @escaping (_ waypoints: [FlightWaypoint]) -> Void) {
    //
    //        YamaseeCore.shared.getWaypoints(flightPlanId: flightPlan.flightPlanId) { data, _, error in
    //
    //            guard error == nil else {
    //                AlertManager.showErrorMessage(with: error?.localizedDescription)
    //                return
    //            }
    //            guard let data = data else {
    //                AlertManager.showErrorMessage(with: "Unknown")
    //                return
    //            }
    //            do {
    //                let waypoints = try JSONDecoder().decode([FlightWaypoint].self, from: data)
    //            } catch {
    //                print(error)
    //            }
    //        }
    //    }
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
    
    func yamaseeNewLocationUpdate(location: YamaseeLocation) {
        print("YM: yamaseeNewLocationUpdate location: \(location)")
        
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
