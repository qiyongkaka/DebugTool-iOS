//
//  PerformanceHUD.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import UIKit

final class PerformanceHUD {

    static let shared = PerformanceHUD()

    private let hudView = PerformanceHUDView()
    private var displayLink: CADisplayLink?
    private var displayLinkProxy: DisplayLinkProxy?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount = 0
    private var isObserving = false
    private let lowFPSThreshold: Double = 70
    private var lastLowFPSLogTime: CFTimeInterval = 0
    var isRunning: Bool { displayLink != nil }

    private init() {}

    func start(in window: UIWindow) {
        if hudView.superview !== window {
            hudView.frame = initialFrame(in: window)
            window.addSubview(hudView)
        } else {
            window.bringSubviewToFront(hudView)
        }

        if displayLink == nil {
            let proxy = DisplayLinkProxy(target: self)
            let displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick(_:)))
            displayLink.add(to: .main, forMode: .common)
            self.displayLinkProxy = proxy
            self.displayLink = displayLink
        }

        if !isObserving {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
            isObserving = true
        }
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
        lastTimestamp = 0
        frameCount = 0
        if isObserving {
            NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
            isObserving = false
        }
        hudView.removeFromSuperview()
    }

    func handleDisplayLink(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1
        let delta = link.timestamp - lastTimestamp

        if delta >= 1 {
            let fps = Double(frameCount) / delta
            let cpu = PerformanceMetrics.cpuUsagePercentage()
            let memory = PerformanceMetrics.memoryUsageMB()
            let totalMemory = PerformanceMetrics.deviceMemoryMB()
            let memoryPercent = totalMemory > 0 ? (memory / totalMemory * 100.0) : 0
            hudView.update(fps: fps, cpu: cpu, memoryMB: memory, memoryPercent: memoryPercent)
            if fps < lowFPSThreshold {
                logLowFPSIfNeeded(fps: fps)
            }
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }

    private func logLowFPSIfNeeded(fps: Double) {
        let now = CACurrentMediaTime()
        if now - lastLowFPSLogTime < 5 {
            return
        }
        lastLowFPSLogTime = now

        let vc = PerformanceDiagnostics.currentViewControllerDescription()
        let stack = PerformanceDiagnostics.mainThreadCallStackSymbols().joined(separator: "\n")
        print("[PerformanceHUD] ⚠️ Low FPS: \(String(format: "%.1f", fps)) | VC: \(vc)\nMain Thread Call Stack:\n\(stack)")
    }

    @objc private func handleOrientationChange() {
        guard let window = hudView.superview as? UIWindow else { return }
        if hudView.isUserDragging {
            return
        }
        hudView.frame = initialFrame(in: window)
    }

    private func initialFrame(in window: UIWindow) -> CGRect {
        let size = CGSize(width: 140, height: 60)
        let x = window.bounds.width - size.width - 16
        let y = window.safeAreaInsets.top + 12
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
