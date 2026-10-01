import Foundation
import IOKit

/// Lê o espaço do volume de inicialização e os bytes lidos/escritos pelos discos internos.
final class DiskReader {
    private var previous: (read: UInt64, write: UInt64, time: ContinuousClock.Instant)?

    init() {
        // Primeira leitura só guarda a referência para calcular a taxa.
        _ = read()
    }

    func read() -> DiskUsage? {
        let keys: Set<URLResourceKey> = [
            .volumeLocalizedNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]

        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacityForImportantUsage else {
            return nil
        }

        let bytes = ioBytes()
        let now = ContinuousClock.now
        var readPerSecond = 0.0
        var writePerSecond = 0.0

        if let previous {
            let elapsed = (now - previous.time) / .seconds(1)
            if elapsed > 0 {
                readPerSecond = Double(bytes.read &- previous.read) / elapsed
                writePerSecond = Double(bytes.write &- previous.write) / elapsed
            }
        }

        previous = (bytes.read, bytes.write, now)

        return DiskUsage(
            name: values.volumeLocalizedName ?? "Macintosh HD",
            total: Int64(total),
            available: available,
            readPerSecond: readPerSecond,
            writePerSecond: writePerSecond
        )
    }

    private func ioBytes() -> (read: UInt64, write: UInt64) {
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IOBlockStorageDriver"),
            &iterator
        ) == KERN_SUCCESS else {
            return (0, 0)
        }

        defer { IOObjectRelease(iterator) }

        var read: UInt64 = 0
        var write: UInt64 = 0
        var entry = IOIteratorNext(iterator)

        while entry != 0 {
            defer {
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }

            guard isInternal(entry),
                  let statistics = IORegistryEntryCreateCFProperty(
                      entry,
                      "Statistics" as CFString,
                      kCFAllocatorDefault,
                      0
                  )?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            read += (statistics["Bytes (Read)"] as? NSNumber)?.uint64Value ?? 0
            write += (statistics["Bytes (Write)"] as? NSNumber)?.uint64Value ?? 0
        }

        return (read, write)
    }

    // Ignora pendrives e discos externos procurando a localização física no controlador pai.
    private func isInternal(_ entry: io_registry_entry_t) -> Bool {
        let characteristics = IORegistryEntrySearchCFProperty(
            entry,
            kIOServicePlane,
            "Protocol Characteristics" as CFString,
            kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        ) as? [String: Any]

        return characteristics?["Physical Interconnect Location"] as? String == "Internal"
    }
}
