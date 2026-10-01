//
//  MacVitalsApp.swift
//  MacVitals
//
//  Created by vini on 30/09/26.
//

import SwiftUI

@main
struct MacVitalsApp: App {
    @State private var monitor = SystemMonitor()

    var body: some Scene {
        Window("MacVitals", id: "main") {
            ContentView(monitor: monitor)
        }

        MenuBarExtra {
            MenuBarView(monitor: monitor)
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
