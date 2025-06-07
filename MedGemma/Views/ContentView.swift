import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(0)
            
            SkinAnalysisView()
                .tabItem {
                    Label("Skin Analysis", systemImage: "camera.viewfinder")
                }
                .tag(1)
            
            SymptomCheckerView()
                .tabItem {
                    Label("Symptoms", systemImage: "heart.text.square.fill")
                }
                .tag(2)
            
            MedicalReferenceView()
                .tabItem {
                    Label("Reference", systemImage: "book.fill")
                }
                .tag(3)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(4)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
        }
    }
}