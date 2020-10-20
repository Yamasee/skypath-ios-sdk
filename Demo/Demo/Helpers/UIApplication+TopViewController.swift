//
//  UIApplication+TopViewController.swift
//  Demo
//
//  Created by Alex Kovalov on 20.10.2020.
//  Copyright © 2020 Yamasee. All rights reserved.
//

import UIKit

extension UIApplication {
    
    public static func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let navigationController = base as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }
        
        if let tabbarController = base as? UITabBarController {
            
            if let selected = tabbarController.selectedViewController {
                return topViewController(base: selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
}
