import SwiftUI

struct SymptomCheckerView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .padding()
                
                Text("Symptom Checker")
                    .font(.title)
                    .bold()
                
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                Text("This feature will help you understand your symptoms through a guided questionnaire.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Symptom Checker")
        }
    }
}