//
//  EnvironmentEx.swift
//  Demo
//
//  Created by Asi Givati on 22/04/2025.
//

import SkyPathSDK

extension SkyPathSDK.Environment {
    
    var baseUrl: String {
        
        switch self {
        case .staging(serverUrl: _):
            return "staging-api.skypath.io"
        default:
            return ""
        }
    }
}
