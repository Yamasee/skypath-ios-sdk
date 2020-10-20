//
//  AlertManager.swift
//  Demo
//
//  Created by Alex Kovalov on 20.10.2020.
//  Copyright © 2020 Yamasee. All rights reserved.
//

import UIKit

final class AlertManager: NSObject {
    
    static var topViewController: UIViewController? {
        return UIApplication.topViewController()
    }
    
    static func showErrorMessage(with text: String?) {
        
        let alert = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        topViewController?.present(alert, animated: true, completion: nil)
    }
    
    static func showMessage(with text: String?, okHandler: (() -> Void)? = nil) {
        
        let alert = UIAlertController(title: "", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            okHandler?()
        })
        topViewController?.present(alert, animated: true, completion: nil)
    }
    
    static func showConfirmationAlert(with title: String? = nil,
                                      message: String? = nil,
                                      okActionTitle: String = "OK",
                                      okActionStyle: UIAlertAction.Style = .default,
                                      cancelActionTitle: String = "Cancel",
                                      okHandler: (() -> Void)? = nil) {
        
        let alert = UIAlertController(title: title ?? "", message: message ?? "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okActionTitle, style: okActionStyle) { _ in
            okHandler?()
        })
        alert.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil))
        topViewController?.present(alert, animated: true, completion: nil)
    }
    
    static func showAlert(withTitle title: String? = nil, message: String? = nil, actions: [UIAlertAction]? = nil, style: UIAlertController.Style = .alert) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        if actions != nil {
            for action in actions! {
                alert.addAction(action)
            }
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }
        topViewController?.present(alert, animated: true, completion: nil)
    }
    
    struct AlertTextField {
        let defaultValue: String?
        let keyboardType: UIKeyboardType
    }
    static func showAlertToEnter(withTitle title: String? = nil,
                                 message: String? = nil,
                                 textFields: [AlertTextField],
                                 entered: @escaping (_ values: [String]) -> Void) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for alertTextField in textFields {
            alert.addTextField { tf in
                tf.text = alertTextField.defaultValue
                tf.keyboardType = alertTextField.keyboardType
            }
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let values = alert.textFields?.map { $0.text ?? "" } ?? []
            entered(values)
        })
        topViewController?.present(alert, animated: true, completion: nil)
    }
    
    static func showSettingsAlert(withTitle title: String? = nil,
                                  message: String? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            
            let settingsUrl = URL(string: UIApplication.openSettingsURLString)
            if let url = settingsUrl {
                UIApplication.shared.open(url, options: [:]) { _ in }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        topViewController?.present(alert, animated: true, completion: nil)
    }
}
