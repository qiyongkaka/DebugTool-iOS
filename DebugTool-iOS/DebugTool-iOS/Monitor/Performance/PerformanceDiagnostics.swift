//
//  PerformanceDiagnostics.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import UIKit

final class PerformanceDiagnostics {

    static func topViewController(from rootViewController: UIViewController?) -> UIViewController? {
        guard let rootViewController else { return nil }

        if let presented = rootViewController.presentedViewController {
            return topViewController(from: presented)
        }

        if let navigationController = rootViewController as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }

        if let tabBarController = rootViewController as? UITabBarController {
            return topViewController(from: tabBarController.selectedViewController)
        }

        return rootViewController
    }

    static func currentViewControllerDescription() -> String {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        let vc = topViewController(from: window?.rootViewController)
        if let vc {
            return "\(type(of: vc))"
        }
        return "UnknownViewController"
    }

    static func mainThreadCallStackSymbols() -> [String] {
        if Thread.isMainThread {
            return Thread.callStackSymbols
        }

        var symbols: [String] = []
        DispatchQueue.main.sync {
            symbols = Thread.callStackSymbols
        }
        return symbols
    }
}
