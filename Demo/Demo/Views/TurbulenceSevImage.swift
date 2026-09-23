//
//  TurbulenceView.swift
//  Demo
//
//  Created by Asi Givati on 28/04/2025.
//

import SwiftUI
import SkyPathSDK

struct TurbulenceSeverityImage: View {
    
    var imageName: String = "sev_turb"
    var sev: SkyPathSDK.TurbulenceSeverity
    private var color: Color {
        if #available(iOS 15.0, *) {
            Color(uiColor: TurbulenceSeverity(rawValue: sev.rawValue)?.demoColor ?? .black)
        } else {
            Color(TurbulenceSeverity(rawValue: sev.rawValue)?.demoColor ?? .black)
        }
    }
    
    var body: some View {
        HexagonShape()
            .fill(color)
    }
}

// MARK: - Severity colors

// Colors were removed from the SDK in v4.0. Reference palette: https://docs.skypath.io/ios/next/basic/data#turbulence-severity
extension TurbulenceSeverity {

    var demoColor: UIColor {
        switch self {
        case .smooth: return UIColor(hex: 0xFFFFFF)
        case .light: return UIColor(hex: 0xFFF04C)
        case .lightModerate: return UIColor(hex: 0xFFBC09)
        case .moderate: return UIColor(hex: 0xFF7100)
        case .moderateSevere: return UIColor(hex: 0xFF0000)
        @unknown default: return .clear
        }
    }

    var demoColorWithOpacity: UIColor {
        demoColor.withAlphaComponent(self == .smooth ? 0.6 : 0.8)
    }
}

private extension UIColor {

    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height * 0.25))
        path.addLine(to: CGPoint(x: width, y: height * 0.75))
        path.addLine(to: CGPoint(x: width / 2, y: height))
        path.addLine(to: CGPoint(x: 0, y: height * 0.75))
        path.addLine(to: CGPoint(x: 0, y: height * 0.25))
        path.closeSubpath()
        return path
    }
}
