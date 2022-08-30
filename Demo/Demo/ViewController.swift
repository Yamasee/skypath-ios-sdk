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
        mapView.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 300_000)
    }

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
                self.mapView.addOverlay(multiPolygon)
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
            renderer.strokeColor = sev.borderColor
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
        SkyPath.shared.dataQuery.types = .turbulence
        SkyPath.shared.dataQuery.sevs = TurbulenceSeverity.allCases

        if let aircraft = SkyPath.shared.aircraft(byId: "B38M") {
            SkyPath.shared.aircraft = aircraft
        }

        startSkyPath()
    }

    private func startSkyPath() {

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

        let flight = Flight(
            dep: "KJFK",
            dest: "KMIA",
            fnum: "TEST")
        SkyPath.shared.startFlight(flight)
    }

    private func endFlight() {

        SkyPath.shared.endFlight()
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

    func didReceiveNewTurbulenceData() {

        print("SkyPath did receive new turbulence data")

        // Query for the updated turbulence and show on the map.
        // See `Get Turbulence` section of this guide.

        getTurbulence()
    }

    func didFailToFetchNewData(with error: GeneralError) {

        print("SkyPath did fail to fetch new data with error: " + error.localizedDescription)
    }

    func didChangeDevicePosition(_ inPosition: Bool, horizontal: Bool) {

        print("SkyPath device is \(inPosition ? "" : "not ")in position and \(horizontal ? "" : "not ")horizontal")

        // Turbulence data is not tracked when device in not in position or is horizontal.
        // Consider to show a notice here to properly position device in the cradle.
    }
}
