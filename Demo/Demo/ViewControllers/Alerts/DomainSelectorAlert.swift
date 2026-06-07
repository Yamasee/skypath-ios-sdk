//
//  DomainSelectorAlert.swift
//  Demo
//
//  Created by Asi Givati on 20/04/2025.
//

import UIKit
import SkyPathSDK

class DomainSelectorAlert: UIAlertController {

    // MARK: - Properties
    
    weak private var parentVC: UIViewController?
    
    // MARK: - Lifecycle
    
    init(sourceView: UIView?, parentVC: UIViewController) {
        
        super.init(nibName: nil, bundle: nil)
        self.parentVC = parentVC
        let wrapper = SkyPathWrapper.shared
        let message = "Domain" + "\n" + "Server: \(wrapper.currentServerEnvStr)"
        self.message = message

        if let popoverController = popoverPresentationController, let sourceView {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
            popoverController.permittedArrowDirections = .any
        }

        let devEnv = SkyPathSDK.Environment.dev(serverUrl: nil)
        addAction(UIAlertAction(title: devEnv.baseUrl, style: .default) { _ in
            wrapper.currentServerEnv = devEnv
        })
        
        let stagEnv = SkyPathSDK.Environment.staging(serverUrl: nil)
        addAction(UIAlertAction(title: stagEnv.baseUrl, style: .default) { _ in
            wrapper.currentServerEnv = stagEnv
        })

        addAction(UIAlertAction(title: "Custom", style: .default) { [weak parentVC] _ in
            let inputAlert = UIAlertController(title: "Custom", message: "Enter full domain url", preferredStyle: .alert)
            inputAlert.addTextField { textField in
                textField.keyboardType = .URL
            }

            inputAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                if let urlText = inputAlert.textFields?.first?.text, !urlText.isEmpty {
                    wrapper.currentServerEnv = .dev(serverUrl: urlText)
                }
            })

            inputAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            parentVC?.present(inputAlert, animated: true)
        })

        addAction(UIAlertAction(title: "Cancel", style: .cancel))
    }

    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Actions
    
    func present() {
        
        guard let parentVC else { return }
        parentVC.present(self, animated: true)
    }
}
