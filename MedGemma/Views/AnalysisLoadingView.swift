import SwiftUI

struct AnalysisLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Loading card
            VStack(spacing: 20) {
                // Animated medical icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .scaleEffect(scale)
                    
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(rotationAngle))
                }
                
                VStack(spacing: 8) {
                    Text("Analyzing Image")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("AI is examining your photo...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                ProgressView()
                    .scaleEffect(1.2)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Rotation animation
        withAnimation(
            Animation.linear(duration: 2.0)
                .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
        
        // Scale animation
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            scale = 1.2
        }
    }
}

#Preview {
    AnalysisLoadingView()
}