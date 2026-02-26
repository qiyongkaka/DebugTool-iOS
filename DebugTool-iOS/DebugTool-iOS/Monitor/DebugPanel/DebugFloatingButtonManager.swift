//
//  DebugFloatingButtonManager.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/28.
//

import UIKit

final class DebugFloatingButtonManager {
    static let shared = DebugFloatingButtonManager()

    private weak var window: UIWindow?
    private let button = DebugFloatingButton(frame: CGRect(origin: .zero, size: CGSize(width: 44, height: 44)))
    private var isObserving = false

    private init() {
        button.onTap = { [weak self] in
            self?.presentPanel()
        }
    }

    func start(in window: UIWindow) {
        if self.window === window, button.superview === window { return }
        stop()
        self.window = window
        button.frame = initialFrame(in: window)
        window.addSubview(button)
        window.bringSubviewToFront(button)
        startObserving()
    }

    func stop() {
        button.removeFromSuperview()
        window = nil
        stopObserving()
    }

    private func presentPanel() {
        DebugPanelPresenter.shared.present(from: window?.windowScene)
    }

    @objc private func handleOrientationChange() {
        guard let window else { return }
        if button.isUserDragging { return }
        button.frame = initialFrame(in: window)
    }

    private func startObserving() {
        guard !isObserving else { return }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        isObserving = true
    }

    private func stopObserving() {
        guard isObserving else { return }
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        isObserving = false
    }

    private func initialFrame(in window: UIWindow) -> CGRect {
        let size = CGSize(width: 44, height: 44)
        let x = window.bounds.width - size.width - 16
        let y = window.safeAreaInsets.top + 80
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
