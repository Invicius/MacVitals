import Foundation
import Observation

@Observable
final class SystemMonitor {
    private(set) var sensors: [TemperatureSensor] = []
    private(set) var cpuUsage: CPUUsage?
    private(set) var memory: MemoryUsage?
    private(set) var disk: DiskUsage?

    private let temperatureProvider: TemperatureProvider
    private let cpuReader = CPUUsageReader()
    private let memoryReader = MemoryReader()
    private let diskReader = DiskReader()
    private let interval: Duration
    private var task: Task<Void, Never>?

    init(
        temperatureProvider: TemperatureProvider = AppleSiliconTemperatureProvider(),
        interval: Duration = .seconds(2)
    ) {
        self.temperatureProvider = temperatureProvider
        self.interval = interval
        start()
    }

    /// Sensores dos núcleos da CPU. "PMU tdie" vale para M2 em diante, "ACC MTR" para M1.
    var cpuSensors: [TemperatureSensor] {
        sensors.filter { $0.name.contains("tdie") || $0.name.contains("ACC MTR") }
    }

    var cpuTemperature: Double? {
        let values = cpuSensors.map(\.value)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    var cpuTemperaturePeak: Double? {
        cpuSensors.map(\.value).max()
    }

    func start() {
        guard task == nil else { return }

        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.refresh()
                try? await Task.sleep(for: self.interval)
            }
        }
    }

    func refresh() {
        sensors = temperatureProvider.sensors()
        cpuUsage = cpuReader.read() ?? cpuUsage
        memory = memoryReader.read()
        disk = diskReader.read()
    }
}
