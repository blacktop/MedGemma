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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    // Unload model when app goes to background to free memory
                    modelManager.unloadModel()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    // Handle memory warnings
                    handleMemoryWarning()
                }
        }
    }
    
    private func showDisclaimerIfNeeded() {
        let hasShownDisclaimer = UserDefaults.standard.bool(forKey: "HasShownMedicalDisclaimer")
        if !hasShownDisclaimer {
            // Will be implemented with disclaimer view
        }
    }
    
    private func handleMemoryWarning() {
        print("Memory warning received - unloading AI model")
        modelManager.unloadModel()
        
        // Force garbage collection
        DispatchQueue.global(qos: .background).async {
            // Clear any cached data
            URLCache.shared.removeAllCachedResponses()
        }
    }
}