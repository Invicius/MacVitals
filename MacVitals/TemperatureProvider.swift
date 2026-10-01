import Foundation

protocol TemperatureProvider {
    func sensors() -> [TemperatureSensor]
}
