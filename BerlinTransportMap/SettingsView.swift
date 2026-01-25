import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Dark Mode", isOn: $darkMode)
                } header: {
                    Text("Appearance")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}