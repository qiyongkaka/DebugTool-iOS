//
//  BatteryMonitor.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/28.
//

import UIKit

final class BatteryMonitor {
    static let shared = BatteryMonitor()

    var onUpdate: ((String) -> Void)?

    private var isMonitoring = false
    private var timer: Timer?
    private var lastLevel: Float?
    private var lastTimestamp: TimeInterval?
    private var smoothedRate: Double?

    private init() {}

    func start() {
        guard !isMonitoring else { return }
        isMonitoring = true
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdate), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdate), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        let level = UIDevice.current.batteryLevel
        lastLevel = level >= 0 ? level : nil
        lastTimestamp = ProcessInfo.processInfo.systemUptime
        let timer = Timer(timeInterval: 5, target: self, selector: #selector(handleUpdate), userInfo: nil, repeats: true)
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        handleUpdate()
    }

    func stop() {
        guard isMonitoring else { return }
        isMonitoring = false
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.batteryStateDidChangeNotification, object: nil)
        UIDevice.current.isBatteryMonitoringEnabled = false
        timer?.invalidate()
        timer = nil
        lastLevel = nil
        lastTimestamp = nil
        smoothedRate = nil
    }

    @objc private func handleUpdate() {
        updateRate()
        let text = statusText()
        DispatchQueue.main.async { [weak self] in
            self?.onUpdate?(text)
        }
    }

    func statusText() -> String {
        let level = UIDevice.current.batteryLevel
        if level < 0 {
            return "Unavailable"
        }
        guard let smoothedRate else {
            return "Calculating..."
        }
        let rateValue = abs(smoothedRate)
        let rateText = String(format: "%.2f%%/h", rateValue)
        switch UIDevice.current.batteryState {
        case .charging, .full:
            return "Charge \(rateText)"
        case .unplugged:
            if smoothedRate >= 0 {
                return "Drain \(rateText)"
            }
            return "Charge \(rateText)"
        case .unknown:
            return "Drain \(rateText)"
        @unknown default:
            return "Drain \(rateText)"
        }
    }

    private func updateRate() {
        let level = UIDevice.current.batteryLevel
        if level < 0 {
            smoothedRate = nil
            lastLevel = nil
            lastTimestamp = nil
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        if let lastLevel, let lastTimestamp {
            let deltaTime = now - lastTimestamp
            if deltaTime > 1 {
                let delta = Double(lastLevel - level)
                let hours = deltaTime / 3600
                let rate = (delta / hours) * 100
                if let smoothedRate {
                    self.smoothedRate = smoothedRate * 0.7 + rate * 0.3
                } else {
                    self.smoothedRate = rate
                }
            }
        }
        self.lastLevel = level
        self.lastTimestamp = now
    }
}
