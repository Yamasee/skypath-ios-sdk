//
//  MapViewController.swift
//  Demo
//
//  Created by Alex Kovalov on 17.02.2022.
//

import UIKit
import MapKit

// MARK: - ViewController

class MapViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var themeTypeButton: UIButton!
    @IBOutlet weak var sdkVersionLabel: UILabel!

    // MARK: - Properties

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMap()

        SkyPathWrapper.shared.setup()
        SkyPathWrapper.shared.onTurbulenceUpdate = { [weak self] in
            self?.showTurbulence()
        }
        sdkVersionLabel.text = "SDK v\(SkyPathWrapper.shared.version)"
    }

    // MARK: - Setup

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

    // MARK: - Actions

    private func showTurbulence() {

        let showSmooth = mapView.currentZoomLevel >= 9

        if let geoJSON = SkyPathWrapper.shared.getTurbulence(showSmooth: showSmooth) {
            updateTurbulenceOnMap(with: geoJSON)
        }
    }
}

// MARK: - Map Data

extension MapViewController {

    private func updateTurbulenceOnMap(with geoJSON: String) {

        guard let data = geoJSON.data(using: .utf8),
              let objs = try? MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature] else {
            return
        }

        var polygons: [Int: [MKPolygon]] = [:]

        for obj in objs {

            guard let propsData = obj.properties,
                  let props = try? JSONSerialization.jsonObject(with: propsData, options: .fragmentsAllowed) as? [String: Any],
                  let sev = props["sev"] as? Int else {
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

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            self.mapView.removeOverlays(self.mapView.overlays)

            for (sev, sevPolygons) in polygons {

                let multiPolygon = MKMultiPolygon(sevPolygons)
                multiPolygon.title = "\(sev)"
                self.mapView.addOverlay(multiPolygon, level: .aboveLabels)
            }
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let multiPolygon = overlay as? MKMultiPolygon,
           let sevStr = multiPolygon.title,
           let sev = Int(sevStr) {

            let renderer = MKMultiPolygonRenderer(multiPolygon: multiPolygon)
            renderer.fillColor = SkyPathWrapper.shared.color(ofSev: sev)
            renderer.strokeColor = sev == 0 ? .black.withAlphaComponent(0.2) : renderer.fillColor
            renderer.lineWidth = 0.5
            return renderer
        }

        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {

        let region = MKCoordinateRegion(mapView.visibleMapRect)
        var polygon = region.boundingBoxCoordinates
        polygon.append(polygon[0])

        SkyPathWrapper.shared.setViewport(polygon)
        showTurbulence()
    }
}
