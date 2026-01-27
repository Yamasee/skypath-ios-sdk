//
//  SkyPathWrapper.swift
//  Demo
//
//  Created by Alex Kovalov on 26.03.2025.
//

import UIKit
import CoreLocation
import SkyPathSDK

let SKYPATH_API_KEY = ""
let AIRLINE_ICAO = ""
let USER_ID = ""

class SkyPathWrapper {

    static let shared = SkyPathWrapper()
    private let simulationManager = SimulationLocationManager()

    var version: String {
        SkyPath.shared.version
    }
    
    var onUpdate: ((UpdatesType) -> Void)?
    
    enum UpdatesType {
        
        case turbulenceUpdate,
             oneLayerUpdate,
             notificationUpdate(NotificationResult)
    }
    
    var currentServerEnv: Environment {
        
        get {
            guard let data = UserDefaults.standard.data(forKey: "LastUsedEnvironment"),
                  let env = try? JSONDecoder().decode(Environment.self, from: data) else {
                return .dev(serverUrl: nil)
            }
            return env
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: "LastUsedEnvironment")
            let isStarted = SkyPath.shared.isStarted
            if isStarted { stop() }
            start()
        }
    }
    
    func setup() {

        precondition(SKYPATH_API_KEY.isEmpty == false, "Please provide your SkyPath API key")
        precondition(AIRLINE_ICAO.isEmpty == false, "Please provide your airline ICAO code")
        precondition(USER_ID.isEmpty == false, "Please provide your user ID")
        
        SkyPath.shared.delegate = self
        SkyPath.shared.logger.level = .verbose

        SkyPath.shared.dataHistoryTime = .twoHours
        SkyPath.shared.dataQuery.types = [.turbulence]

        if let aircraft = SkyPath.shared.aircraft(byId: "B737") {
            SkyPath.shared.aircraft = aircraft
        }

        start()
    }
    
    func setDataQueryTypes(_ types: SkyPathSDK.DataTypeOptions) {
        
        SkyPath.shared.dataQuery.types = types
        SkyPath.shared.dataQuery.viewportTypes = types
    }

    private func start() {

        SkyPath.shared.start(apiKey: SKYPATH_API_KEY, airline: AIRLINE_ICAO, userId: USER_ID, env: currentServerEnv) { [weak self] error in

            if let error {
                print(error)
                return
            }

            self?.startFlight()
        }
    }

    func stop() {

        SkyPath.shared.stop()
    }
    
    func startFlight() {

        let flight = Flight(dep: "KJFK", dest: "KMIA", fnum: "TEST")
        SkyPath.shared.setFlight(flight)
        setCorridor()
    }

    func endFlight() {

        SkyPath.shared.setFlight(nil)
    }

    var corridor:[CLLocationCoordinate2D] { [.kjfkAirport, .kiadAirport] }
    
    func setCorridor() {

        let corridor = corridor.geodesic.buffer(widthNM: 100)
        
        SkyPath.shared.dataQuery.polygon = corridor
    }

    func getTurbulence(showSmooth: Bool = true) -> String? {

        var query = TurbulenceQuery(
            type: .server,
            altRange: 0...52_000,
            resultOptions: .geoJSON)
        if !showSmooth {
            query.minSev = .light
        }
        do {
            let result = try SkyPath.shared.turbulence(with: query).get()
            let geoJSON = result.geoJSON
            return geoJSON
        } catch {
            print(error)
            return nil
        }
    }
    
    func getOneLayer(showSmooth: Bool = true) -> String? {
        
        var query = OneLayerQuery(
            altRange: 0...52_000,
            resultOptions: .geoJSON,
            dataHistoryTime: .twoHours)

        if !showSmooth {
            query.minSev = .light
        }
        do {
            let result = try SkyPath.shared.oneLayer(with: query).get()
            let geoJSON = result.geoJSON
            return geoJSON
        } catch {
            print(error)
            return nil
        }
    }

    func setViewport(_ viewport: [CLLocationCoordinate2D]) {
        
        SkyPath.shared.dataQuery.viewport = viewport
    }

    func color(ofSev sev: Int) -> UIColor? {

        return TurbulenceSeverity(rawValue: sev)?.colorWithOpacity
    }
}

// MARK: - SkyPathDelegate

extension SkyPathWrapper: SkyPathDelegate {

    func didUpdateRecordingStatus(to recording: Bool) {

        if recording {
            print("SkyPath did start recording")
        } else {
            print("SkyPath did stop recording")

            // Call `start()` again to continue recording if needed.
        }
    }

    func didReceiveNewTurbulenceData(areaType: DataAreaType) {

        print("SkyPath did receive new turbulence data")

        onUpdate?(.turbulenceUpdate)
    }
    
    func didReceiveNewOneLayer(areaType: DataAreaType) {
        
        print("SkyPath did receive new oneLayer data")
        
        onUpdate?(.oneLayerUpdate)
    }

    func didFailToFetchNewData(with error: any SkyPathSDK.SPError, type: SkyPathSDK.DataTypeOptions) {

        print("SkyPath did fail to fetch new data with error: \(error)")
    }

    func didChangeDevicePosition(_ inPosition: Bool, horizontal: Bool) {

        print("SkyPath device is \(inPosition ? "" : "not ")in position and \(horizontal ? "" : "not ")horizontal")

        // Turbulence data is not tracked when device in not in position or is horizontal.
        // Consider to show a notice here to properly position device in the cradle.
    }

    func didReceiveNotification(_ notification: NotificationResult) {

        print("SkyPath did find a turbulence notification")

        onUpdate?(.notificationUpdate(notification))
    }

    func didUpdateConfig() {
        
        print("SkyPath did update config")
    }
}

// MARK: - Notifications

extension SkyPathWrapper {

    func startMonitoringNotifications(altRange:ClosedRange<Double>, route:[CLLocationCoordinate2D]? = nil) {

        guard !SkyPath.shared.isMonitoringNotifications else { return }

        let query = NotificationQuery(altRange: altRange, route: route)
        SkyPath.shared.startMonitoringNotifications(with: query)
    }
}

// MARK: - Environment

extension SkyPathWrapper {

    var currentServerEnvStr: String {
        
        switch currentServerEnv {
        case .dev(serverUrl: let url):
            return url ?? currentServerEnv.baseUrl
        case .staging(serverUrl: let url):
            return url ?? currentServerEnv.baseUrl
        default: return ""
        }
    }
}

// MARK: - SimulationLocationManager

extension SkyPathWrapper {
    
    var isSimulationRunning: Bool {
        
        simulationManager.isRunning
    }
    
    func startFlightSimulation(with coordinates: [CLLocationCoordinate2D],
                               delegate: SimulationLocationManagerDelegate) {
        
        SkyPath.shared.enableSimulation(true)
        SkyPath.shared.enablePushSimulated(false)
        let altFtRange: ClosedRange<Double> = 30000...35000
        let altitudeFt: Double = 39000
        simulationManager.start(with: coordinates, altitudeFt: altitudeFt, delegate: delegate)
        startMonitoringNotifications(altRange: altFtRange, route: simulationManager.route)
    }
    
    func stopFlightSimulation() {
        
        SkyPath.shared.enableSimulation(false)
        SkyPath.shared.stopMonitoringNotifications()
        simulationManager.stop()
    }
}
