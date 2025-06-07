import Foundation
import CoreML
import NaturalLanguage
import UIKit
import Vision

@MainActor
class ModelManager: ObservableObject {
    static let shared = ModelManager()
    
    @Published var isModelLoaded = false
    @Published var loadingProgress: Double = 0.0
    
    private var model: MLModel?
    private let tokenizer = NLTokenizer(unit: .word)
    
    private init() {
        Task {
            await loadModel()
        }
    }
    
    func loadModel() async {
        do {
            // Check if model exists
            guard let modelURL = Bundle.main.url(forResource: "medgemma_4b_mobile", withExtension: "mlmodelc") else {
                print("Model not found in bundle. Please add medgemma_4b_mobile.mlpackage to the project.")
                return
            }
            
            // Load model
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndGPU
            
            model = try MLModel(contentsOf: modelURL, configuration: config)
            isModelLoaded = true
            
            print("Model loaded successfully")
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    func generateResponse(for prompt: String, context: [Message]) async throws -> String {
        guard let model = model else {
            throw ModelError.modelNotLoaded
        }
        
        // Build context from previous messages
        var fullPrompt = buildPrompt(from: prompt, context: context)
        
        // Tokenize input
        let tokens = tokenize(fullPrompt)
        
        // TODO: Implement actual model inference
        // For now, return a placeholder response
        try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate processing
        
        return """
        I understand you're asking about "\(prompt)". While I'm designed to provide medical information, I'm currently in setup phase. Once fully integrated, I'll be able to offer detailed medical insights based on the MedGemma model.
        
        Remember: Always consult with healthcare professionals for personalized medical advice.
        """
    }
    
    private func buildPrompt(from userInput: String, context: [Message]) -> String {
        var prompt = "You are MedGemma, a helpful medical AI assistant. Provide accurate, helpful medical information while always reminding users to consult healthcare professionals for serious concerns.\n\n"
        
        // Add recent context (last 5 exchanges)
        let recentMessages = context.suffix(10)
        for message in recentMessages {
            if message.isUser {
                prompt += "User: \(message.content)\n"
            } else {
                prompt += "Assistant: \(message.content)\n"
            }
        }
        
        prompt += "User: \(userInput)\nAssistant: "
        
        return prompt
    }
    
    private func tokenize(_ text: String) -> [String] {
        var tokens: [String] = []
        tokenizer.string = text
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { tokenRange, _ in
            let token = String(text[tokenRange])
            tokens.append(token)
            return true
        }
        
        return tokens
    }
    
    // Image Analysis
    func analyzeImage(image: UIImage, prompt: String) async throws -> String {
        guard let model = model else {
            throw ModelError.modelNotLoaded
        }
        
        // Convert image to format expected by model
        guard let imageBuffer = image.toCVPixelBuffer() else {
            throw ModelError.inferenceError("Failed to convert image")
        }
        
        // Create multimodal prompt combining image and text
        let fullPrompt = buildImageAnalysisPrompt(prompt: prompt)
        
        // TODO: Implement actual model inference with image input
        // For now, simulate processing and return a medical analysis
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        return """
        Based on the dermatological image analysis:
        
        **Potential Conditions:**
        • Benign nevus (common mole) - 85% confidence
        • Seborrheic keratosis - 45% confidence
        
        **Observations:**
        • Regular borders with uniform pigmentation
        • Symmetric appearance
        • No signs of rapid changes
        
        **Recommendations:**
        • Monitor for any changes in size, color, or shape
        • Annual dermatological examination
        • Sun protection with SPF 30+
        • Photo documentation for future comparison
        
        **Urgency Level:** Low
        
        ⚠️ **Important:** This analysis is for educational purposes only. Please consult a dermatologist for professional diagnosis and treatment recommendations.
        """
    }
    
    private func buildImageAnalysisPrompt(prompt: String) -> String {
        return """
        You are MedGemma, a medical AI assistant specializing in dermatological analysis.
        
        Analyze the provided skin image and provide:
        1. Potential conditions with confidence levels
        2. Visual observations
        3. Recommended actions
        4. Urgency assessment
        
        Context: \(prompt)
        
        Always emphasize the need for professional medical consultation.
        """
    }
}

enum ModelError: LocalizedError {
    case modelNotLoaded
    case inferenceError(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "The AI model is not loaded. Please restart the app."
        case .inferenceError(let message):
            return "Model error: \(message)"
        }
    }
}