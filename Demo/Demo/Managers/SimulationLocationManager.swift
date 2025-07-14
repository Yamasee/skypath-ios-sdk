//
//  SimulationLocationManager.swift
//  Demo
//
//  Created by Asi Givati on 23/04/2025.
//

import SkyPathSDK
import CoreLocation

protocol SimulationLocationManagerDelegate: AnyObject {
    
    func simulationManager(
        _ manager:SimulationLocationManager,
        willStartWith route:[CLLocationCoordinate2D],
        at location: CLLocationCoordinate2D)
    
    func simulationManager(
        _ manager:SimulationLocationManager,
        didUpdateLocation newLocation: CLLocationCoordinate2D,
        direction: CGFloat)
}

class SimulationLocationManager {
    
    // MARK: - Private Variables
    
    private weak var delegate: SimulationLocationManagerDelegate?
    private var coordinateIndex = 0
    private var timer: Timer?

    // MARK: - Public Variables
    
    private(set) var route: [CLLocationCoordinate2D] = []
    var isRunning: Bool { timer != nil }
    var currentLocation: CLLocationCoordinate2D? { route[coordinateIndex] }
    
    // MARK: - Actions
    
    func start(with coordinates: [CLLocationCoordinate2D],
               altitude: Double,
               delegate: SimulationLocationManagerDelegate) {
        
        if coordinates.isEmpty || isRunning { return }
        self.delegate = delegate
        route = coordinates.geodesic
        let origin = coordinates[0]
        coordinateIndex = 0
        delegate.simulationManager(self, willStartWith: route, at: origin)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.coordinateIndex < self.route.count else {
                self.stop()
                return
            }

            let currentCoord = self.route[self.coordinateIndex]
            var direction: CGFloat = 0
            let nextCoordIdx = self.coordinateIndex + 1 < self.route.count ? self.coordinateIndex + 1 : nil
            if let nextCoordIdx {
                let nextCoord = self.route[nextCoordIdx]
                direction = currentCoord.direction(to: nextCoord)
            }
            
            let location = CLLocation(coordinate:
                                        CLLocationCoordinate2D(latitude: currentCoord.latitude,
                                                               longitude: currentCoord.longitude),
                                      altitude: 30000,
                                      horizontalAccuracy: 1000,
                                      verticalAccuracy: 304.8,
                                      course: direction,
                                      speed: 1500,
                                      timestamp: Date())
            
            SkyPath.shared.simulatedLocation(location)
            
            self.delegate?.simulationManager(self, didUpdateLocation: currentCoord, direction: direction)
            self.coordinateIndex += 1
        }
    }
    
    func stop() {
        
        timer?.invalidate()
        timer = nil
        route = []
        coordinateIndex = 0
        delegate = nil
    }
}
