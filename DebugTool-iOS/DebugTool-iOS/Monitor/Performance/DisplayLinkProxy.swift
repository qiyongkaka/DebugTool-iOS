//
//  DisplayLinkProxy.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import UIKit

final class DisplayLinkProxy: NSObject {
    weak var target: PerformanceHUD?

    init(target: PerformanceHUD) {
        self.target = target
        super.init()
    }

    @objc func tick(_ link: CADisplayLink) {
        target?.handleDisplayLink(link)
    }
}
