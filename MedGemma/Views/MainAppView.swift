import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var modelManager: ModelManager
    @State private var showLoading = true
    @State private var minimumLoadingTime = false
    
    var body: some View {
        ZStack {
            if showLoading {
                LoadingView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            startLoadingSequence()
        }
        .onChange(of: modelManager.isModelLoaded) { _, isLoaded in
            if isLoaded && minimumLoadingTime {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showLoading = false
                }
            }
        }
    }
    
    private func startLoadingSequence() {
        // Ensure minimum loading time for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            minimumLoadingTime = true
            
            // If model is already loaded, transition immediately
            if modelManager.isModelLoaded {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showLoading = false
                }
            }
        }
        
        // Start model loading in background
        Task {
            await modelManager.loadModel()
        }
    }
}

#Preview {
    MainAppView()
        .environmentObject(ModelManager.shared)
}