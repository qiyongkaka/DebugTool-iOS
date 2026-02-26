//
//  ViewControllerLifecycleHook.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import UIKit
import ObjectiveC.runtime

final class ViewControllerLifecycleHook {
    static func start() {
        UIViewController.swizzleViewDidLoad()
    }
}

extension UIViewController {
    private static let swizzleViewDidLoadOnce: Void = {
        guard
            let originalMethod = class_getInstanceMethod(UIViewController.self, #selector(viewDidLoad)),
            let swizzledMethod = class_getInstanceMethod(UIViewController.self, #selector(hooked_viewDidLoad))
        else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()

    static func swizzleViewDidLoad() {
        _ = swizzleViewDidLoadOnce
    }

    @objc func hooked_viewDidLoad() {
        hooked_viewDidLoad()
        print("[ViewControllerLifecycleHook] ViewDidLoad: \(type(of: self))")
    }
}
