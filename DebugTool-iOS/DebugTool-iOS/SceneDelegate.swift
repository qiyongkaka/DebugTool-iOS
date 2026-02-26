//
//  SceneDelegate.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        DispatchQueue.main.async { [weak self] in
            if let window = self?.window {
                DebugFloatingButtonManager.shared.start(in: window)
                LaunchLoadingAnimator.shared.show(in: window)
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        DebugFloatingButtonManager.shared.stop()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if let window = window {
            DebugFloatingButtonManager.shared.start(in: window)
        }
        LaunchTimingLogger.shared.logFinish(marker: "sceneDidBecomeActive")
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }


}
