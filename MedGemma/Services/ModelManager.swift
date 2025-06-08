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
    private var isLoading = false
    
    private init() {
        // Don't auto-load model to prevent memory issues
        // Load only when needed
    }
    
    func loadModel() async {
        // Prevent multiple simultaneous loads
        guard !isLoading && !isModelLoaded else { return }
        
        isLoading = true
        
        do {
            // Check for different possible model file names/extensions
            var modelURL: URL?
            
            // Try .mlmodelc first (compiled model)
            modelURL = Bundle.main.url(forResource: "medgemma_4b_mobile", withExtension: "mlmodelc")
            
            // Try .mlpackage (package format)
            if modelURL == nil {
                modelURL = Bundle.main.url(forResource: "medgemma_4b_mobile", withExtension: "mlpackage")
            }
            
            // Try without extension
            if modelURL == nil {
                modelURL = Bundle.main.url(forResource: "medgemma_4b_mobile", withExtension: nil)
            }
            
            guard let finalModelURL = modelURL else {
                print("Model not found in bundle. Please add medgemma_4b_mobile model file to the project.")
                print("Checked for: medgemma_4b_mobile.mlmodelc, medgemma_4b_mobile.mlpackage")
                isLoading = false
                return
            }
            
            print("Found model at: \(finalModelURL)")
            
            // Configure model for memory efficiency
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly // Use CPU only to reduce memory pressure
            config.allowLowPrecisionAccumulationOnGPU = true
            
            // Load model with memory optimization
            model = try MLModel(contentsOf: finalModelURL, configuration: config)
            isModelLoaded = true
            
            print("Model loaded successfully with memory optimizations")
            
            // Print model information for debugging
            if let modelDescription = model?.modelDescription {
                print("Model description: \(modelDescription)")
                print("Input features: \(modelDescription.inputDescriptionsByName.keys)")
                print("Output features: \(modelDescription.outputDescriptionsByName.keys)")
                
                // Print detailed input requirements
                for (name, description) in modelDescription.inputDescriptionsByName {
                    print("Input '\(name)': \(description)")
                }
                for (name, description) in modelDescription.outputDescriptionsByName {
                    print("Output '\(name)': \(description)")
                }
            }
        } catch {
            print("Failed to load model: \(error)")
            // Clear any partial state
            model = nil
        }
        
        isLoading = false
    }
    
    func unloadModel() {
        model = nil
        isModelLoaded = false
        print("Model unloaded to free memory")
    }
    
    func generateResponse(for prompt: String, context: [Message]) async throws -> String {
        // Lazy load model only when needed
        if !isModelLoaded {
            await loadModel()
        }
        
        guard let model = model else {
            throw ModelError.modelNotLoaded
        }
        
        // Build context from previous messages
        var fullPrompt = buildPrompt(from: prompt, context: context)
        
        do {
            // Prepare text-only input for the model
            let input = try prepareTextInput(prompt: fullPrompt)
            
            // Run model inference
            let prediction = try await model.prediction(from: input)
            
            // Extract and process the output
            let responseText = try extractTextFromPrediction(prediction)
            
            return responseText
            
        } catch {
            print("Text model inference failed: \(error)")
            // Fallback response if model fails
            return generateFallbackTextResponse(prompt: prompt)
        }
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
        
        // Add special tokens that language models typically expect
        return ["<bos>"] + tokens + ["<eos>"]
    }
    
    private func tokenToId(_ token: String) -> Int32 {
        // Simple hash-based token ID generation (not ideal but works for testing)
        // In production, you'd use the actual model's vocabulary
        return Int32(abs(token.hashValue) % 32000) // Limit to reasonable vocab size
    }
    
    // Image Analysis
    func analyzeImage(image: UIImage, prompt: String) async throws -> String {
        // Lazy load model only when needed
        if !isModelLoaded {
            await loadModel()
        }
        
        guard let model = model else {
            throw ModelError.modelNotLoaded
        }
        
        // Convert image to format expected by model
        guard let imageBuffer = image.toCVPixelBuffer() else {
            throw ModelError.inferenceError("Failed to convert image")
        }
        
        // Create multimodal prompt combining image and text
        let fullPrompt = buildImageAnalysisPrompt(prompt: prompt)
        
        do {
            print("Starting image analysis with model...")
            
            // Prepare model input
            let input = try prepareModelInput(image: imageBuffer, prompt: fullPrompt)
            print("Model input prepared successfully")
            
            // Run model inference
            print("Running model prediction...")
            let prediction = try await model.prediction(from: input)
            print("Model prediction completed")
            
            // Extract and process the output
            let analysisResult = try extractAnalysisFromPrediction(prediction)
            print("Analysis result extracted successfully")
            
            return analysisResult
            
        } catch {
            print("Model inference failed: \(error)")
            print("Error details: \(error.localizedDescription)")
            // Fallback to basic analysis if model fails
            return generateFallbackAnalysis(prompt: prompt)
        }
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
    
    // MARK: - Model Input/Output Processing
    
    private func prepareModelInput(image: CVPixelBuffer, prompt: String) throws -> MLFeatureProvider {
        // For multimodal models, we likely need both pixel_values and input_ids
        var inputDict: [String: MLFeatureValue] = [:]
        
        // Add image input
        inputDict["pixel_values"] = MLFeatureValue(pixelBuffer: image)
        
        // Tokenize the text prompt
        let tokens = tokenize(prompt)
        let inputIds = tokens.map { tokenToId($0) }
        
        // Create the MLMultiArray for input_ids
        guard let inputIdsArray = try? MLMultiArray(shape: [1, NSNumber(value: inputIds.count)], dataType: .int32) else {
            throw ModelError.inferenceError("Failed to create input_ids array for image analysis")
        }
        
        // Fill the array with token IDs
        for (index, tokenId) in inputIds.enumerated() {
            inputIdsArray[index] = NSNumber(value: tokenId)
        }
        
        inputDict["input_ids"] = MLFeatureValue(multiArray: inputIdsArray)
        
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: inputDict)
        
        return inputFeatures
    }
    
    private func extractAnalysisFromPrediction(_ prediction: MLFeatureProvider) throws -> String {
        // Try different output feature names
        let possibleOutputNames = ["output", "text_output", "generated_text", "response", "result"]
        
        for outputName in possibleOutputNames {
            if let outputFeature = prediction.featureValue(for: outputName) {
                // Handle different types of outputs
                if outputFeature.type == .string {
                    let outputText = outputFeature.stringValue
                    print("Found output in feature: \(outputName)")
                    return formatModelOutput(outputText)
                }
            }
        }
        
        // If we can't find text output, list available features for debugging
        let availableFeatures = prediction.featureNames
        print("Available output features: \(availableFeatures)")
        
        throw ModelError.inferenceError("Failed to extract model output. Available features: \(availableFeatures)")
    }
    
    private func formatModelOutput(_ rawOutput: String) -> String {
        // Clean up and structure the model's raw output
        var formattedOutput = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add safety disclaimer if not present
        if !formattedOutput.lowercased().contains("consult") && !formattedOutput.lowercased().contains("professional") {
            formattedOutput += "\n\n⚠️ **Important:** This analysis is for educational purposes only. Please consult a dermatologist for professional diagnosis and treatment recommendations."
        }
        
        return formattedOutput
    }
    
    private func generateFallbackAnalysis(prompt: String) -> String {
        return """
        **Image Analysis Status:** Model temporarily unavailable
        
        I can see you've uploaded an image for dermatological analysis. While the AI model is currently unavailable, here are some general recommendations:
        
        **General Skin Health Guidelines:**
        • Monitor any changes in size, color, shape, or texture
        • Use broad-spectrum sunscreen daily (SPF 30+)
        • Perform regular self-examinations
        • Schedule annual skin checks with a dermatologist
        • Take photos for comparison over time
        
        **When to Seek Immediate Care:**
        • Rapid changes in moles or spots
        • Bleeding, itching, or pain
        • Asymmetrical growths
        • Irregular borders or colors
        
        ⚠️ **Important:** This is not a substitute for professional medical evaluation. Please consult a dermatologist for proper diagnosis and treatment recommendations.
        """
    }
    
    private func prepareTextInput(prompt: String) throws -> MLFeatureProvider {
        // Tokenize the input text
        let tokens = tokenize(prompt)
        
        // Convert tokens to input_ids (integers)
        let inputIds = tokens.map { tokenToId($0) }
        
        // Create the MLMultiArray for input_ids
        guard let inputIdsArray = try? MLMultiArray(shape: [1, NSNumber(value: inputIds.count)], dataType: .int32) else {
            throw ModelError.inferenceError("Failed to create input_ids array")
        }
        
        // Fill the array with token IDs
        for (index, tokenId) in inputIds.enumerated() {
            inputIdsArray[index] = NSNumber(value: tokenId)
        }
        
        // Create input features
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: [
            "input_ids": MLFeatureValue(multiArray: inputIdsArray)
        ])
        
        return inputFeatures
    }
    
    private func extractTextFromPrediction(_ prediction: MLFeatureProvider) throws -> String {
        // Use the same robust extraction as image analysis
        return try extractAnalysisFromPrediction(prediction)
    }
    
    private func generateFallbackTextResponse(prompt: String) -> String {
        return """
        I'm MedGemma, your medical AI assistant. While the model is currently unavailable, I can provide some general guidance.
        
        For your question about "\(prompt)", I recommend:
        • Consulting with a healthcare professional for personalized advice
        • Seeking immediate care if symptoms are severe or worsening
        • Keeping track of any changes in your condition
        
        **Common Medical Resources:**
        • Primary care physician
        • Urgent care for non-emergency concerns
        • Emergency services for serious symptoms
        • Telehealth consultations when appropriate
        
        ⚠️ **Important:** This is not a substitute for professional medical advice. Always consult healthcare providers for proper diagnosis and treatment.
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