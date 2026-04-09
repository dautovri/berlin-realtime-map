import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Follow System", isOn: $useSystemTheme)
                    Toggle("Dark Mode", isOn: $darkMode)
                        .disabled(useSystemTheme)
                } header: {
                    Text("Appearance")
                }
            }
            .navigationTitle("Settings")
            #if !os(tvOS)
.navigationBarTitleDisplayMode(.inline)
#endif
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