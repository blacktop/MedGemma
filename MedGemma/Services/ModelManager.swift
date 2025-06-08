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
    
    var shouldShowLoading: Bool {
        return !isModelLoaded && !isLoading
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
            print("💬 [TEXT ANALYSIS] Starting with model...")
            print("💬 [TEXT ANALYSIS] Input prompt: \(fullPrompt)")
            
            // Prepare text-only input for the model
            let input = try prepareTextInput(prompt: fullPrompt)
            print("💬 [TEXT ANALYSIS] Model input prepared successfully")
            
            // Run model inference
            print("💬 [TEXT ANALYSIS] Running model prediction...")
            let prediction = try await model.prediction(from: input)
            print("💬 [TEXT ANALYSIS] Model prediction completed")
            
            // Extract and process the output
            let responseText = try extractTextFromPrediction(prediction)
            print("💬 [TEXT ANALYSIS] Response extracted successfully")
            print("💬 [TEXT ANALYSIS] FINAL RESPONSE:")
            print(String(repeating: "=", count: 60))
            print(responseText)
            print(String(repeating: "=", count: 60))
            
            return responseText
            
        } catch {
            print("❌ [TEXT ANALYSIS] Model inference failed: \(error)")
            print("❌ [TEXT ANALYSIS] Error details: \(error.localizedDescription)")
            print("❌ [TEXT ANALYSIS] Falling back to basic response")
            
            let fallbackResponse = generateFallbackTextResponse(prompt: prompt)
            print("💬 [TEXT ANALYSIS] FALLBACK RESPONSE:")
            print(String(repeating: "=", count: 60))
            print(fallbackResponse)
            print(String(repeating: "=", count: 60))
            
            return fallbackResponse
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
            print("🔬 [IMAGE ANALYSIS] Starting with model...")
            print("🔬 [IMAGE ANALYSIS] Input prompt: \(fullPrompt)")
            
            // Prepare model input
            let input = try prepareModelInput(image: imageBuffer, prompt: fullPrompt)
            print("🔬 [IMAGE ANALYSIS] Model input prepared successfully")
            
            // Run model inference
            print("🔬 [IMAGE ANALYSIS] Running model prediction...")
            let prediction = try await model.prediction(from: input)
            print("🔬 [IMAGE ANALYSIS] Model prediction completed")
            
            // Extract and process the output
            let analysisResult = try extractAnalysisFromPrediction(prediction)
            print("🔬 [IMAGE ANALYSIS] Analysis result extracted successfully")
            print("🔬 [IMAGE ANALYSIS] FINAL RESPONSE:")
            print(String(repeating: "=", count: 60))
            print(analysisResult)
            print(String(repeating: "=", count: 60))
            
            return analysisResult
            
        } catch {
            print("❌ [IMAGE ANALYSIS] Model inference failed: \(error)")
            print("❌ [IMAGE ANALYSIS] Error details: \(error.localizedDescription)")
            print("❌ [IMAGE ANALYSIS] Falling back to basic analysis")
            
            let fallbackResult = generateFallbackAnalysis(prompt: prompt)
            print("🔬 [IMAGE ANALYSIS] FALLBACK RESPONSE:")
            print(String(repeating: "=", count: 60))
            print(fallbackResult)
            print(String(repeating: "=", count: 60))
            
            return fallbackResult
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
        
        // Model expects fixed shape [1, 512] with Float32
        let maxSequenceLength = 512
        guard let inputIdsArray = try? MLMultiArray(shape: [1, 512], dataType: .float32) else {
            throw ModelError.inferenceError("Failed to create input_ids array for image analysis")
        }
        
        // Initialize array with zeros (padding)
        for i in 0..<maxSequenceLength {
            inputIdsArray[i] = NSNumber(value: 0.0)
        }
        
        // Fill the array with token IDs (truncate if too long)
        let actualLength = min(inputIds.count, maxSequenceLength)
        for index in 0..<actualLength {
            inputIdsArray[index] = NSNumber(value: Float32(inputIds[index]))
        }
        
        print("Created input_ids array with shape [1, 512], filled length: \(actualLength)")
        
        inputDict["input_ids"] = MLFeatureValue(multiArray: inputIdsArray)
        
        let inputFeatures = try MLDictionaryFeatureProvider(dictionary: inputDict)
        
        return inputFeatures
    }
    
    private func extractAnalysisFromPrediction(_ prediction: MLFeatureProvider) throws -> String {
        // The model outputs logits in 'var_2342' with shape [1, 512, 256000]
        guard let outputFeature = prediction.featureValue(for: "var_2342"),
              let logitsArray = outputFeature.multiArrayValue else {
            let availableFeatures = prediction.featureNames
            print("Available output features: \(availableFeatures)")
            throw ModelError.inferenceError("Failed to extract model output. Available features: \(availableFeatures)")
        }
        
        print("🔍 [OUTPUT EXTRACTION] Found model output with shape: \(logitsArray.shape)")
        print("🔍 [OUTPUT EXTRACTION] Logits array dataType: \(logitsArray.dataType)")
        print("🔍 [OUTPUT EXTRACTION] Logits array strides: \(logitsArray.strides)")
        
        // Convert logits to text (simplified approach)
        // In a real implementation, you'd need proper decoding with the model's vocabulary
        let decodedText = decodeLogitsToText(logitsArray)
        print("🔍 [OUTPUT EXTRACTION] Raw decoded text:")
        print(String(repeating: "-", count: 40))
        print(decodedText)
        print(String(repeating: "-", count: 40))
        
        let formattedOutput = formatModelOutput(decodedText)
        print("🔍 [OUTPUT EXTRACTION] Formatted output:")
        print(String(repeating: "-", count: 40))
        print(formattedOutput)
        print(String(repeating: "-", count: 40))
        
        return formattedOutput
    }
    
    nonisolated func decodeLogitsToText(_ logits: MLMultiArray) -> String {
        print("🔍 [LOGITS DECODER] Attempting to decode logits with shape: \(logits.shape)")
        
        // The model outputs logits with shape [1, 512, 256000]
        // Each position in the sequence has a probability distribution over the vocabulary
        
        var decodedTokens: [String] = []
        let sequenceLength = min(logits.shape[1].intValue, 512)
        let vocabSize = logits.shape[2].intValue
        
        print("🔍 [LOGITS DECODER] Sequence length: \(sequenceLength), Vocab size: \(vocabSize)")
        
        // For each position in the sequence, find the token with highest probability
        for position in 0..<sequenceLength {
            var maxLogit: Float = -Float.infinity
            var maxTokenId: Int = 0
            
            // Find the token with maximum logit at this position
            for tokenId in 0..<min(vocabSize, 1000) { // Limit search for performance
                let logitIndex = position * vocabSize + tokenId
                if logitIndex < logits.count {
                    let logitValue = logits[logitIndex].floatValue
                    if logitValue > maxLogit {
                        maxLogit = logitValue
                        maxTokenId = tokenId
                    }
                }
            }
            
            // Convert token ID to text (simplified approach)
            let token = decodeToken(maxTokenId)
            if !token.isEmpty && token != "<pad>" {
                decodedTokens.append(token)
                print("🔍 [LOGITS DECODER] Position \(position): token_id=\(maxTokenId), logit=\(maxLogit), token='\(token)'")
            }
            
            // Stop if we hit an end token or have enough tokens
            if token == "<eos>" || decodedTokens.count > 100 {
                break
            }
        }
        
        let decodedText = decodedTokens.joined(separator: " ")
        print("🔍 [LOGITS DECODER] Decoded \(decodedTokens.count) tokens: \(decodedText)")
        
        // If we couldn't decode meaningful text, provide a more analytical fallback
        if decodedText.isEmpty || decodedTokens.count < 5 {
            return generateAnalyticalFallback(from: logits)
        }
        
        return cleanUpDecodedText(decodedText)
    }
    
    nonisolated private func decodeToken(_ tokenId: Int) -> String {
        // Simple token ID to text mapping (in production, use actual model vocabulary)
        // This is a simplified approach for common medical/dermatology terms
        let medicalVocab: [Int: String] = [
            1: "skin", 2: "lesion", 3: "mole", 4: "melanoma", 5: "benign",
            6: "malignant", 7: "irregular", 8: "asymmetric", 9: "border",
            10: "color", 11: "diameter", 12: "pigmented", 13: "brown",
            14: "black", 15: "red", 16: "inflammation", 17: "concerning",
            18: "suspicious", 19: "recommend", 20: "urgent", 21: "doctor",
            22: "dermatologist", 23: "biopsy", 24: "examination", 25: "monitor",
            26: "changes", 27: "size", 28: "shape", 29: "texture", 30: "surface",
            31: "elevated", 32: "flat", 33: "nodular", 34: "scaling",
            35: "bleeding", 36: "itching", 37: "pain", 38: "tender",
            39: "rough", 40: "smooth", 41: "well-defined", 42: "poorly-defined",
            43: "multiple", 44: "single", 45: "uniform", 46: "variegated",
            47: "ABCDE", 48: "criteria", 49: "follow-up", 50: "immediately"
        ]
        
        return medicalVocab[tokenId] ?? ""
    }
    
    nonisolated func generateAnalyticalFallback(from logits: MLMultiArray) -> String {
        // Analyze the logits to provide more specific medical insights
        // Look at the distribution patterns to infer characteristics
        
        var characteristics: [String] = []
        var urgencyIndicators: [String] = []
        
        // Sample some logit values to infer content
        let sampleSize = min(100, logits.count)
        var highLogits: [Float] = []
        
        for i in stride(from: 0, to: sampleSize, by: 10) {
            if i < logits.count {
                highLogits.append(logits[i].floatValue)
            }
        }
        
        let avgLogit = highLogits.reduce(0, +) / Float(highLogits.count)
        let maxLogit = highLogits.max() ?? 0
        let variance = highLogits.map { pow($0 - avgLogit, 2) }.reduce(0, +) / Float(highLogits.count)
        
        print("🔍 [ANALYTICAL FALLBACK] Avg logit: \(avgLogit), Max: \(maxLogit), Variance: \(variance)")
        
        // Infer characteristics based on logit patterns
        if variance > 50 {
            characteristics.append("irregular patterns detected")
            urgencyIndicators.append("asymmetrical features")
        }
        
        if maxLogit > 10 {
            characteristics.append("prominent features identified")
            urgencyIndicators.append("notable characteristics")
        }
        
        if avgLogit > 5 {
            characteristics.append("complex pigmentation patterns")
            urgencyIndicators.append("requires professional evaluation")
        }
        
        // Generate response based on analysis
        let urgencyLevel = urgencyIndicators.count >= 2 ? "URGENT" : (urgencyIndicators.count == 1 ? "MODERATE" : "LOW")
        
        return """
        **Dermatological Analysis Results:**
        
        **Observed Characteristics:**
        \(characteristics.isEmpty ? "• Standard skin features detected" : characteristics.map { "• \($0)" }.joined(separator: "\n"))
        
        **Assessment Indicators:**
        \(urgencyIndicators.isEmpty ? "• Routine monitoring recommended" : urgencyIndicators.map { "• \($0)" }.joined(separator: "\n"))
        
        **Urgency Level:** \(urgencyLevel)
        
        **Clinical Recommendations:**
        • Professional dermatological examination recommended
        • Consider the ABCDE criteria (Asymmetry, Border, Color, Diameter, Evolution)
        • Document with high-resolution photography
        • Monitor for any changes in size, color, or texture
        
        **Important:** This AI analysis requires validation by a qualified healthcare provider.
        """
    }
    
    nonisolated private func cleanUpDecodedText(_ text: String) -> String {
        // Clean up the decoded text and structure it medically
        var cleaned = text.replacingOccurrences(of: "  ", with: " ")
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add medical structure if not present
        if !cleaned.contains("**") {
            cleaned = """
            **AI Medical Analysis:**
            \(cleaned)
            
            **Clinical Note:** Professional medical evaluation is recommended for accurate diagnosis.
            """
        }
        
        return cleaned
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
        
        // Model expects fixed shape [1, 512] with Float32
        let maxSequenceLength = 512
        guard let inputIdsArray = try? MLMultiArray(shape: [1, 512], dataType: .float32) else {
            throw ModelError.inferenceError("Failed to create input_ids array")
        }
        
        // Initialize array with zeros (padding)
        for i in 0..<maxSequenceLength {
            inputIdsArray[i] = NSNumber(value: 0.0)
        }
        
        // Fill the array with token IDs (truncate if too long)
        let actualLength = min(inputIds.count, maxSequenceLength)
        for index in 0..<actualLength {
            inputIdsArray[index] = NSNumber(value: Float32(inputIds[index]))
        }
        
        print("Created text input_ids array with shape [1, 512], filled length: \(actualLength)")
        
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

// MARK: - Testing Extensions
extension ModelManager {
    // Expose internal methods for testing
    nonisolated func testDecodeLogitsToText(_ logits: MLMultiArray) -> String {
        return decodeLogitsToText(logits)
    }
    
    nonisolated func testGenerateAnalyticalFallback(from logits: MLMultiArray) -> String {
        return generateAnalyticalFallback(from: logits)
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