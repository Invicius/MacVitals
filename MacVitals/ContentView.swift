import SwiftUI

struct ContentView: View {
    let monitor: SystemMonitor

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 12)], spacing: 12) {
                    MacVitalsCard(monitor: monitor)
                    CPUUsageCard(usage: monitor.cpuUsage)
                    MemoryCard(memory: monitor.memory)
                    DiskCard(disk: monitor.disk)
                }

                SensorListCard(sensors: monitor.sensors)
            }
            .padding()
        }
        .frame(minWidth: 320, idealWidth: 560, minHeight: 420, idealHeight: 640)
    }
}

// MARK: - Cards

struct MacVitalsCard: View {
    let monitor: SystemMonitor

    var body: some View {
        MetricCard(title: "Temperatura da CPU", systemImage: "thermometer.medium", menuBarItem: .cpuTemperature) {
            if let temperature = monitor.cpuTemperature {
                BigValue(text: Format.temperature(temperature), color: Format.temperatureColor(temperature))
                ProgressView(value: min(temperature, 110), total: 110)
                    .tint(Format.temperatureColor(temperature))

                if let peak = monitor.cpuTemperaturePeak {
                    DetailRow(label: "Núcleo mais quente", value: Format.temperature(peak))
                }
                DetailRow(label: "Sensores", value: "\(monitor.cpuSensors.count)")
            } else {
                Placeholder(text: "Sensores da CPU não encontrados")
            }
        }
    }
}

struct CPUUsageCard: View {
    let usage: CPUUsage?

    var body: some View {
        MetricCard(title: "Uso da CPU", systemImage: "cpu", menuBarItem: .cpuUsage) {
            if let usage {
                BigValue(text: Format.percent(usage.total), color: Format.usageColor(usage.total))
                ProgressView(value: usage.total)
                    .tint(Format.usageColor(usage.total))
                DetailRow(label: "Usuário", value: Format.percent(usage.user))
                DetailRow(label: "Sistema", value: Format.percent(usage.system))

                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(usage.cores.indices, id: \.self) { index in
                        CoreBar(value: usage.cores[index])
                            .help("Núcleo \(index + 1): \(Format.percent(usage.cores[index]))")
                    }
                }
                .frame(height: 32)
            } else {
                Placeholder(text: "Medindo…")
            }
        }
    }
}

struct MemoryCard: View {
    let memory: MemoryUsage?

    var body: some View {
        MetricCard(title: "Uso da RAM", systemImage: "memorychip", menuBarItem: .memory) {
            if let memory {
                BigValue(text: Format.percent(memory.usage), color: Format.usageColor(memory.usage))
                ProgressView(value: memory.usage)
                    .tint(Format.usageColor(memory.usage))
                DetailRow(label: "Usada", value: "\(Format.memory(memory.used)) de \(Format.memory(memory.total))")
                DetailRow(label: "Apps", value: Format.memory(memory.app))
                DetailRow(label: "Fixa", value: Format.memory(memory.wired))
                DetailRow(label: "Comprimida", value: Format.memory(memory.compressed))
            } else {
                Placeholder(text: "Indisponível")
            }
        }
    }
}

struct DiskCard: View {
    let disk: DiskUsage?

    var body: some View {
        MetricCard(title: "Uso do SSD", systemImage: "internaldrive", menuBarItem: .disk) {
            if let disk {
                BigValue(text: Format.percent(disk.usage), color: Format.usageColor(disk.usage))
                ProgressView(value: disk.usage)
                    .tint(Format.usageColor(disk.usage))
                DetailRow(label: disk.name, value: "\(Format.file(disk.used)) de \(Format.file(disk.total))")
                DetailRow(label: "Livre", value: Format.file(disk.available))
                DetailRow(label: "Leitura", value: Format.speed(disk.readPerSecond))
                DetailRow(label: "Escrita", value: Format.speed(disk.writePerSecond))
            } else {
                Placeholder(text: "Indisponível")
            }
        }
    }
}

struct SensorListCard: View {
    let sensors: [TemperatureSensor]
    @State private var expanded = false

    var body: some View {
        MetricCard(title: "Todos os sensores de temperatura", systemImage: "list.bullet") {
            DisclosureGroup(expanded ? "Ocultar" : "Mostrar \(sensors.count) sensores", isExpanded: $expanded) {
                VStack(spacing: 4) {
                    ForEach(sensors) { sensor in
                        DetailRow(label: sensor.name, value: Format.temperature(sensor.value))
                    }
                }
                .padding(.top, 6)
            }
        }
    }
}

// MARK: - Componentes

struct MetricCard<Content: View>: View {
    let title: String
    let systemImage: String
    var menuBarItem: MenuBarItem? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)

                if let menuBarItem {
                    Spacer()
                    MenuBarToggle(item: menuBarItem)
                }
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct BigValue: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 34, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color)
            .contentTransition(.numericText())
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.callout)
    }
}

struct CoreBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Format.usageColor(value))
                    .frame(height: max(2, proxy.size.height * value))
            }
        }
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 2))
    }
}

struct Placeholder: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 60)
    }
}

// MARK: - Formatação

enum Format {
    static func temperature(_ value: Double) -> String {
        String(format: "%.1f °C", value)
    }

    static func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    static func memory(_ bytes: UInt64) -> String {
        Int64(bytes).formatted(.byteCount(style: .memory))
    }

    static func file(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }

    static func speed(_ bytesPerSecond: Double) -> String {
        Int64(bytesPerSecond).formatted(.byteCount(style: .file)) + "/s"
    }

    static func temperatureColor(_ value: Double) -> Color {
        switch value {
        case ..<60: .green
        case ..<80: .orange
        default: .red
        }
    }

    static func usageColor(_ value: Double) -> Color {
        switch value {
        case ..<0.6: .green
        case ..<0.85: .orange
        default: .red
        }
    }
}

#Preview {
    ContentView(monitor: SystemMonitor())
}
