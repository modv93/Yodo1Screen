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

    @objc public func stopTracking() -> [String: [String: Double]] {
        timer?.invalidate()
        timer = nil
        return [
            "cpu": calculateStats(for: cpuUsage),
            "gpu": calculateStats(for: gpuUsage),
            "ram": calculateStats(for: ramUsage)
        ]
    }

    @objc private func trackUsage() {
        cpuUsage.append(getCPUUsage())
        gpuUsage.append(getGPUUsage())
        ramUsage.append(getRAMUsage())
    }

    private func getCPUUsage() -> Double {
        var kr: kern_return_t
        var task_info_count: mach_msg_type_number_t = mach_msg_type_number_t(TASK_INFO_MAX)
        var tinfo = task_info_t.allocate(capacity: Int(task_info_count))
        defer { tinfo.deallocate() }

        kr = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), tinfo, &task_info_count)
        if kr != KERN_SUCCESS {
            return -1.0
        }

        let task_basic_info_ptr = tinfo.withMemoryRebound(to: task_basic_info.self, capacity: 1) { $0 }
        let basic_info = task_basic_info_ptr.pointee

        var thread_list: thread_act_array_t?
        var thread_count: mach_msg_type_number_t = 0
        kr = task_threads(mach_task_self_, &thread_list, &thread_count)
        if kr != KERN_SUCCESS {
            return -1.0
        }

        var tot_cpu: Double = 0
        if let thread_list = thread_list {
            for i in 0..<thread_count {
                var thread_info_count: mach_msg_type_number_t = mach_msg_type_number_t(THREAD_INFO_MAX)
                var thinfo = thread_info_t.allocate(capacity: Int(thread_info_count))
                defer { thinfo.deallocate() }

                kr = thread_info(thread_list[Int(i)], thread_flavor_t(THREAD_BASIC_INFO), thinfo, &thread_info_count)
                if kr != KERN_SUCCESS {
                    return -1.0
                }

                let thread_basic_info_ptr = thinfo.withMemoryRebound(to: thread_basic_info.self, capacity: 1) { $0 }
                let thread_basic_info = thread_basic_info_ptr.pointee

                if thread_basic_info.flags & TH_FLAGS_IDLE == 0 {
                    tot_cpu += Double(thread_basic_info.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: thread_list), vm_size_t(Int(thread_count) * MemoryLayout<thread_t>.stride))
        }

        return tot_cpu
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

        let gpuUsagePercentage = (gpuUsageTime / totalElapsedTime) * 100.0
        return gpuUsagePercentage
    }

    private func getRAMUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Double(info.resident_size)
        } else {
            return -1
        }
    }

    private func calculateStats(for data: [Double]) -> [String: Double] {
        guard !data.isEmpty else { return ["min": 0, "max": 0, "avg": 0] }

        let min = data.min() ?? 0
        let max = data.max() ?? 0
        let avg = data.reduce(0, +) / Double(data.count)

        return ["min": min, "max": max, "avg": avg]
    }
}

