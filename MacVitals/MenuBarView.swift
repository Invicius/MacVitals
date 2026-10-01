import SwiftUI

/// Texto curto exibido na barra de menus, como no Stats. Mostra só as métricas ligadas nos cartões.
struct MenuBarLabel: View {
    let monitor: SystemMonitor

    @AppStorage(MenuBarItem.cpuTemperature.storageKey) private var showTemperature = MenuBarItem.cpuTemperature.shownByDefault
    @AppStorage(MenuBarItem.cpuUsage.storageKey) private var showCPU = MenuBarItem.cpuUsage.shownByDefault
    @AppStorage(MenuBarItem.memory.storageKey) private var showMemory = MenuBarItem.memory.shownByDefault
    @AppStorage(MenuBarItem.disk.storageKey) private var showDisk = MenuBarItem.disk.shownByDefault

    var body: some View {
        if parts.isEmpty {
            // Sem nenhuma métrica ligada o item sumiria da barra, então mostra o ícone para continuar clicável.
            Image(systemName: "waveform.path.ecg")
        } else {
            Text(parts.joined(separator: "  "))
                .monospacedDigit()
        }
    }

    private var parts: [String] {
        var parts: [String] = []

        if showTemperature {
            parts.append("TEMP " + (monitor.cpuTemperature.map { "\(Int($0.rounded()))°" } ?? "--°"))
        }
        if showCPU {
            parts.append("CPU " + (monitor.cpuUsage.map { Format.percent($0.total) } ?? "--%"))
        }
        if showMemory {
            parts.append("RAM " + (monitor.memory.map { Format.percent($0.usage) } ?? "--%"))
        }
        if showDisk {
            parts.append("SSD " + (monitor.disk.map { Format.percent($0.usage) } ?? "--%"))
        }

        return parts
    }
}

struct MenuBarView: View {
    let monitor: SystemMonitor
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 10) {
            MacVitalsCard(monitor: monitor)
            CPUUsageCard(usage: monitor.cpuUsage)
            MemoryCard(memory: monitor.memory)
            DiskCard(disk: monitor.disk)

            HStack {
                Button("Abrir janela") {
                    openWindow(id: "main")
                    NSApp.activate()
                }
                Spacer()
                Button("Sair") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
