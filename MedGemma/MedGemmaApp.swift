import SwiftUI
import SwiftData

@main
struct MedGemmaApp: App {
    @StateObject private var modelManager = ModelManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
            Conversation.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .environmentObject(modelManager)
                .onAppear {
                    showDisclaimerIfNeeded()
                }
        }
    }
    
    private func showDisclaimerIfNeeded() {
        let hasShownDisclaimer = UserDefaults.standard.bool(forKey: "HasShownMedicalDisclaimer")
        if !hasShownDisclaimer {
            // Will be implemented with disclaimer view
        }
    }
}