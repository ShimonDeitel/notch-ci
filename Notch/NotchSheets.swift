import SwiftUI
import PhotosUI

/// One unified sheet enum for the whole app — a single `.sheet(item:)` per
/// screen, per the standing rule.
enum NotchSheet: Identifiable {
    case addChild
    case editChild(Child)
    case addMeasurement(childID: UUID)
    case editMeasurement(GrowthMeasurement)
    case paywall

    var id: String {
        switch self {
        case .addChild: return "addChild"
        case .editChild(let c): return "editChild-\(c.id)"
        case .addMeasurement(let id): return "addMeasurement-\(id)"
        case .editMeasurement(let m): return "editMeasurement-\(m.id)"
        case .paywall: return "paywall"
        }
    }
}

struct ChildFormView: View {
    @EnvironmentObject private var store: NotchStore
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    let existing: Child?

    @State private var name: String
    @State private var birthDate: Date
    @State private var hasBirthDate: Bool

    init(existing: Child?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _birthDate = State(initialValue: existing?.birthDate ?? Date())
        _hasBirthDate = State(initialValue: existing?.birthDate != nil)
    }

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    TextField("Name", text: $name)
                        .accessibilityIdentifier("childNameField")
                    Toggle("Track birth date", isOn: $hasBirthDate)
                        .accessibilityIdentifier("hasBirthDateToggle")
                    if hasBirthDate {
                        DatePicker("Birth date", selection: $birthDate, displayedComponents: .date)
                            .accessibilityIdentifier("birthDateField")
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Child", role: .destructive) {
                            if let existing {
                                store.deleteChild(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteChildButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Child" : "New Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .buttonStyle(.plain)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("saveChildButton")
                }
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let finalBirthDate: Date? = hasBirthDate ? birthDate : nil
        if let existing {
            store.updateChild(existing.id, name: name, birthDate: finalBirthDate)
            dismiss()
        } else {
            guard store.canAddChild(isPro: purchases.isPro) else { return }
            store.addChild(name: name, birthDate: finalBirthDate, isPro: purchases.isPro)
            dismiss()
        }
    }
}

struct MeasurementFormView: View {
    @EnvironmentObject private var store: NotchStore
    @Environment(\.dismiss) private var dismiss

    let childID: UUID
    let existing: GrowthMeasurement?

    @State private var date: Date
    @State private var heightFeet: Int
    @State private var heightRemainderInches: Double
    @State private var note: String
    @State private var pickerItem: PhotosPickerItem?
    @State private var photoData: Data?

    init(childID: UUID, existing: GrowthMeasurement?) {
        self.childID = childID
        self.existing = existing
        _date = State(initialValue: existing?.date ?? Date())
        let totalInches = existing?.heightInches ?? 36.0
        _heightFeet = State(initialValue: Int(totalInches) / 12)
        _heightRemainderInches = State(initialValue: totalInches.truncatingRemainder(dividingBy: 12))
        _note = State(initialValue: existing?.note ?? "")
        _photoData = State(initialValue: existing?.photoData)
    }

    private var isEditing: Bool { existing != nil }
    private var totalInches: Double { Double(heightFeet * 12) + heightRemainderInches }

    var body: some View {
        NavigationStack {
            Form {
                Section("Measurement Day") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("measurementDateField")
                }

                Section("Height") {
                    Stepper("Feet: \(heightFeet)", value: $heightFeet, in: 0...8)
                        .accessibilityIdentifier("heightFeetStepper")
                    Stepper(String(format: "Inches: %.1f", heightRemainderInches), value: $heightRemainderInches, in: 0...11.75, step: 0.25)
                        .accessibilityIdentifier("heightInchesStepper")
                    Text(String(format: "Total: %.1f in", totalInches))
                        .font(.caption)
                        .foregroundStyle(NOTheme.inkFaded)
                }

                Section("Doorframe Photo") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        photoRow
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("doorframePhotoPicker")
                }

                Section("Notes") {
                    TextField("Anything notable (optional)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .accessibilityIdentifier("measurementNoteField")
                }

                if isEditing {
                    Section {
                        Button("Delete Measurement", role: .destructive) {
                            if let existing {
                                store.deleteMeasurement(existing.id)
                            }
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("deleteMeasurementButton")
                    }
                }
            }
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit Notch" : "New Notch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .buttonStyle(.plain)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("saveMeasurementButton")
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let item, let data = try? await item.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var photoRow: some View {
        HStack {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "camera.fill")
                    .foregroundStyle(NOTheme.skyDeep)
                    .frame(width: 44, height: 44)
            }
            Text(photoData != nil ? "Doorframe photo added" : "Add doorframe photo")
                .foregroundStyle(NOTheme.ink)
            Spacer()
        }
    }

    private func save() {
        if let existing {
            store.updateMeasurement(existing.id, date: date, heightInches: totalInches, note: note, photoData: photoData)
            dismiss()
        } else {
            store.addMeasurement(childID: childID, date: date, heightInches: totalInches, note: note, photoData: photoData)
            dismiss()
        }
    }
}
