//
//  NotificationView.swift
//  Demo
//
//  Created by Asi Givati on 27/04/2025.
//

import SwiftUI
import SkyPathSDK

struct NotificationView: View {

    var settings: NotificationViewController.NotificationSettings
    var notificationData:Any
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            if settings.alignment == .right {
                Spacer(minLength: 0)
            }
            
            HStack(spacing: 0) {
                
                NotificationContent(notificationData: notificationData)
                
                Spacer()

                Divider()
                
                Button("Close") {
                    settings.onDismiss?()
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, 12) // inner padding
            .frame(width: settings.size.width, height: settings.size.height)
            .background(Color(.white))
            .cornerRadius(settings.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: settings.cornerRadius)
                    .stroke(.gray.opacity(0.5), lineWidth: 1)
            )

            if settings.alignment == .left {
                Spacer(minLength: 0)
            }
        }
    }
    
    private struct NotificationContent: View {
        var notificationData:Any
        var body: some View {
            if let item = notificationData as? (any SkyPathSDK.TurbulenceItemable) {
                TurbulenceItemableView(item: item)
            }
        }
    }
    
    struct TurbulenceItemableView: View {
        var item: (any SkyPathSDK.TurbulenceItemable)
        var body: some View {
            HStack(spacing: 15) {
                VStack {
                    TurbulenceSeverityImage(sev: item.sev)
                        .frame(width: 40, height: 40)
                    
                    FlightLevelView(flightLevel: Int(item.altFt) / 1000)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Spacer()
                    Text("\(item.sev)".capitalized + " Turbulence") +
                    Text(" | EDR: \(String(format: "%.2f", item.edr))")
                        .foregroundColor(.gray)
                        
                    Text(timeAgoString(from: TimeInterval(item.ts)))
                        .foregroundColor(.gray)
                        .font(.title3)
                    
                    Spacer()
                }
            }
            .font(.title2)
        }
        
        struct FlightLevelView: View {
            var flightLevel: Int
            
            var body: some View {
                HStack(spacing: 4) {
                    Text("FL")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.gray)
                        .cornerRadius(4)
                    
                    Text("\(flightLevel)")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(6)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                )
            }
        }
        
        private func timeAgoString(from timestamp: TimeInterval) -> String {
            let date = Date(timeIntervalSince1970: timestamp)
            let now = Date()
            let interval = Int(now.timeIntervalSince(date))
            
            let minutes = (interval / 60) % 60
            let hours = interval / 3600
            
            let formatter = DateFormatter()
            formatter.timeZone = .current
            formatter.dateFormat = "HH:mm 'Z'"
            let utcTime = formatter.string(from: date)
            
            if hours > 0 {
                return "\(hours)h \(minutes)m ago (\(utcTime))"
            } else if minutes > 0 {
                return "\(minutes)m ago (\(utcTime))"
            } else {
                return "Just now (\(utcTime))"
            }
        }
    }
}

class NotificationViewController: UIHostingController<NotificationView> {
    
    // Mark: - Settings
    
    class NotificationSettings {
        
        /// Notification view size (width and height).
        var size = CGSize(width: 550, height: 120)
        /// Top padding from the safe area.
        var topPadding:CGFloat = 10
        /// Horizontal padding from screen edges.
        var horizontalPadding:CGFloat = 20
        /// Corner radius for the notification view.
        var cornerRadius:CGFloat = 8
        /// The duration (in seconds) for which the notification will stay visible before disappearing.
        var displayDuration: TimeInterval = 8
        /// Notification alignment: left, center, or right.
        var alignment:NotificationAlignment = .right
        
        /// Called when notification needs to be dismissed.
        fileprivate var onDismiss: (() -> Void)?
        
        enum NotificationAlignment {
            case right, center, left
        }
    }
    
    // Mark: - Properties
    
    private weak var dismissWorkItem: DispatchWorkItem?
    
    let settings = NotificationSettings()
    
    weak static private(set) var current:UIHostingController<NotificationView>?
    
    // Mark: - Life Cycle
    
    private init(notificationData:Any) {
        
        let notificationView = NotificationView(settings: settings, notificationData: notificationData)
        super.init(rootView: notificationView)
        
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
    
    // Mark: - Presentation
    
    static func show(on parentVC: UIViewController, with notificationData: Any) {
        
        let showAnimated = NotificationViewController.current == nil
        NotificationViewController.dismiss(animated: false)
        let notificationView = NotificationViewController(notificationData: notificationData)
        notificationView.present(on: parentVC, animated: showAnimated)
    }
    
    private func present(on parentVC: UIViewController, animated:Bool = true) {
        
        let parentView = parentVC.view!
        parentView.addSubview(view)
        parentVC.addChild(self)
        
        func setupConstraints() {
            let horizontalConstraint: NSLayoutConstraint
            switch settings.alignment {
            case .center:
                horizontalConstraint = view.centerXAnchor.constraint(equalTo: parentView.centerXAnchor)
            case .left:
                horizontalConstraint = view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: settings.horizontalPadding)
            case .right:
                horizontalConstraint = view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -settings.horizontalPadding)
            }
            
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: settings.topPadding),
                horizontalConstraint,
                view.widthAnchor.constraint(equalToConstant: settings.size.width),
                view.heightAnchor.constraint(equalToConstant: settings.size.height)
            ])
            parentView.layoutIfNeeded()
        }
        
        func startAnimation() {
            view.transform = CGAffineTransform(translationX: 0, y: -view.bounds.height)
            
            UIView.animate(withDuration: animated ? 0.35 : 0, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.7, options: [.curveEaseOut]) { [weak self] in
                guard let self else { return }
                self.view.transform = .identity
            }
        }
        
        setupConstraints()

        Self.current = self
        
        startAnimation()
        
        scheduleAutoDismiss()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        dismissWorkItem?.cancel()
    }
    
    static func dismiss(animated:Bool = true) {
        
        guard let notificationView = Self.current else { return }
        
        func close() {
            notificationView.removeFromParent()
            notificationView.view.removeFromSuperview()
            notificationView.dismiss(animated: animated)
        }
        
        if !animated {
            close()
            return
        }
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) { [weak notificationView] in
            
            guard let notificationView else { return }
            notificationView.view.transform = CGAffineTransform(translationX: 0, y: -notificationView.view.bounds.height)
            
        } completion: {  _ in
            
            close()
        }
    }
    
    // Mark: - Actions
    
    private func scheduleAutoDismiss() {
        
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        
        let dismissWorkItem = DispatchWorkItem {
            Self.dismiss()
        }
        
        settings.onDismiss = {
            dismissWorkItem.cancel()
            Self.dismiss()
        }
        
        self.dismissWorkItem = dismissWorkItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.displayDuration, execute: dismissWorkItem)
    }
}

extension UIViewController {
    
    func showNotification(_ notificationData:Any) {
        
        NotificationViewController.show(on: self, with: notificationData)
    }
    
    func dismissNotification() {
        
        NotificationViewController.dismiss()
    }
}

#Preview {
    NotificationView(settings: .init(), notificationData: "Some item" )
}
