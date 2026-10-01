import SwiftUI

/// Métricas que podem aparecer na barra de menus. A escolha fica salva no UserDefaults.
enum MenuBarItem: String, CaseIterable {
    case cpuTemperature
    case cpuUsage
    case memory
    case disk

    var storageKey: String { "menuBar.\(rawValue)" }

    var shownByDefault: Bool {
        switch self {
        case .cpuTemperature, .cpuUsage: true
        case .memory, .disk: false
        }
    }
}

/// Interruptor que liga ou desliga uma métrica na barra de menus.
struct MenuBarToggle: View {
    @AppStorage private var isOn: Bool

    init(item: MenuBarItem) {
        _isOn = AppStorage(wrappedValue: item.shownByDefault, item.storageKey)
    }

    var body: some View {
        Toggle("Mostrar na barra de menus", isOn: $isOn)
            .toggleStyle(.switch)
            .controlSize(.mini)
            .labelsHidden()
            .help("Mostrar na barra de menus")
    }
}
