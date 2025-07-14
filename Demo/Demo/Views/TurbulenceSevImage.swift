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
            Color(uiColor: TurbulenceSeverity(rawValue: sev.rawValue)?.color ?? .black)
        } else {
            Color(TurbulenceSeverity(rawValue: sev.rawValue)?.color ?? .black)
        }
    }
    
    var body: some View {
        HexagonShape()
            .fill(color)
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
