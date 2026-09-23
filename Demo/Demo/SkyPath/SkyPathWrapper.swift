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
                return .staging(serverUrl: nil)
            }
            return env
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            // Switching the environment at runtime is not supported, it's applied on the next app launch.
            UserDefaults.standard.set(data, forKey: "LastUsedEnvironment")
        }
    }
    
    func setup() {

        precondition(SKYPATH_API_KEY.isEmpty == false, "Please provide your SkyPath API key")
        precondition(AIRLINE_ICAO.isEmpty == false, "Please provide your airline ICAO code")
        precondition(USER_ID.isEmpty == false, "Please provide your user ID")
        
        SkyPath.shared.delegate = self
        SkyPath.shared.loggerLevel = .verbose

        SkyPath.shared.dataHistoryTime = .fourHours

        do {
            try SkyPath.shared.updateFetchConfig {
                $0.types = [.observations]
                $0.aircraftICAO = "B737"
            }
        } catch {
            print(error)
        }

        start()
    }
    
    func setDataQueryTypes(_ types: Set<SkyPathSDK.DataType>) {
        
        do {
            try SkyPath.shared.updateFetchConfig {
                $0.types = types
                $0.viewportTypes = types
            }
        } catch {
            print(error)
        }
    }

    private func start() {

        let config = AuthConfig(apiKey: SKYPATH_API_KEY, companyId: AIRLINE_ICAO, userId: USER_ID, env: currentServerEnv)
        SkyPath.shared.initialize(with: config) { [weak self] error in

            if let error {
                print(error)
                return
            }

            self?.startFlight()
        }
    }

    func startFlight() {

        let flight = Flight(dep: "KJFK", dest: "KMIA", num: "TEST")
        SkyPath.shared.setFlight(flight)
        setCorridor()
    }

    func endFlight() {

        SkyPath.shared.setFlight(nil)
    }

    var corridor:[CLLocationCoordinate2D] { [.kjfkAirport, .kiadAirport] }
    
    func setCorridor() {

        let corridor = corridor.geodesic.buffer(widthNM: 100)
        
        do {
            try SkyPath.shared.updateFetchConfig { $0.polygon = corridor }
        } catch {
            print(error)
        }
    }

    func getTurbulence(showSmooth: Bool = true) -> String? {

        var query = ObservationsQuery(
            type: .server,
            altRange: 0...52_000,
            resultOptions: .geoJSON)
        query.route = corridor
        query.routeWidth = 100
        if !showSmooth {
            query.minSev = .light
        }
        do {
            let result = try SkyPath.shared.observations(with: query).get()
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
        
        do {
            try SkyPath.shared.updateFetchConfig { $0.viewport = viewport }
        } catch {
            print(error)
        }
    }

    func color(ofSev sev: Int) -> UIColor? {

        return TurbulenceSeverity(rawValue: sev)?.demoColorWithOpacity
    }
}

// MARK: - SkyPathDelegate

extension SkyPathWrapper: SkyPathDelegate {

    func didUpdateRecordingState(to state: RecordingState) {

        let recording = state == .recording
        if recording {
            print("SkyPath did start recording")
        } else {
            print("SkyPath did stop recording")

            // Call `start()` again to continue recording if needed.
        }

        let inPosition = state == .recording
        let horizontal = state == .horizontal
        print("SkyPath device is \(inPosition ? "" : "not ")in position and \(horizontal ? "" : "not ")horizontal")

        // Turbulence data is not tracked when device in not in position or is horizontal.
        // Consider to show a notice here to properly position device in the cradle.
    }

    func didReceiveNewObservationsData(areaType: DataAreaType) {

        print("SkyPath did receive new turbulence data")

        onUpdate?(.turbulenceUpdate)
    }
    
    func didReceiveNewOneLayer(areaType: DataAreaType) {
        
        print("SkyPath did receive new oneLayer data")
        
        onUpdate?(.oneLayerUpdate)
    }

    func didFail(with error: any SkyPathSDK.SPError, dataType: SkyPathSDK.DataType?) {

        print("SkyPath did fail to fetch new data with error: \(error)")
    }

    func didReceiveNotification(_ notification: NotificationResult) {

        print("SkyPath did find a turbulence notification")

        onUpdate?(.notificationUpdate(notification))
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
        
        SkyPath.shared.testing.enableSimulation(true)
        SkyPath.shared.testing.enablePushSimulated(false)
        let altFtRange: ClosedRange<Double> = 36000...40000
        let altitudeFt: Double = 38000
        simulationManager.start(with: coordinates, altitudeFt: altitudeFt, delegate: delegate)
        startMonitoringNotifications(altRange: altFtRange, route: simulationManager.route)
    }
    
    func stopFlightSimulation() {
        
        SkyPath.shared.testing.enableSimulation(false)
        SkyPath.shared.stopMonitoringNotifications()
        simulationManager.stop()
    }
}
