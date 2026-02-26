//
//  PerformanceMetrics.swift
//  DebugTool-iOS
//
//  Created by qiyongkaka on 2026/2/26.
//

import Foundation

final class PerformanceMetrics {
    private static let bytesPerMB: Double = 1024 * 1024

    static func cpuUsagePercentage() -> Double {
        var threadCount: mach_msg_type_number_t = 0
        var threadList: thread_act_array_t?
        let taskResult = task_threads(mach_task_self_, &threadList, &threadCount)
        guard taskResult == KERN_SUCCESS, let threadList else { return 0 }

        var totalUsage: Double = 0

        for index in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(threadInfoCount)) {
                    thread_info(threadList[index], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }

            if infoResult == KERN_SUCCESS {
                if (threadInfo.flags & TH_FLAGS_IDLE) == 0 {
                    totalUsage += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }
        }

        let size = vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadList), size)
        return totalUsage
    }

    static func memoryUsageMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.stride) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.phys_footprint) / bytesPerMB
    }

    static func deviceMemoryMB() -> Double {
        Double(ProcessInfo.processInfo.physicalMemory) / bytesPerMB
    }
}
