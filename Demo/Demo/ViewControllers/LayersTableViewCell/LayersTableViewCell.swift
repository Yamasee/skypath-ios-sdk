//
//  LayersTableViewCell.swift
//  Demo
//
//  Created by Asi Givati on 18/04/2025.
//

import UIKit
import SkyPathSDK

class LayersTableViewCell: UITableViewCell {
    
    @IBOutlet weak private var layerName: UILabel!
    @IBOutlet weak private var checkbox: UIImageView!
    @IBOutlet weak private var icon: UIImageView!
    
    func setup(withType type: DataType, _ isSelected: Bool) {
        layerName.text = title(for: type)
        checkbox.image = UIImage(named: "checkbox_\(isSelected ? "selected" : "empty")")
        icon.image = icon(for: type)
    }
    
    private func title(for type: DataType) -> String {
        switch type {
        case .oneLayer: return "SkyPath OneLayer"
        case .observations: return "SkyPath Observations"
        default: return ""
        }
    }
    
    private func icon(for type: DataType) -> UIImage? {
        switch type {
        case .oneLayer: return UIImage(named: "onelayer")
        case .observations: return UIImage(named: "spobservations")
        default: return nil
        }
    }
}
