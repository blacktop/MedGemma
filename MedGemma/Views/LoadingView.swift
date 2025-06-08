import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var progress: Double = 0.0
    @EnvironmentObject var modelManager: ModelManager
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.pink.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Title
                VStack(spacing: 16) {
                    Text("MedGemma")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    
                    Text("AI-Powered Medical Assistant")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Loading Animation
                VStack(spacing: 32) {
                    // Medical cross with pulse animation
                    ZStack {
                        // Outer pulse ring
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseScale)
                            .opacity(2.0 - pulseScale)
                        
                        // Inner circle
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        // Medical cross icon
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(rotationAngle))
                    }
                    
                    // Progress indicator
                    VStack(spacing: 16) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 200)
                            .scaleEffect(y: 2)
                        
                        Text(loadingMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Medical disclaimer
                VStack(spacing: 8) {
                    Text("⚕️ For Educational Purposes Only")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Always consult healthcare professionals for medical advice")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimations()
            simulateLoadingProgress()
        }
    }
    
    private var loadingMessage: String {
        switch progress {
        case 0.0..<0.3:
            return "Initializing AI Model..."
        case 0.3..<0.6:
            return "Loading Medical Knowledge Base..."
        case 0.6..<0.9:
            return "Preparing Analysis Engine..."
        default:
            return modelManager.isModelLoaded ? "Ready!" : "Almost Ready..."
        }
    }
    
    private func startAnimations() {
        // Pulse animation
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.4
        }
        
        // Rotation animation
        withAnimation(
            Animation.linear(duration: 3.0)
                .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
    
    private func simulateLoadingProgress() {
        // Simulate loading progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.02
            } else {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    LoadingView()
        .environmentObject(ModelManager.shared)
}