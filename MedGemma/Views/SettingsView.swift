import SwiftUI

struct SettingsView: View {
    @AppStorage("showMedicalDisclaimer") private var showDisclaimer = true
    @AppStorage("enableHapticFeedback") private var enableHaptics = true
    @EnvironmentObject var modelManager: ModelManager
    
    var body: some View {
        NavigationView {
            Form {
                Section("Model") {
                    HStack {
                        Text("Model Status")
                        Spacer()
                        if modelManager.isModelLoaded {
                            Label("Loaded", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Label("Loading...", systemImage: "arrow.clockwise.circle")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Text("Model Version")
                        Spacer()
                        Text("MedGemma 4B")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Preferences") {
                    Toggle("Show Medical Disclaimer", isOn: $showDisclaimer)
                    Toggle("Haptic Feedback", isOn: $enableHaptics)
                }
                
                Section("Privacy") {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("All processing happens on-device")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Image(systemName: "icloud.slash.fill")
                            .foregroundColor(.blue)
                        Text("No data is sent to external servers")
                            .font(.subheadline)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
                
                Section {
                    Text("MedGemma AI is not a substitute for professional medical advice, diagnosis, or treatment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}