//
//  LocationManager.swift
//  Demo
//
//  Created by Alex Kovalov on 20.10.2020.
//  Copyright © 2020 Yamasee. All rights reserved.
//

import UIKit
import CoreLocation

extension Notification.Name {
    
    static let didUpdateLocation = Notification.Name("didUpdateLocation")
    static let failedToUpdateLocation = Notification.Name("failedToUpdateLocation")
    static let didUpdateHeading = Notification.Name("didUpdateHeading")
    static let didChangeAutorizationStatus = Notification.Name("didChangeAutorizationStatus")
}

final class LocationManager: NSObject {
    
    static let shared = LocationManager()
    
    // MARK: - Properties
    
    var location: CLLocation?
    
    private var locationManager: CLLocationManager
    private var updatingLocation = false
    private var locationAccessEnabled = false
    
    // MARK: - Actions
    
    override init() {
        
        locationManager = CLLocationManager()
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        
        super.init()
        
        locationManager.delegate = self
    }
    
    func startUpdatingLocation() {
        
        guard !updatingLocation else {
            return
        }
        
        updatingLocation = true
        
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Private
    
    private func notifyUpdate(location: CLLocation?, error: Error?) {
        
        updatingLocation = false
        
        guard error == nil else {
            
            NotificationCenter.default.post(name: .failedToUpdateLocation, object: error)
            return
        }
        
        guard location != nil else {
            
            NotificationCenter.default.post(name: .failedToUpdateLocation, object: nil)
            return
        }
        
        NotificationCenter.default.post(name: .didUpdateLocation, object: nil)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            return
        }
        
        notifyUpdate(location: location, error: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        notifyUpdate(location: nil, error: error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        locationAccessEnabled = false
        NotificationCenter.default.post(name: .didChangeAutorizationStatus, object: status)
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            locationAccessEnabled = true
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied:
            break
        case .restricted:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        NotificationCenter.default.post(name: .didUpdateHeading, object: nil)
    }
}
