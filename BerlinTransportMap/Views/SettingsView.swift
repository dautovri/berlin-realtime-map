import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var alertManager = CommuteAlertManager.shared
    @State private var savedStops: [Favorite] = []
    @State private var showingAddAlert = false

    private let services = ServiceContainer.shared

    /// The three states a user can actually reason about. Persisted to the
    /// existing `useSystemTheme`/`darkMode` keys that `ContentView` and the
    /// widget already read, so nothing downstream changes.
    enum ThemeSelection: Hashable {
        case system, light, dark
    }

    private var themeSelection: Binding<ThemeSelection> {
        Binding {
            if useSystemTheme { return .system }
            return darkMode ? .dark : .light
        } set: { newValue in
            switch newValue {
            case .system:
                useSystemTheme = true
            case .light:
                useSystemTheme = false
                darkMode = false
            case .dark:
                useSystemTheme = false
                darkMode = true
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: City
                Section {
                    // Seven inline city rows pushed every other setting below the
                    // fold. One row that states the current city is enough.
                    NavigationLink {
                        CityPickerView(dismissOnSelection: false)
                    } label: {
                        HStack {
                            Text("City")
                                .foregroundStyle(.primary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(services.cityManager.currentCity.name)
                                    .font(.subheadline)
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.secondary)
                                Text(services.cityManager.currentCity.transitAuthority)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("City")
                }

                // MARK: Appearance
                Section {
                    // Two independent toggles let the user reach a state where
                    // "Dark Mode" is on but visibly does nothing. One picker can't.
                    Picker("Theme", selection: themeSelection) {
                        Text("System").tag(ThemeSelection.system)
                        Text("Light").tag(ThemeSelection.light)
                        Text("Dark").tag(ThemeSelection.dark)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                }

                // MARK: Commute Alerts
                Section {
                    switch alertManager.permissionStatus {
                    case .denied:
                        permissionDeniedRow
                    case .notDetermined:
                        if alertManager.alerts.isEmpty {
                            enableAlertsRow
                        } else {
                            alertRows
                        }
                    default:
                        alertRows
                    }
                } header: {
                    Text("Commute Alerts")
                } footer: {
                    Text("Get a daily reminder to check departures for your saved stop.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
            #if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddAlert) {
                AddCommuteAlertSheet(stops: savedStops, alertManager: alertManager)
            }
            .task {
                await alertManager.refreshPermissionStatus()
                loadStops()
            }
        }
    }

    // MARK: - Permission rows

    private var enableAlertsRow: some View {
        Button {
            Task {
                let granted = await alertManager.requestPermission()
                if granted { showingAddAlert = true }
            }
        } label: {
            Label("Enable Commute Alerts", systemImage: "bell.badge")
        }
    }

    private var permissionDeniedRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notifications are turned off")
                .font(.subheadline)
                .foregroundStyle(.primary)
            Text("Enable notifications for Berlin Transport Map in Settings to receive commute reminders.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption.bold())
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Alert list

    @ViewBuilder
    private var alertRows: some View {
        ForEach(alertManager.alerts) { alert in
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(alert.stopName)
                        .font(.subheadline)
                        .fontDesign(.rounded)
                    Text("Daily at \(alert.displayTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#00A550"))
            }
            .swipeActions {
                Button(role: .destructive) {
                    alertManager.removeAlert(alert)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }

        Button {
            showingAddAlert = true
        } label: {
            Label("Add Alert", systemImage: "plus")
        }
    }

    // MARK: - Data

    private func loadStops() {
        let service = FavoritesService(modelContext: modelContext, cityManager: services.cityManager)
        let all = (try? service.loadFavorites()) ?? []
        savedStops = all.filter { $0.type == .stop }
    }
}

// MARK: - Add alert sheet

private struct AddCommuteAlertSheet: View {
    let stops: [Favorite]
    let alertManager: CommuteAlertManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedStop: Favorite?
    @State private var alertTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Stop") {
                    if stops.isEmpty {
                        Text("No saved stops — add stops in My Stops first.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        Picker("Stop", selection: $selectedStop) {
                            Text("Select a stop").tag(Optional<Favorite>.none)
                            ForEach(stops) { stop in
                                Text(stop.name)
                                    .fontDesign(.rounded)
                                    .tag(Optional(stop))
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }

                Section("Time") {
                    DatePicker("Alert time", selection: $alertTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                }
            }
            .navigationTitle("Add Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let stop = selectedStop, let stopId = stop.stopId else { return }
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: alertTime)
                        // Use the favorite's own city, not the active city — picking a Berlin
                        // favorite while in Munich must save the alert with cityId="berlin",
                        // otherwise the notification opens Munich's API with a Berlin stopId.
                        let cityId = stop.effectiveCityId
                        Task {
                            await alertManager.addAlert(
                                stopId: stopId,
                                stopName: stop.name,
                                hour: comps.hour ?? 8,
                                minute: comps.minute ?? 0,
                                cityId: cityId
                            )
                        }
                        dismiss()
                    }
                    .disabled(selectedStop == nil || selectedStop?.stopId == nil)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
