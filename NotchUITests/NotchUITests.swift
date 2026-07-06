import XCTest

final class NotchUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddFirstChild() {
        let addFirstChildButton = app.buttons["addFirstChildButton"]
        XCTAssertTrue(addFirstChildButton.waitForExistence(timeout: 5))
        addFirstChildButton.tap()
        let nameField = app.textFields["childNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Ari")
        app.buttons["saveChildButton"].tap()
        XCTAssertTrue(app.navigationBars["Notch"].waitForExistence(timeout: 5))
    }

    func testAddMeasurementViaMenu() {
        addSeedChild()
        let addMenu = app.buttons["addMenuButton"]
        XCTAssertTrue(addMenu.waitForExistence(timeout: 5))
        addMenu.tap()
        app.buttons["Add Measurement"].tap()
        let saveButton = app.buttons["saveMeasurementButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        XCTAssertTrue(app.navigationBars["Notch"].waitForExistence(timeout: 5))
    }

    func testEditMeasurementViaMenu() {
        addSeedChild()
        addSeedMeasurement()
        let menu = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'measurementMenu_'")).firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["Edit"].tap()
        let saveButton = app.buttons["saveMeasurementButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
    }

    func testDeleteMeasurementViaMenu() {
        addSeedChild()
        addSeedMeasurement()
        let menu = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'measurementMenu_'")).firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        app.buttons["Delete"].tap()
        let deleteButtons = app.buttons.matching(identifier: "Delete")
        let confirmDelete = deleteButtons.element(boundBy: max(0, deleteButtons.count - 1))
        if confirmDelete.waitForExistence(timeout: 3) {
            confirmDelete.tap()
        }
    }

    func testSettingsTabOpensAndTogglesUnits() {
        app.tabBars.buttons["Settings"].tap()
        let toggle = app.switches["useMetricToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
    }

    func testSecondChildTriggersPaywall() {
        addSeedChild()
        let addMenu = app.buttons["addMenuButton"]
        XCTAssertTrue(addMenu.waitForExistence(timeout: 5))
        addMenu.tap()
        app.buttons["Add Child"].tap()
        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5))
    }

    private func addSeedChild() {
        let addFirstChildButton = app.buttons["addFirstChildButton"]
        if addFirstChildButton.waitForExistence(timeout: 5) {
            addFirstChildButton.tap()
            let nameField = app.textFields["childNameField"]
            nameField.tap()
            nameField.typeText("Ari")
            app.buttons["saveChildButton"].tap()
        }
    }

    private func addSeedMeasurement() {
        let addMenu = app.buttons["addMenuButton"]
        if addMenu.waitForExistence(timeout: 5) {
            addMenu.tap()
            app.buttons["Add Measurement"].tap()
            app.buttons["saveMeasurementButton"].tap()
        }
    }
}
