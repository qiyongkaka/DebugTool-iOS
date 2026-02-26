//
//  LaunchTimingLogger.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import Foundation

final class LaunchTimingLogger {
    static let shared = LaunchTimingLogger()

    private let processStartUptime = ProcessInfo.processInfo.systemUptime
    private var didLogStart = false
    private var didLogFinish = false

    func logStart() {
        guard !didLogStart else { return }
        didLogStart = true
        print("[LaunchTimingLogger] LaunchStart uptime=\(String(format: "%.3f", processStartUptime))s")
    }

    func logFinish(marker: String) {
        guard !didLogFinish else { return }
        didLogFinish = true
        let now = ProcessInfo.processInfo.systemUptime
        let duration = now - processStartUptime
        print("[LaunchTimingLogger] LaunchFinish \(marker) duration=\(String(format: "%.3f", duration))s")
    }
}
