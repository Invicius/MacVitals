import Darwin

/// Lê os ticks de cada núcleo via `host_processor_info` e calcula o uso pela diferença entre leituras.
final class CPUUsageReader {
    private typealias Ticks = (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)

    private let host = mach_host_self()
    private var previous: [Ticks] = []

    init() {
        // Primeira leitura só guarda a referência para a próxima diferença.
        _ = read()
    }

    func read() -> CPUUsage? {
        guard let current = ticks() else { return nil }
        defer { previous = current }

        guard previous.count == current.count else { return nil }

        var user = 0.0, system = 0.0, total = 0.0
        var cores: [Double] = []

        for (old, new) in zip(previous, current) {
            // Subtração com overflow porque os contadores são UInt32 e podem dar a volta.
            let coreUser = Double((new.user &- old.user) &+ (new.nice &- old.nice))
            let coreSystem = Double(new.system &- old.system)
            let coreIdle = Double(new.idle &- old.idle)
            let coreTotal = coreUser + coreSystem + coreIdle

            user += coreUser
            system += coreSystem
            total += coreTotal
            cores.append(coreTotal > 0 ? (coreUser + coreSystem) / coreTotal : 0)
        }

        guard total > 0 else { return nil }

        return CPUUsage(
            total: (user + system) / total,
            user: user / total,
            system: system / total,
            cores: cores
        )
    }

    private func ticks() -> [Ticks]? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        guard host_processor_info(host, PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount) == KERN_SUCCESS,
              let info else {
            return nil
        }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: info),
                vm_size_t(Int(infoCount) * MemoryLayout<integer_t>.stride)
            )
        }

        let stride = Int(CPU_STATE_MAX)

        return (0..<Int(cpuCount)).map { cpu in
            let base = cpu * stride
            return (
                user: UInt32(bitPattern: info[base + Int(CPU_STATE_USER)]),
                system: UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)]),
                idle: UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)]),
                nice: UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)])
            )
        }
    }
}
