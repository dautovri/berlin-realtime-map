import SwiftUI

/// A grid-based city picker for selecting one of the supported German transit cities.
/// Shown on first launch (when no city is saved) and accessible from SettingsView.
struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let services = ServiceContainer.shared
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    /// When `true`, tapping a city dismisses the picker (used when presented as a sheet).
    var dismissOnSelection: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(CityConfig.allCities) { city in
                        CityCard(
                            city: city,
                            isSelected: city.id == services.cityManager.currentCity.id
                        ) {
                            Task {
                                await services.updateCity(city)
                                if dismissOnSelection {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose City")
            #if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - City Card

private struct CityCard: View {
    let city: CityConfig
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Accent circle
                Circle()
                    .fill(city.accentColor)
                    .frame(width: 40, height: 40)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                // City name
                Text(city.name)
                    .font(.subheadline.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Transit authority
                Text(city.transitAuthority)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                isSelected
                    ? city.accentColor.opacity(0.12)
                    : Color(.secondarySystemGroupedBackground),
                in: .rect(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? city.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(city.name), \(city.transitAuthority)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(reduceMotion ? nil : .spring(duration: 0.25), value: isSelected)
    }
}

#Preview {
    CityPickerView()
}
