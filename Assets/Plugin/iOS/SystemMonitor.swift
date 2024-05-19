import Foundation
import UIKit
import Metal

@objc public class SystemMonitor: NSObject {
    private var timer: Timer?
    private var cpuUsage: [Double] = []
    private var gpuUsage: [Double] = []
    private var ramUsage: [Double] = []

    @objc public static let shared = SystemMonitor()

    @objc public func startTracking() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(trackUsage), userInfo: nil, repeats: true)
    }

    @objc public func stopTracking() -> [String: [Double]] {
        timer?.invalidate()
        timer = nil
        return ["cpu": cpuUsage, "gpu": gpuUsage, "ram": ramUsage]
    }

    @objc private func trackUsage() {
        cpuUsage.append(getCPUUsage())
        gpuUsage.append(getGPUUsage())
        ramUsage.append(getRAMUsage())
    }

    private func getCPUUsage() -> Double {
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t
        var tinfo = task_info_t.allocate(capacity: Int(TASK_INFO_MAX))
        task_info_count = mach_msg_type_number_t(TASK_INFO_MAX)
        kr = task_info(mach_task_self_, task_flavor_t(TASK_THREAD_TIMES_INFO), tinfo, &task_info_count)
        if kr != KERN_SUCCESS {
            return -1
        }

        let taskInfo = tinfo.withMemoryRebound(to: task_thread_times_info.self, capacity: 1) { $0.pointee }
        let totalCPUTime = taskInfo.user_time.seconds + taskInfo.system_time.seconds
        let cpuUsage = Double(totalCPUTime) * 100.0
        return cpuUsage
    }

    private func getGPUUsage() -> Double {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return -1
        }

        let commandQueue = device.makeCommandQueue()

        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return -1
        }

        let start = CACurrentMediaTime()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let end = CACurrentMediaTime()

        let gpuUsageTime = end - start
        let totalElapsedTime = 1.0 // Assume 1 second interval for tracking
        
        // Convert to percentage
        let gpuUsagePercentage = (gpuUsageTime / totalElapsedTime) * 100.0
        return gpuUsagePercentage
    }

    private func getRAMUsage() -> Double {
        let usedMemory = report_memory()
        return Double(usedMemory)
    }

    private func report_memory() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout.size(ofValue: taskInfo) / MemoryLayout<Int32>.size)
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return taskInfo.resident_size
        } else {
            return 0
        }
    }
}
