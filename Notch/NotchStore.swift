import Foundation

@MainActor
final class NotchStore: ObservableObject {
    @Published private(set) var children: [Child] = []
    @Published private(set) var measurements: [GrowthMeasurement] = []

    /// Free tier: 1 child, unlimited measurements for that child. Pro unlocks
    /// additional children (siblings).
    private let freeChildLimit = 1
    private let childrenURL: URL
    private let measurementsURL: URL

    init(childrenFileName: String = "notch_children.json", measurementsFileName: String = "notch_measurements.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        childrenURL = dir.appendingPathComponent(childrenFileName)
        measurementsURL = dir.appendingPathComponent(measurementsFileName)
        load()
    }

    func canAddChild(isPro: Bool) -> Bool {
        isPro || children.count < freeChildLimit
    }

    @discardableResult
    func addChild(name: String, birthDate: Date?, isPro: Bool) -> Bool {
        guard canAddChild(isPro: isPro) else { return false }
        children.append(Child(name: name, birthDate: birthDate))
        saveChildren()
        return true
    }

    func updateChild(_ id: UUID, name: String, birthDate: Date?) {
        guard let idx = children.firstIndex(where: { $0.id == id }) else { return }
        children[idx].name = name
        children[idx].birthDate = birthDate
        saveChildren()
    }

    func deleteChild(_ id: UUID) {
        children.removeAll { $0.id == id }
        measurements.removeAll { $0.childID == id }
        saveChildren()
        saveMeasurements()
    }

    func measurements(for childID: UUID) -> [GrowthMeasurement] {
        measurements.filter { $0.childID == childID }.sorted { $0.date < $1.date }
    }

    func addMeasurement(
        childID: UUID,
        date: Date,
        heightInches: Double,
        note: String,
        photoData: Data?
    ) {
        let measurement = GrowthMeasurement(childID: childID, date: date, heightInches: heightInches, note: note, photoData: photoData)
        measurements.append(measurement)
        saveMeasurements()
    }

    func updateMeasurement(
        _ id: UUID,
        date: Date,
        heightInches: Double,
        note: String,
        photoData: Data?
    ) {
        guard let idx = measurements.firstIndex(where: { $0.id == id }) else { return }
        measurements[idx].date = date
        measurements[idx].heightInches = heightInches
        measurements[idx].note = note
        measurements[idx].photoData = photoData
        saveMeasurements()
    }

    func deleteMeasurement(_ id: UUID) {
        measurements.removeAll { $0.id == id }
        saveMeasurements()
    }

    func deleteAllData() {
        children.removeAll()
        measurements.removeAll()
        saveChildren()
        saveMeasurements()
    }

    /// The signature feature: growth rate since the previous measurement,
    /// in inches — surfaced as a literal "grew X inches since last notch"
    /// callout.
    func growthSincePrevious(childID: UUID, measurementID: UUID) -> Double? {
        let sorted = measurements(for: childID)
        guard let idx = sorted.firstIndex(where: { $0.id == measurementID }), idx > 0 else { return nil }
        return sorted[idx].heightInches - sorted[idx - 1].heightInches
    }

    private func load() {
        if let data = try? Data(contentsOf: childrenURL),
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            children = decoded
        }
        if let data = try? Data(contentsOf: measurementsURL),
           let decoded = try? JSONDecoder().decode([GrowthMeasurement].self, from: data) {
            measurements = decoded
        }
    }

    private func saveChildren() {
        guard let data = try? JSONEncoder().encode(children) else { return }
        try? data.write(to: childrenURL, options: .atomic)
    }

    private func saveMeasurements() {
        guard let data = try? JSONEncoder().encode(measurements) else { return }
        try? data.write(to: measurementsURL, options: .atomic)
    }
}
