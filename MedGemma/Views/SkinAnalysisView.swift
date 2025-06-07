import SwiftUI
import PhotosUI
import SwiftData

struct SkinAnalysisView: View {
    @StateObject private var viewModel = SkinAnalysisViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingResults = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Skin Analysis")
                        .font(.title)
                        .bold()
                    
                    Text("Take or select a photo of your skin concern")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Selected Image Preview
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No image selected")
                                    .foregroundColor(.gray)
                            }
                        )
                        .padding()
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Take Photo Button
                    Button(action: { showingCamera = true }) {
                        Label("Take Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Select Photo Button
                    PhotosPicker(selection: $selectedPhoto,
                                matching: .images,
                                photoLibrary: .shared()) {
                        Label("Choose from Library", systemImage: "photo.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    
                    // Analyze Button
                    Button(action: analyzeImage) {
                        Label("Analyze Image", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.selectedImage != nil ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(viewModel.selectedImage == nil || viewModel.isAnalyzing)
                }
                .padding()
            }
            .navigationTitle("Skin Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $viewModel.selectedImage)
            }
            .sheet(isPresented: $showingResults) {
                if let analysis = viewModel.analysisResult {
                    AnalysisResultView(analysis: analysis, image: viewModel.selectedImage)
                }
            }
            .onChange(of: selectedPhoto) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                    }
                }
            }
            .overlay(
                Group {
                    if viewModel.isAnalyzing {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Analyzing image...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                    }
                }
            )
        }
        .onAppear {
            viewModel.setupModelContext(modelContext)
        }
    }
    
    private func analyzeImage() {
        Task {
            await viewModel.analyzeImage()
            if viewModel.analysisResult != nil {
                showingResults = true
            }
        }
    }
}

// Camera View for taking photos
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Analysis Result View
struct AnalysisResultView: View {
    let analysis: SkinAnalysisResult
    let image: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var showingChat = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Disclaimer
                    DisclaimerBanner()
                        .padding(.horizontal)
                    
                    // Analysis Results
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Analysis Results")
                            .font(.title2)
                            .bold()
                        
                        // Condition Assessment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Potential Conditions:")
                                .font(.headline)
                            
                            ForEach(analysis.conditions, id: \.name) { condition in
                                ConditionRow(condition: condition)
                            }
                        }
                        
                        // Recommendations
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommendations:")
                                .font(.headline)
                            
                            ForEach(analysis.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(recommendation)
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        // Urgency Level
                        HStack {
                            Text("Urgency:")
                                .font(.headline)
                            
                            Text(analysis.urgencyLevel.rawValue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(analysis.urgencyLevel.color.opacity(0.2))
                                .foregroundColor(analysis.urgencyLevel.color)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: { showingChat = true }) {
                            Label("Ask Follow-up Questions", systemImage: "bubble.left.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: saveToHistory) {
                            Label("Save to History", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingChat) {
            NavigationView {
                ChatView()
                    .onAppear {
                        // Pre-populate chat with analysis context
                    }
            }
        }
    }
    
    private func saveToHistory() {
        // Save analysis to history
        dismiss()
    }
}

struct ConditionRow: View {
    let condition: PotentialCondition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(condition.name)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text("\(Int(condition.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(condition.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: condition.confidence)
                .tint(confidenceColor(for: condition.confidence))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func confidenceColor(for confidence: Double) -> Color {
        switch confidence {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}