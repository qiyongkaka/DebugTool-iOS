//
//  DebugPanelPresenter.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/27.
//

import UIKit

final class DebugPanelPresenter {
    static let shared = DebugPanelPresenter()

    private var isPresenting = false

    private init() {}

    func present(from windowScene: UIWindowScene?) {
        guard !isPresenting else { return }
        guard let topViewController = topViewController(from: windowScene) else { return }

        isPresenting = true
        let panel = DebugPanelViewController()
        let navigation = UINavigationController(rootViewController: panel)
        navigation.modalPresentationStyle = .pageSheet
        topViewController.present(navigation, animated: true) { [weak self] in
            self?.isPresenting = false
        }
    }

    private func topViewController(from windowScene: UIWindowScene?) -> UIViewController? {
        let window = windowScene?.windows.first { $0.isKeyWindow } ?? windowScene?.windows.first
        guard let root = window?.rootViewController else { return nil }
        return topViewController(from: root)
    }

    private func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = root as? UINavigationController, let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }
}
