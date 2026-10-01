import Foundation

/// Uso da CPU entre duas leituras. Valores de 0 a 1.
struct CPUUsage {
    let total: Double
    let user: Double
    let system: Double
    let cores: [Double]
}

/// Memória em bytes, com a mesma divisão do Monitor de Atividade.
struct MemoryUsage {
    let total: UInt64
    let app: UInt64
    let wired: UInt64
    let compressed: UInt64

    var used: UInt64 { app + wired + compressed }
    var usage: Double { total > 0 ? Double(used) / Double(total) : 0 }
}

/// Espaço do volume de inicialização e atividade de leitura/escrita do SSD interno.
struct DiskUsage {
    let name: String
    let total: Int64
    let available: Int64
    let readPerSecond: Double
    let writePerSecond: Double

    var used: Int64 { total - available }
    var usage: Double { total > 0 ? Double(used) / Double(total) : 0 }
}
