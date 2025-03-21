//
//  ViewController.swift
//  Demo
//
//  Created by Alex Kovalov on 17.02.2022.
//

import UIKit
import MapKit
import SkyPathSDK
import GEOSwift

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
    @IBOutlet weak var sdkVersionLabel: UILabel!
    
    // MARK: - Properties
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMap()
        
        assert(!SKYPATH_API_KEY.isEmpty)
        assert(!AIRLINE_ICAO.isEmpty)
        assert(!USER_ID.isEmpty)
        
        sdkVersionLabel.text = "SDK v\(SkyPath.shared.version)"
        
        setupSkyPath()
    }
    
    private func setupMap() {
        
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40, longitude: -90), span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30))
    }
    
    // MARK: - IBActions
    
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
        
        if mapView.currentZoomLevel >= 10 {
            SkyPath.shared.dataQuery.viewport = polygon
        }
        
        getTurbulence()
    }
}

// MARK: - SkyPath

extension ViewController {
    
    private func setupSkyPath() {
        
        SkyPath.shared.delegate = self
        SkyPath.shared.logger.level = .verbose
        
        SkyPath.shared.dataHistoryTime = .twoHours
        SkyPath.shared.dataQuery.types = [.turbulence]
        
        if let aircraft = SkyPath.shared.aircraft(byId: "B737") {
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
            
            if let error {
                print(error)
            }
            self?.startFlight()
            self?.setCorridor()
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
    
    private func setCorridor() {
        
        // KJFK-KIAD
        let corridor = [(-76.76, 37.43), (-72.55,39.50), (-72.21,40.06), (-72.26,41.33), (-72.64,41.86), (-73.51,42.28), (-74.16,42.26), (-78.15,40.46), (-79.10,39.20), (-78.80,37.96), (-77.72,37.30), (-76.76,37.43)]
            .map {
                CLLocationCoordinate2D(latitude: $0.1, longitude: $0.0) // corridor is [lng, lat]
            }
        SkyPath.shared.dataQuery.polygon = corridor
    }
    
    private func getTurbulence() {
        
        var query = TurbulenceQuery(
            type: .server,
            altRange: 0...52_000, // feet
            resultOptions: .geoJSON)
        if mapView.currentZoomLevel >= 10 {
            query.polygon = SkyPath.shared.dataQuery.viewport
        }
        do {
            let result = try SkyPath.shared.turbulence(with: query).get()
            let geoJSON = result.geoJSON
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.updateTurbulenceOnMap(with: geoJSON)
            }
        } catch {
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
        
        getTurbulence()
    }
    
    func didFailToFetchNewData(with error: any SkyPathSDK.SPError, type: SkyPathSDK.DataTypeOptions) {
        
        print("SkyPath did fail to fetch new data with error: \(error)")
    }
    
    func didChangeDevicePosition(_ inPosition: Bool, horizontal: Bool) {
        
        print("SkyPath device is \(inPosition ? "" : "not ")in position and \(horizontal ? "" : "not ")horizontal")
        
        // Turbulence data is not tracked when device in not in position or is horizontal.
        // Consider to show a notice here to properly position device in the cradle.
    }
    
    func didReceiveAlert(_ notification: NotificationResult) {

        print("SkyPath did find a turbulence alert")
        
        processNotification(notification)
    }
    
}

// MARK: - Alert

extension ViewController {
    
    private func getAlerts() {
        
        guard !SkyPath.shared.isMonitoringNotifications else { return }
        
        let query = NotificationQuery(altRange: 25000...52000, route: nil)
        SkyPath.shared.startMonitoringNotifications(with: query)
    }
    
    func processNotification(_ result: NotificationResult) {

        // TODO:
    }
}
