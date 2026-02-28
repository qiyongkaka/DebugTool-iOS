//
//  MainThreadStallMonitor.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/28.
//

import Foundation

final class MainThreadStallMonitor {
    struct StallEvent {
        let duration: TimeInterval
        let timestamp: Date
        let callStackSymbols: [String]
    }

    static let shared = MainThreadStallMonitor()

    var onStall: ((StallEvent) -> Void)?

    private let queue = DispatchQueue(label: "debugtool.mainthreadstall.monitor")
    private var timer: DispatchSourceTimer?
    private var lastPingUptime: TimeInterval = 0
    private var isInStall = false
    private var stallStartUptime: TimeInterval = 0

    private(set) var latestEvent: StallEvent?

    var isRunning: Bool { timer != nil }

    var threshold: TimeInterval = 0.4
    var pingInterval: TimeInterval = 0.1

    private init() {}

    func start() {
        guard timer == nil else { return }
        lastPingUptime = ProcessInfo.processInfo.systemUptime
        isInStall = false
        stallStartUptime = 0

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: pingInterval, leeway: .milliseconds(20))
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        self.timer = timer
        timer.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isInStall = false
        stallStartUptime = 0
    }

    private func tick() {
        DispatchQueue.main.async { [weak self] in
            self?.lastPingUptime = ProcessInfo.processInfo.systemUptime
        }

        let now = ProcessInfo.processInfo.systemUptime
        let lag = now - lastPingUptime

        if !isInStall, lag >= threshold {
            isInStall = true
            stallStartUptime = now - lag
            return
        }

        if isInStall, lag < threshold {
            isInStall = false
            let stallDuration = now - stallStartUptime
            let callStack = PerformanceDiagnostics.mainThreadCallStackSymbols()
            let event = StallEvent(duration: stallDuration, timestamp: Date(), callStackSymbols: callStack)
            latestEvent = event
            
            print("[MainThreadStallMonitor] stall=\(String(format: "%.0fms", event.duration * 1000))")
            for line in event.callStackSymbols {
                print(line)
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.onStall?(event)
            }
        }
    }
}
