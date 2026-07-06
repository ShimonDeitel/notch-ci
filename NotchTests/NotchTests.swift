import XCTest
@testable import Notch

@MainActor
final class NotchTests: XCTestCase {
    private func makeStore() -> NotchStore {
        let suffix = UUID().uuidString
        return NotchStore(childrenFileName: "test_children_\(suffix).json", measurementsFileName: "test_measurements_\(suffix).json")
    }

    func testAddChild() {
        let store = makeStore()
        let added = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        XCTAssertTrue(added)
        XCTAssertEqual(store.children.count, 1)
        XCTAssertEqual(store.children.first?.name, "Ari")
    }

    func testFreeLimitBlocksSecondChild() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        XCTAssertFalse(store.canAddChild(isPro: false))
        let added = store.addChild(name: "Noa", birthDate: nil, isPro: false)
        XCTAssertFalse(added)
        XCTAssertEqual(store.children.count, 1)
    }

    func testProAllowsMultipleChildren() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: true)
        let added = store.addChild(name: "Noa", birthDate: nil, isPro: true)
        XCTAssertTrue(added)
        XCTAssertEqual(store.children.count, 2)
    }

    func testUpdateChild() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let id = store.children.first?.id else { return XCTFail("no child") }
        store.updateChild(id, name: "Arik", birthDate: nil)
        XCTAssertEqual(store.children.first?.name, "Arik")
    }

    func testDeleteChildRemovesMeasurements() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let childID = store.children.first?.id else { return XCTFail("no child") }
        store.addMeasurement(childID: childID, date: Date(), heightInches: 40, note: "", photoData: nil)
        store.deleteChild(childID)
        XCTAssertTrue(store.children.isEmpty)
        XCTAssertTrue(store.measurements(for: childID).isEmpty)
    }

    func testAddMeasurement() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let childID = store.children.first?.id else { return XCTFail("no child") }
        store.addMeasurement(childID: childID, date: Date(), heightInches: 42.5, note: "growing", photoData: nil)
        XCTAssertEqual(store.measurements(for: childID).count, 1)
        XCTAssertEqual(store.measurements(for: childID).first?.heightInches, 42.5)
    }

    func testUpdateMeasurement() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let childID = store.children.first?.id else { return XCTFail("no child") }
        store.addMeasurement(childID: childID, date: Date(), heightInches: 40, note: "", photoData: nil)
        guard let mid = store.measurements(for: childID).first?.id else { return XCTFail("no measurement") }
        store.updateMeasurement(mid, date: Date(), heightInches: 41, note: "updated", photoData: nil)
        XCTAssertEqual(store.measurements(for: childID).first?.heightInches, 41)
        XCTAssertEqual(store.measurements(for: childID).first?.note, "updated")
    }

    func testDeleteMeasurement() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let childID = store.children.first?.id else { return XCTFail("no child") }
        store.addMeasurement(childID: childID, date: Date(), heightInches: 40, note: "", photoData: nil)
        guard let mid = store.measurements(for: childID).first?.id else { return XCTFail("no measurement") }
        store.deleteMeasurement(mid)
        XCTAssertTrue(store.measurements(for: childID).isEmpty)
    }

    func testMeasurementsSortedByDateAscending() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let childID = store.children.first?.id else { return XCTFail("no child") }
        let earlier = Date().addingTimeInterval(-86400 * 30)
        let later = Date()
        store.addMeasurement(childID: childID, date: later, heightInches: 42, note: "", photoData: nil)
        store.addMeasurement(childID: childID, date: earlier, heightInches: 40, note: "", photoData: nil)
        let sorted = store.measurements(for: childID)
        XCTAssertEqual(sorted.first?.heightInches, 40)
        XCTAssertEqual(sorted.last?.heightInches, 42)
    }

    func testGrowthSincePrevious() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let childID = store.children.first?.id else { return XCTFail("no child") }
        let earlier = Date().addingTimeInterval(-86400 * 30)
        let later = Date()
        store.addMeasurement(childID: childID, date: earlier, heightInches: 40, note: "", photoData: nil)
        store.addMeasurement(childID: childID, date: later, heightInches: 42.5, note: "", photoData: nil)
        guard let latestID = store.measurements(for: childID).last?.id else { return XCTFail("no measurement") }
        let growth = store.growthSincePrevious(childID: childID, measurementID: latestID)
        XCTAssertEqual(growth ?? 0, 2.5, accuracy: 0.001)
    }

    func testGrowthSincePreviousNilForFirstMeasurement() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let childID = store.children.first?.id else { return XCTFail("no child") }
        store.addMeasurement(childID: childID, date: Date(), heightInches: 40, note: "", photoData: nil)
        guard let mid = store.measurements(for: childID).first?.id else { return XCTFail("no measurement") }
        XCTAssertNil(store.growthSincePrevious(childID: childID, measurementID: mid))
    }

    func testDeleteAllData() {
        let store = makeStore()
        _ = store.addChild(name: "Ari", birthDate: nil, isPro: false)
        guard let childID = store.children.first?.id else { return XCTFail("no child") }
        store.addMeasurement(childID: childID, date: Date(), heightInches: 40, note: "", photoData: nil)
        store.deleteAllData()
        XCTAssertTrue(store.children.isEmpty)
    }

    func testPersistenceRoundTrip() {
        let suffix = UUID().uuidString
        let childrenFile = "test_persist_children_\(suffix).json"
        let measurementsFile = "test_persist_measurements_\(suffix).json"
        let store1 = NotchStore(childrenFileName: childrenFile, measurementsFileName: measurementsFile)
        _ = store1.addChild(name: "Persisted", birthDate: nil, isPro: false)
        guard let childID = store1.children.first?.id else { return XCTFail("no child") }
        store1.addMeasurement(childID: childID, date: Date(), heightInches: 40, note: "", photoData: nil)

        let store2 = NotchStore(childrenFileName: childrenFile, measurementsFileName: measurementsFile)
        XCTAssertEqual(store2.children.count, 1)
        XCTAssertEqual(store2.measurements(for: childID).count, 1)
    }
}
