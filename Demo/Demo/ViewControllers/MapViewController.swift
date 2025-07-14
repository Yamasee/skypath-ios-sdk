//
//  MapViewController.swift
//  Demo
//
//  Created by Alex Kovalov on 17.02.2022.
//

import UIKit
import MapKit
import SkyPathSDK

// MARK: - ViewController

class MapViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var sdkVersionLabel: UILabel!
    @IBOutlet weak var layersButton: UIButton!
    @IBOutlet weak var flightSimulationButton: UIButton! {
        didSet {
            updateFlightSimulationBtnIcon()
        }
    }
    
    @IBOutlet weak var layersTableView: UITableView! {
        didSet {
            layersTableView.isHidden = true
            layersTableView.delegate = self
            layersTableView.dataSource = self
            layersTableView.layer.cornerRadius = 8
        }
    }
    
    // MARK: - Properties
    
    private var selectedLayerIdx = 0 {
        didSet {
            reloadLayersData()
        }
    }
    
    private let minSmoothZoomLevel = 9
    var skyPathLayers: [DataTypeOptions] = [.turbulence, .oneLayer]
    var selectedLayer: DataTypeOptions { skyPathLayers[selectedLayerIdx] }
    private let turbulenceClusterer = SkyPathSDK.TurbulenceClusterer(options: .init())

    private let dataQueue = DispatchQueue(label: "skypath.demo.data")

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupMap()
        
        SkyPathWrapper.shared.setup()
        
        setupUpdatesActions()
        
        sdkVersionLabel.text = "SDK v\(SkyPathWrapper.shared.version)"
    }
    
    // MARK: - Setup
    
    private func setupMap() {
        
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40, longitude: -90), span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 30))
    }
    
    private func setupUpdatesActions() {
        
        SkyPathWrapper.shared.onUpdate = { [weak self] update in
            
            guard let self else { return }
            
            switch update {
                
            case .turbulenceUpdate:
                
                self.showTurbulence()
                
            case .oneLayerUpdate:
                
                self.showOneLayer()
                
            case .notificationUpdate(let notificationResult):
                
                var items = [any SkyPathSDK.TurbulenceItemable]()
                switch selectedLayer {
                case .turbulence:
                    items = notificationResult.turbulence
                case .oneLayer:
                    items = notificationResult.oneLayer
                default:
                    return
                }
                
                items = items.filter { $0.sev != .none }
                
                guard !items.isEmpty,
                      let selectedItem = processNotificationResult(items: items) else { return }
                
                self.showNotification(selectedItem)
            }
        }
    }
    
    /// Processes a list of turbulence items and returns the most severe one from the first unnotified cluster.
    /// Marks the selected cluster as notified to prevent reprocessing in the future.
    /// - Parameter items: A list of turbulence items to cluster and evaluate.
    /// - Returns: The nearest maximum severity item from the first unnotified cluster, or nil if none found.
    private func processNotificationResult(items: [any SkyPathSDK.TurbulenceItemable]) -> TurbulenceItem? {
        
        turbulenceClusterer.process(turbulence: items)
        
        let selectedCluster = turbulenceClusterer.clusters.first(where: { [weak self] in
            self?.turbulenceClusterer.isNotified(cluster: $0) == false
        })
        
        guard let selectedCluster,
              let selectedItem = selectedCluster.nearestMaxSevTurbulence else { return nil }
        
        turbulenceClusterer.notified(cluster: selectedCluster)
        return selectedItem
    }
    
    // MARK: - IBActions
    
    @IBAction func startFlightSimulationTapped(_ sender: UIButton) {
        
        toggleFlightSimulation()
    }
    
    @IBAction func settingsButtonTapped(_ sender: UIButton) {
        
        showSettingsAlert(sender: sender)
    }
    
    @IBAction func layersButtonTapped(_ sender: UIButton) {
        
        layersTableView.isHidden.toggle()
    }
    
    // MARK: - Actions
    
    private func switchThemeType() {
        
        overrideUserInterfaceStyle = overrideUserInterfaceStyle == .dark ? .light : .dark
    }
    
    private func showDomainSelector(_ sender: UIButton?) {
        
        let alert = DomainSelectorAlert(sourceView: sender, parentVC: self)
        alert.present()
    }
    
    private func showTurbulence() {
        
        let showSmooth = mapView.currentZoomLevel >= minSmoothZoomLevel
        dataQueue.async { [weak self] in
            if let geoJSON = SkyPathWrapper.shared.getTurbulence(showSmooth: showSmooth) {
                self?.updateTurbulenceOnMap(with: geoJSON)
            }
        }
    }
    
    private func showOneLayer() {
        
        let showSmooth = mapView.currentZoomLevel >= minSmoothZoomLevel
        dataQueue.async { [weak self] in
            if let geoJSON = SkyPathWrapper.shared.getOneLayer(showSmooth: showSmooth) {
                self?.updateTurbulenceOnMap(with: geoJSON)
            }
        }
    }
    
    private func showCurrentLayerData() {
        
        switch selectedLayer {
        case .turbulence:
            showTurbulence()
        case .oneLayer:
            showOneLayer()
        default: break
        }
    }
    
    private func updateFlightSimulationBtnIcon() {
        
        let image = SkyPathWrapper.shared.isSimulationRunning ? UIImage(systemName: "stop.fill") : UIImage(named: "auto_cur_selected")
        flightSimulationButton.setImage(image, for: .normal)
    }
    
    private func reloadLayersData() {
        
        SkyPathWrapper.shared.setDataQueryTypes(selectedLayer)
        refreshMap()
        layersTableView.reloadData()
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
            
            self.mapView.removeOverlays(self.mapView.overlays.filter { $0 is MKMultiPolygon })
            
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
        
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.7)
            renderer.lineWidth = 10
            return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        refreshMap()
    }
    
    private func refreshMap() {
        
        let region = MKCoordinateRegion(mapView.visibleMapRect)
        var polygon = region.boundingBoxCoordinates
        polygon.append(polygon[0])
        
        SkyPathWrapper.shared.setViewport(polygon)
        showCurrentLayerData()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let planeAnnotation = annotation as? PlaneAnnotation {
            let identifier = planeAnnotation.identifier
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.image = UIImage(named: "user_location")
                view?.canShowCallout = false
            } else {
                view?.annotation = annotation
            }
            
            view?.transform = CGAffineTransform(rotationAngle: planeAnnotation.direction)
            
            return view
        }
        
        return nil
    }
}

