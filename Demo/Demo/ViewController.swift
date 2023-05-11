//
//  ViewController.swift
//  Demo
//
//  Created by Alex Kovalov on 17.02.2022.
//

import UIKit
import MapKit
import SkyPathSDK

// MARK: - SkyPath Auth

let SKYPATH_API_KEY = ""
let AIRLINE_ICAO = ""
let USER_ID = ""

// MARK: - ViewController

class ViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var turbTypeButton: UIButton!
    @IBOutlet weak var themeTypeButton: UIButton!

    // MARK: - Properties

    private var polygonsEnabled: Bool = false {
        didSet {
            polygonsEnabled ? getTurbulencePolygons() : getTurbulence()
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMap()

        assert(!SKYPATH_API_KEY.isEmpty)
        assert(!AIRLINE_ICAO.isEmpty)
        assert(!USER_ID.isEmpty)

        setupSkyPath()
    }

    private func setupMap() {

        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40, longitude: -90), span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30))
    }

    // MARK: - IBActions

    @IBAction func turbTypeButtonTapped(_ sender: UIButton) {

        polygonsEnabled.toggle()
    }

    @IBAction func themeTypeButtonTapped(_ sender: UIButton) {

        overrideUserInterfaceStyle = overrideUserInterfaceStyle == .dark ? .light : .dark
    }
}

// MARK: - Map Data

extension ViewController {

    private func updateTurbulenceOnMap(with geoJSON: String) {

        guard let data = geoJSON.data(using: .utf8),
              let objs = try? MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature]
        else {
            return
        }

        var polygons: [TurbulenceSeverity: [MKPolygon]] = [:]

        for obj in objs {

            guard  let propsData = obj.properties,
                   let props = try? JSONSerialization.jsonObject(with: propsData, options: .fragmentsAllowed) as? [String: Any],
                   let sevInt = props["sev"] as? Int,
                   let sev = TurbulenceSeverity(rawValue: sevInt)
            else {
                return
            }

            var objPolygons: [MKPolygon] = []
            for geo in obj.geometry {
                if let polygon = geo as? MKPolygon {
                    objPolygons.append(polygon)
                }
            }

            if polygons[sev] == nil {
                polygons[sev] = objPolygons
            } else {
                polygons[sev]?.append(contentsOf: objPolygons)
            }
        }

        DispatchQueue.main.async {

            self.mapView.removeOverlays(self.mapView.overlays)

            for (sev, sevPolygons) in polygons {

                let multiPolygon = MKMultiPolygon(sevPolygons)
                multiPolygon.title = "\(sev.rawValue)"
                self.mapView.addOverlay(multiPolygon, level: .aboveLabels)
            }
        }
    }

    private func updateTurbulencePolygonsOnMap(with geoJSON: String) {

        if geoJSON.isEmpty {
            SkyPath.shared.fetchData(refresh: true)
            return
        }

        guard let data = geoJSON.data(using: .utf8),
              let objs = try? MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature]
        else {
            return
        }

        var polygons: [TurbulenceSeverity: [MKMultiPolygon]] = [:]

        for obj in objs {

            guard  let propsData = obj.properties,
                   let props = try? JSONSerialization.jsonObject(with: propsData, options: .fragmentsAllowed) as? [String: Any],
                   let sevInt = props["sev"] as? Int,
                   let sev = TurbulenceSeverity(rawValue: sevInt)
            else {
                return
            }

            var objPolygons: [MKMultiPolygon] = []
            for geo in obj.geometry {
                if let polygon = geo as? MKMultiPolygon {
                    objPolygons.append(polygon)
                }
            }

            if polygons[sev] == nil {
                polygons[sev] = objPolygons
            } else {
                polygons[sev]?.append(contentsOf: objPolygons)
            }
        }

        DispatchQueue.main.async {

            self.mapView.removeOverlays(self.mapView.overlays)

            for (sev, sevPolygons) in polygons {

                for multiPolygon in sevPolygons {
                    multiPolygon.title = "\(sev.rawValue)"
                    self.mapView.addOverlay(multiPolygon)
                }
            }
        }
    }

}

