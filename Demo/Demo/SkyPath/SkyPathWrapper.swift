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

    var version: String {
        SkyPath.shared.version
    }
    var onTurbulenceUpdate: (() -> Void)?

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

    private func start() {

        SkyPath.shared.start(apiKey: SKYPATH_API_KEY, airline: AIRLINE_ICAO, userId: USER_ID, env: .dev(serverUrl: nil)) { [weak self] error in

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

    func setCorridor() {

        // KJFK-KIAD
        let corridor = [(-76.76, 37.43), (-72.55,39.50), (-72.21,40.06), (-72.26,41.33), (-72.64,41.86), (-73.51,42.28), (-74.16,42.26), (-78.15,40.46), (-79.10,39.20), (-78.80,37.96), (-77.72,37.30), (-76.76,37.43)]
            .map {
                CLLocationCoordinate2D(latitude: $0.1, longitude: $0.0) // corridor is [lng, lat]
            }
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

        onTurbulenceUpdate?()
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

        processNotification(notification)
    }
}

// MARK: - Notifications

extension SkyPathWrapper {

    func getNotifications() {

        guard !SkyPath.shared.isMonitoringNotifications else { return }

        let query = NotificationQuery(altRange: 25000...52000, route: nil)
        SkyPath.shared.startMonitoringNotifications(with: query)
    }

    func processNotification(_ result: NotificationResult) {

        // TODO:
    }
}
