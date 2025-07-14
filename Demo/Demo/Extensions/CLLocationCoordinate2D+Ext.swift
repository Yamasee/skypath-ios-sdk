//
//  LocationEx.swift
//  Demo
//
//  Created by Asi Givati on 23/04/2025.
//

import CoreLocation

extension CLLocationCoordinate2D {
    
    func direction(to otherLocation: CLLocationCoordinate2D) -> CGFloat {
        
        let deltaLat = otherLocation.latitude - latitude
        let deltaLon = otherLocation.longitude - longitude
        return CGFloat(atan2(deltaLon, deltaLat))
    }
    
    func distance(to otherLocation: CLLocationCoordinate2D) -> CLLocationDistance {
        
        CLLocation(latitude: latitude, longitude: longitude).distance(from: CLLocation(latitude: otherLocation.latitude, longitude: otherLocation.longitude))
    }
}

// MARK: - Convenience vars

extension CLLocationCoordinate2D {
    
    static var kjfkAirport = CLLocationCoordinate2D(latitude: 40.641766, longitude: -73.780968)
    static var kiadAirport = CLLocationCoordinate2D(latitude: 38.9519444444, longitude: -77.4480555556)
}