// MARK: - MKMapViewDelegate

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let multiPolygon = overlay as? MKMultiPolygon,
           let sevStr = multiPolygon.title,
           let sevInt = Int(sevStr),
           let sev = TurbulenceSeverity(rawValue: sevInt) {

            let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
            renderer.fillColor = sev.colorWithOpacity
            renderer.strokeColor = sev == .none ? .black.withAlphaComponent(0.2) : sev.colorWithOpacity
            renderer.lineWidth = 0.5
            return renderer
        }

        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

        let region = MKCoordinateRegion(mapView.visibleMapRect)
        var polygon = region.boundingBoxCoordinates
        polygon.append(polygon[0])
        
        // to make data fetch smaller
        if mapView.currentZoomLevel >= 8 {
            SkyPath.shared.dataQuery.viewport = polygon
        }
    }

}

// MARK: - SkyPath

extension ViewController {

    private func setupSkyPath() {

        SkyPath.shared.delegate = self
        SkyPath.shared.logger.level = .info

        SkyPath.shared.dataHistoryTime = .twoHours
        SkyPath.shared.dataUpdateFrequency = .fast
        SkyPath.shared.dataQuery.types = [.turbulence, .turbulencePolygons]
        SkyPath.shared.dataQuery.sevs = TurbulenceSeverity.allCases

        if let aircraft = SkyPath.shared.aircraft(byId: "B737") {
            SkyPath.shared.aircraft = aircraft
        }

        startSkyPath()
    }

    private func startSkyPath() {
        guard !SkyPath.shared.isStarted else {
            return
        }
        SkyPath.shared.start(
            apiKey: SKYPATH_API_KEY, // provided by SkyPath
            airline: AIRLINE_ICAO, // ICAO code of the airline
            userId: USER_ID,
            env: .dev(serverUrl: nil)) // airline user account id
        { [weak self] error in

            if let error = error {
                print(error)
            }
            self?.startFlight()
        }
    }

    private func stopSkyPath() {

        SkyPath.shared.stop()
    }

    private func startFlight() {

        let flight = Flight(dep: "KJFK", dest: "KMIA", fnum: "TEST")
        SkyPath.shared.setFlight(flight)
    }

    private func endFlight() {

        SkyPath.shared.setFlight(nil)
    }

    private func getTurbulence() {

        let query = TurbulenceQuery(
            type: .server,
            altRange: 0...52_000, // feet
            resultOptions: .geoJSON)

        let result = SkyPath.shared.turbulence(with: query)
        switch result {
        case .success(let turbResult):
            let geoJSON = turbResult.geoJSON
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.updateTurbulenceOnMap(with: geoJSON)
            }
        case .failure(let error):
            print(error)
        }
    }

    private func getTurbulencePolygons() {

        let result = SkyPath.shared.turbulencePolygons(with: TurbulencePolygonsQuery(altRange: 0...52_000))
        switch result {
        case .success(let turbResult):
            let geoJSON = turbResult.geoJSON
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.updateTurbulencePolygonsOnMap(with: geoJSON)
            }
        case .failure(let error):
            print(error)
        }
    }
}

// MARK: - SkyPathDelegate

extension ViewController: SkyPathDelegate {

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

        if !polygonsEnabled {
            getTurbulence()
        }
    }

    func didReceiveNewTurbulencePolygons() {

        print("SkyPath did receive new turbulence polygons data")

        if polygonsEnabled {
            getTurbulencePolygons()
        }
    }

    func didFailToFetchNewData(with error: SPError) {

        print("SkyPath did fail to fetch new data with error: \(error)")
    }

    func didChangeDevicePosition(_ inPosition: Bool, horizontal: Bool) {

        print("SkyPath device is \(inPosition ? "" : "not ")in position and \(horizontal ? "" : "not ")horizontal")

        // Turbulence data is not tracked when device in not in position or is horizontal.
        // Consider to show a notice here to properly position device in the cradle.
    }

    func didReceiveAlert(_ alert: AlertResult) {

        print("SkyPath did find a turbulence alert")

        processAlert(alert)
    }

}

// MARK: - Alert

extension ViewController {

    private func getAlerts() {

        guard !SkyPath.shared.isMonitoringAlerts else {
            return
        }
        let query = AlertQuery(altRange: 25000...52000, route: nil)
        SkyPath.shared.startMonitoringAlerts(with: query)
    }

    func processAlert(_ alertResult: AlertResult) {

        // TODO:
    }
}
