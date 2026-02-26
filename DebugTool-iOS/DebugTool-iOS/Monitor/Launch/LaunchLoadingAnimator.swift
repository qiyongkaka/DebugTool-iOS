//
//  LaunchLoadingAnimator.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import UIKit

final class LaunchLoadingAnimator {
    static let shared = LaunchLoadingAnimator()

    private let overlayView = UIView()
    private let logoImageView = UIImageView()
    private let indicator = UIActivityIndicatorView(style: .large)
    private var autoHideWorkItem: DispatchWorkItem?
    private var isShowing = false

    private init() {
        overlayView.backgroundColor = .systemBackground
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = Self.appIconImage()
        overlayView.addSubview(logoImageView)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(indicator)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor, constant: -40),
            logoImageView.widthAnchor.constraint(equalToConstant: 88),
            logoImageView.heightAnchor.constraint(equalToConstant: 88),
            indicator.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            indicator.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 20)
        ])
    }

    func show(in window: UIWindow, autoHideAfter: TimeInterval = 1.0) {
        if overlayView.superview !== window {
            overlayView.removeFromSuperview()
            overlayView.frame = window.bounds
            window.addSubview(overlayView)
        }
        logoImageView.isHidden = (logoImageView.image == nil)
        overlayView.alpha = 1
        indicator.startAnimating()
        isShowing = true

        autoHideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        autoHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoHideAfter, execute: workItem)
    }

    func hide(animated: Bool = true) {
        guard isShowing else { return }
        isShowing = false
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil

        let finish: () -> Void = { [weak self] in
            guard let self else { return }
            self.indicator.stopAnimating()
            self.overlayView.removeFromSuperview()
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.overlayView.alpha = 0
            }, completion: { _ in
                finish()
            })
        } else {
            overlayView.alpha = 0
            finish()
        }
    }

    private static func appIconImage() -> UIImage? {
        let dict = Bundle.main.infoDictionary
        let icons = dict?["CFBundleIcons"] as? [String: Any]
        let primary = icons?["CFBundlePrimaryIcon"] as? [String: Any]
        let files = primary?["CFBundleIconFiles"] as? [String]
        if let name = files?.last {
            return UIImage(named: name)
        }
        let iconName = primary?["CFBundleIconName"] as? String
        if let iconName {
            return UIImage(named: iconName)
        }
        return nil
    }
}