// MARK: - UITableView delegate & DataSource

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        skyPathLayers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LayersTableViewCell", for: indexPath) as? LayersTableViewCell else {
            return .init()
        }
        
        let isSelected = selectedLayerIdx == indexPath.row
        let current = skyPathLayers[indexPath.row]
        cell.setup(withType: current, isSelected)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if selectedLayerIdx == indexPath.row { return }
        selectedLayerIdx = indexPath.row
    }
}

// MARK: - Alerts

extension MapViewController {
    
    func showSettingsAlert(sender sourceView:UIView?) {
        
        let alert = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        
        if let popoverController = alert.popoverPresentationController, let sourceView {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
            popoverController.permittedArrowDirections = .any
        }
        
        let domainAction = UIAlertAction(title: "Domain", style: .default) { [weak self] _ in
            self?.showDomainSelector(sourceView as? UIButton)
        }
        
        let themeAction = UIAlertAction(title: "Dark / Light", style: .default) { [weak self] _ in
            self?.switchThemeType()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(domainAction)
        alert.addAction(themeAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

// MARK: - Flight Simulation

extension MapViewController {
    
    func toggleFlightSimulation() {
        
        let wrapper = SkyPathWrapper.shared
        switch wrapper.currentServerEnv {
        case .dev(serverUrl: _):
            break
        default:
            let alert = UIAlertController(title: "Flight Simulation Unavailable", message: "Flight simulation is allowed only in dev environment.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        if wrapper.isSimulationRunning {
            wrapper.stopFlightSimulation()
            setupMap()
            removeSimulationUIComponents()
            turbulenceClusterer.reset()
        } else {
            wrapper.startFlightSimulation(with: wrapper.corridor, delegate: self)
        }
        
        updateFlightSimulationBtnIcon()
    }
    
    private func drawRouteOnMap(_ route: [CLLocationCoordinate2D]) {
        
        let polyline = RouteOverlay(coordinates: route, count: route.count)
        mapView.addOverlay(polyline)
    }
    
    private var planeAnnotation:PlaneAnnotation? {
        
        mapView.annotations.first(where: { $0 is PlaneAnnotation }) as? PlaneAnnotation
    }
    
    private func removeSimulationUIComponents() {
        
        mapView.removeOverlays(mapView.overlays.filter({ $0 is RouteOverlay }))
        if let planeAnnotation {
            mapView.removeAnnotation(planeAnnotation)
        }
    }
    
    private class PlaneAnnotation: NSObject, MKAnnotation {
        
        let identifier = "PlaneAnnotation"
        @objc dynamic var coordinate: CLLocationCoordinate2D
        var direction: CGFloat
        
        init(coordinate: CLLocationCoordinate2D, direction: CGFloat) {
            
            self.coordinate = coordinate
            self.direction = direction
        }
    }
    
    private class RouteOverlay: MKPolyline { }
}

// MARK: - SimulationLocationManagerDelegate

extension MapViewController: SimulationLocationManagerDelegate {
    
    func simulationManager(_ manager: SimulationLocationManager, willStartWith route: [CLLocationCoordinate2D], at location: CLLocationCoordinate2D) {
        
        drawRouteOnMap(route)
        
        var zoomRect = MKMapRect.null
        for point in route {
            let annotationPoint = MKMapPoint(point)
            let pointRect = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.1, height: 0.1)
            zoomRect = zoomRect.union(pointRect)
        }
        
        let padding:CGFloat = 60
        let edgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        mapView.setVisibleMapRect(zoomRect, edgePadding: edgeInsets, animated: true)
    }
    
    func simulationManager(_ manager: SimulationLocationManager, didUpdateLocation newLocation: CLLocationCoordinate2D, direction: CGFloat) {
        
        guard let planeAnnotation  else {
            let annotation = PlaneAnnotation(coordinate: newLocation, direction: direction)
            mapView.addAnnotation(annotation)
            return
        }
        
        planeAnnotation.coordinate = newLocation
        planeAnnotation.direction = direction
        if let view = mapView.view(for: planeAnnotation) {
            view.transform = CGAffineTransform(rotationAngle: direction)
        }
    }
}
