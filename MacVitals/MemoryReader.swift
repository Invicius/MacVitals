import Foundation

/// Lê as estatísticas da memória virtual via `host_statistics64`.
final class MemoryReader {
    private let host = mach_host_self()

    func read() -> MemoryUsage? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let internalPages = UInt64(stats.internal_page_count)
        let purgeable = UInt64(stats.purgeable_count)

        return MemoryUsage(
            total: ProcessInfo.processInfo.physicalMemory,
            app: (internalPages > purgeable ? internalPages - purgeable : 0) * pageSize,
            wired: UInt64(stats.wire_count) * pageSize,
            compressed: UInt64(stats.compressor_page_count) * pageSize
        )
    }
}
