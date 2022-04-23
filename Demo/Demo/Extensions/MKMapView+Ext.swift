//
//  MKMapView+Ext.swift
//  Demo
//
//  Created by Alex Kovalov on 23.04.2022.
//

import Foundation
import MapKit

extension MKMapView {
    
    var currentZoomLevel: Int {
        let maxZoom: Double = 24
        let zoomScale = visibleMapRect.size.width / Double(frame.size.width)
        let zoomExponent = log2(zoomScale)
        return Int(maxZoom - ceil(zoomExponent))
    }
}
