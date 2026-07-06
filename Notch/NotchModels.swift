import Foundation

/// A child profile — a kid whose growth is tracked over multiple doorframe
/// photo measurements.
struct Child: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var birthDate: Date?
    var createdDate: Date

    init(id: UUID = UUID(), name: String, birthDate: Date? = nil, createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.createdDate = createdDate
    }
}

/// A single growth measurement for a child — a doorframe photo plus the
/// height measured at that moment, so the user builds up a photographic
/// timeline of literal pencil-notch marks alongside real numeric height.
struct GrowthMeasurement: Identifiable, Codable, Equatable {
    let id: UUID
    var childID: UUID
    var date: Date
    var heightInches: Double
    var note: String
    var photoData: Data?
    var createdDate: Date

    init(
        id: UUID = UUID(),
        childID: UUID,
        date: Date = Date(),
        heightInches: Double,
        note: String = "",
        photoData: Data? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.childID = childID
        self.date = date
        self.heightInches = heightInches
        self.note = note
        self.photoData = photoData
        self.createdDate = createdDate
    }
}
