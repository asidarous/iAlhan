//
//  SceneDelegate.swift
//  iAlhan
//
//  Created by ARSANI SIDAROUS on 9/23/26.
//  Copyright © 2026 alhan.org. All rights reserved.
//


import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard scene is UIWindowScene,
              let browseNavigationController = window?.rootViewController
                as? PlayerNavigationController else {
            return
        }

        window?.rootViewController = MainTabBarController(
            browseNavigationController: browseNavigationController
        )
    }
}