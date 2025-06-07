import SwiftUI

struct MedicalReferenceView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                
                Text("Medical Reference")
                    .font(.title)
                    .bold()
                
                Text("Coming Soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                Text("Quick access to medical terms, conditions, and treatments.")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Medical Reference")
        }
    }
}