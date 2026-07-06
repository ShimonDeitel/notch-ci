import SwiftUI

struct NotchHomeView: View {
    @EnvironmentObject private var store: NotchStore
    @EnvironmentObject private var purchases: PurchaseManager
    @State private var activeSheet: NotchSheet?
    @State private var selectedChildID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                NOTheme.backdrop.ignoresSafeArea()

                if store.children.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            childPicker
                                .padding(.top, 8)

                            if let childID = selectedChildID ?? store.children.first?.id {
                                DoorframeView(measurements: store.measurements(for: childID))
                                    .frame(height: 320)
                                    .padding(.horizontal, 4)

                                let entries = store.measurements(for: childID).sorted { $0.date > $1.date }
                                ForEach(entries) { measurement in
                                    MeasurementRow(
                                        measurement: measurement,
                                        growth: store.growthSincePrevious(childID: childID, measurementID: measurement.id)
                                    ) {
                                        activeSheet = .editMeasurement(measurement)
                                    } onDelete: {
                                        store.deleteMeasurement(measurement.id)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Notch")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Measurement") {
                            if let childID = selectedChildID ?? store.children.first?.id {
                                activeSheet = .addMeasurement(childID: childID)
                            }
                        }
                        Button("Add Child") {
                            if store.canAddChild(isPro: purchases.isPro) {
                                activeSheet = .addChild
                            } else {
                                activeSheet = .paywall
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addMenuButton")
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addChild:
                    ChildFormView(existing: nil)
                case .editChild(let child):
                    ChildFormView(existing: child)
                case .addMeasurement(let childID):
                    MeasurementFormView(childID: childID, existing: nil)
                case .editMeasurement(let measurement):
                    MeasurementFormView(childID: measurement.childID, existing: measurement)
                case .paywall:
                    PaywallView()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "ruler.fill")
                .font(.system(size: 64))
                .foregroundStyle(NOTheme.grass)
            Text("Mark your child's growth")
                .font(NOTheme.headlineFont)
                .foregroundStyle(NOTheme.ink)
            Text("Take a doorframe photo each time you measure, and watch the notches climb.")
                .font(.subheadline)
                .foregroundStyle(NOTheme.inkFaded)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Add First Child") {
                activeSheet = .addChild
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(NOTheme.skyDeep)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .accessibilityIdentifier("addFirstChildButton")
        }
    }

    private var childPicker: some View {
        HStack {
            ForEach(store.children) { child in
                Button {
                    selectedChildID = child.id
                } label: {
                    Text(child.name)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background((selectedChildID ?? store.children.first?.id) == child.id ? NOTheme.skyDeep : NOTheme.surfaceRaised)
                        .foregroundStyle((selectedChildID ?? store.children.first?.id) == child.id ? Color.white : NOTheme.ink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("childChip_\(child.name)")
            }
            Spacer()
        }
    }
}

/// The quirky signature feature: a literal wood doorframe with horizontal
/// pencil-mark notches at each measurement's height, tallest at top —
/// exactly the real-world ritual this app digitizes.
struct DoorframeView: View {
    let measurements: [GrowthMeasurement]

    var body: some View {
        GeometryReader { geo in
            let maxHeight = max(measurements.map(\.heightInches).max() ?? 40, 40)
            ZStack(alignment: .bottomLeading) {
                // wood doorframe post
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [NOTheme.pencil.opacity(0.85), NOTheme.pencil],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * 0.22)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                ForEach(measurements) { measurement in
                    let ratio = measurement.heightInches / maxHeight
                    let y = geo.size.height * (1 - min(1, ratio))
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(NOTheme.ink)
                            .frame(width: geo.size.width * 0.30, height: 3)
                        Text(String(format: "%.0f\"", measurement.heightInches))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(NOTheme.ink)
                    }
                    .position(x: geo.size.width * 0.34, y: y)
                    .accessibilityIdentifier("notchMark_\(measurement.id)")
                }
            }
        }
        .accessibilityIdentifier("doorframeView")
    }
}

struct MeasurementRow: View {
    let measurement: GrowthMeasurement
    let growth: Double?
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            if let photoData = measurement.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(NOTheme.surfaceRaised)
                        .frame(width: 48, height: 48)
                    Image(systemName: "ruler.fill")
                        .foregroundStyle(NOTheme.skyDeep)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(Self.dateFormatter.string(from: measurement.date))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(NOTheme.ink)
                Text(String(format: "%.1f in", measurement.heightInches))
                    .font(.caption)
                    .foregroundStyle(NOTheme.inkFaded)
                if let growth, growth > 0 {
                    Text(String(format: "Grew %.1f in since last notch", growth))
                        .font(.caption2)
                        .foregroundStyle(NOTheme.grass)
                }
            }

            Spacer()

            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive) { showDeleteConfirm = true }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(NOTheme.sky)
                    .frame(width: 32, height: 32)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("measurementMenu_\(measurement.id)")
            .accessibilityAddTraits(.isButton)
            .contentShape(Rectangle())
        }
        .padding(14)
        .background(NOTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .confirmationDialog("Delete this measurement?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
}
