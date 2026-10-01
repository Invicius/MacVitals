import Foundation
import IOKit
import IOKit.hidsystem

struct AppleSiliconTemperatureProvider: TemperatureProvider {
    private let validRange = 1.0...150.0

    func sensors() -> [TemperatureSensor] {
        let page = 0xff00
        let usage = 0x0005

        guard let system = IOHIDEventSystemClientCreate(kCFAllocatorDefault) else {
            return []
        }

        let matching: [String: Any] = [
            "PrimaryUsagePage": page,
            "PrimaryUsage": usage
        ]

        IOHIDEventSystemClientSetMatching(
            system,
            matching as CFDictionary
        )

        guard let services = IOHIDEventSystemClientCopyServices(system) as? [IOHIDServiceClient] else {
            return []
        }

        var readings: [(name: String, value: Double)] = []

        for service in services {
            let name = IOHIDServiceClientCopyProperty(
                service,
                "Product" as CFString
            ) as? String ?? "Unknown"

            guard let event = IOHIDServiceClientCopyEvent(
                service,
                Int64(kIOHIDEventTypeTemperature),
                0,
                0
            ) else {
                continue
            }

            let temperature = IOHIDEventGetFloatValue(
                event,
                Int32(kIOHIDEventTypeTemperature << 16)
            )

            guard validRange.contains(temperature) else {
                continue
            }

            readings.append((name, temperature))
        }

        // Vários sensores compartilham o mesmo nome, então o id recebe um sufixo por ocorrência.
        var occurrences: [String: Int] = [:]

        return readings
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { reading in
                let count = occurrences[reading.name, default: 0]
                occurrences[reading.name] = count + 1

                return TemperatureSensor(
                    id: "\(reading.name)#\(count)",
                    name: reading.name,
                    value: reading.value
                )
            }
    }
}
