import Foundation
import UIKit
import CoreML
import Vision
import SwiftData
import SwiftUI

// Analysis Result Models
struct SkinAnalysisResult {
    let conditions: [PotentialCondition]
    let recommendations: [String]
    let urgencyLevel: UrgencyLevel
    let confidence: Double
    let timestamp: Date
}

struct PotentialCondition {
    let name: String
    let description: String
    let confidence: Double
}

enum UrgencyLevel: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

@MainActor
class SkinAnalysisViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isAnalyzing = false
    @Published var analysisResult: SkinAnalysisResult?
    @Published var errorMessage: String?
    
    private let modelManager = ModelManager.shared
    private var modelContext: ModelContext?
    
    func setupModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func analyzeImage() async {
        guard let image = selectedImage else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        do {
            // Prepare image for analysis with memory management
            let preprocessedImage = preprocessImage(image)
            
            // Generate prompt for the model
            let prompt = generateAnalysisPrompt()
            
            // Get analysis from model
            let response = try await modelManager.analyzeImage(
                image: preprocessedImage,
                prompt: prompt
            )
            
            // Parse the response into structured result
            print("📱 [VIEWMODEL] Model response received:")
            print(String(repeating: "=", count: 50))
            print(response)
            print(String(repeating: "=", count: 50))
            
            analysisResult = parseAnalysisResponse(response)
            
            print("📱 [VIEWMODEL] Parsed analysis result:")
            if let result = analysisResult {
                print("   Conditions: \(result.conditions.count)")
                for condition in result.conditions {
                    print("   - \(condition.name): \(condition.confidence)")
                }
                print("   Recommendations: \(result.recommendations.count)")
                for rec in result.recommendations {
                    print("   - \(rec)")
                }
                print("   Urgency: \(result.urgencyLevel.rawValue)")
                print("   Confidence: \(result.confidence)")
            }
            
            // Save to history
            await saveAnalysisToHistory()
            
            // Clear processed image from memory
            selectedImage = nil
            
        } catch {
            errorMessage = "Failed to analyze image: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
    
    private func preprocessImage(_ image: UIImage) -> UIImage {
        // Resize image to smaller size to reduce memory usage
        let targetSize = CGSize(width: 224, height: 224) // Reduced from 512x512
        
        // Use memory-efficient image resizing
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return resizedImage
    }
    
    private func generateAnalysisPrompt() -> String {
        """
        Analyze this dermatological image and provide:
        1. List of potential skin conditions (with confidence levels)
        2. Brief description of each condition
        3. Recommended actions for the patient
        4. Urgency level (Low/Medium/High/Urgent)
        
        Focus on common conditions like:
        - Acne
        - Eczema
        - Psoriasis
        - Melanoma
        - Basal cell carcinoma
        - Benign moles
        - Rashes
        - Allergic reactions
        
        Important: This is for educational purposes only. Always recommend consulting a healthcare professional.
        """
    }
    
    private func parseAnalysisResponse(_ response: String) -> SkinAnalysisResult {
        // Parse the actual model response instead of returning hardcoded results
        print("🧠 [PARSER] Starting to parse model response...")
        print("🧠 [PARSER] Response length: \(response.count) characters")
        print("🧠 [PARSER] Response preview: \(String(response.prefix(100)))...")
        
        // Extract conditions from the response
        var conditions: [PotentialCondition] = []
        var recommendations: [String] = []
        var urgencyLevel: UrgencyLevel = .low
        var confidence: Double = 0.8
        
        // Parse response text for medical insights
        let lowercaseResponse = response.lowercased()
        
        // Extract potential conditions based on medical keywords
        
        // HIGH PRIORITY: Melanoma and malignant indicators
        if lowercaseResponse.contains("melanoma") || lowercaseResponse.contains("malignant") {
            conditions.append(PotentialCondition(
                name: "Possible Melanoma",
                description: "Suspicious pigmented lesion with concerning features",
                confidence: 0.9
            ))
            urgencyLevel = .urgent
        }
        
        // HIGH PRIORITY: ABCDE criteria and concerning features
        if lowercaseResponse.contains("asymmet") || lowercaseResponse.contains("irregular") || 
           lowercaseResponse.contains("variegated") || lowercaseResponse.contains("suspicious") {
            conditions.append(PotentialCondition(
                name: "Irregular/Asymmetric Features",
                description: "Lesion shows asymmetrical or irregular characteristics requiring evaluation",
                confidence: 0.85
            ))
            if urgencyLevel.rawValue == "Low" { urgencyLevel = .high }
        }
        
        // MEDIUM PRIORITY: Concerning patterns
        if lowercaseResponse.contains("concerning") || lowercaseResponse.contains("notable") ||
           lowercaseResponse.contains("prominent") || lowercaseResponse.contains("complex") {
            conditions.append(PotentialCondition(
                name: "Concerning Features",
                description: "Notable characteristics detected that warrant professional review",
                confidence: 0.75
            ))
            if urgencyLevel.rawValue == "Low" { urgencyLevel = .medium }
        }
        
        // STANDARD: Basic mole/nevus
        if lowercaseResponse.contains("mole") || lowercaseResponse.contains("nevus") {
            if !conditions.contains(where: { $0.name.contains("Melanoma") || $0.name.contains("Irregular") }) {
                conditions.append(PotentialCondition(
                    name: "Pigmented Lesion/Mole",
                    description: "Pigmented skin lesion requiring monitoring",
                    confidence: 0.7
                ))
            }
        }
        
        // Inflammatory conditions
        if lowercaseResponse.contains("inflammation") || lowercaseResponse.contains("red") {
            conditions.append(PotentialCondition(
                name: "Inflammatory Changes",
                description: "Signs of skin inflammation detected",
                confidence: 0.6
            ))
        }
        
        // Emergency indicators
        if lowercaseResponse.contains("urgent") || lowercaseResponse.contains("immediate") ||
           lowercaseResponse.contains("emergency") {
            urgencyLevel = .urgent
        }
        
        // If no specific conditions detected, create a general assessment
        if conditions.isEmpty {
            conditions.append(PotentialCondition(
                name: "General Assessment",
                description: "AI analysis completed - requires professional interpretation",
                confidence: 0.75
            ))
        }
        
        // Generate recommendations based on urgency level and detected conditions
        switch urgencyLevel {
        case .urgent:
            recommendations = [
                "⚠️ URGENT: Seek immediate dermatological evaluation",
                "Schedule appointment within 24-48 hours",
                "Consider emergency consultation if rapid changes observed",
                "Document lesion with high-resolution photos",
                "Avoid sun exposure to the area"
            ]
        case .high:
            recommendations = [
                "Schedule dermatological consultation within 1-2 weeks",
                "Monitor closely for any changes in size, color, or shape",
                "Apply ABCDE criteria (Asymmetry, Border, Color, Diameter, Evolution)",
                "Document with photos for comparison",
                "Use broad-spectrum sunscreen SPF 30+"
            ]
        case .medium:
            recommendations = [
                "Consider dermatological evaluation within 1 month",
                "Monitor for changes and document with photos",
                "Apply sun protection measures",
                "Track any evolution in appearance",
                "Follow up if concerned about changes"
            ]
        case .low:
            recommendations = [
                "Routine skin monitoring recommended",
                "Annual dermatological check-up",
                "Use sun protection (SPF 30+) daily",
                "Self-examine monthly for changes",
                "Document with photos for future comparison"
            ]
        }
        
        // Add specific recommendations based on detected features
        if lowercaseResponse.contains("biopsy") || lowercaseResponse.contains("melanoma") {
            recommendations.insert("Discuss biopsy options with dermatologist", at: 1)
        }
        
        if lowercaseResponse.contains("irregular") || lowercaseResponse.contains("asymmet") {
            recommendations.append("Pay special attention to border irregularities")
        }
        
        let result = SkinAnalysisResult(
            conditions: conditions,
            recommendations: recommendations,
            urgencyLevel: urgencyLevel,
            confidence: confidence,
            timestamp: Date()
        )
        
        print("🧠 [PARSER] Parsing completed successfully:")
        print("🧠 [PARSER] - Found \(conditions.count) conditions")
        print("🧠 [PARSER] - Generated \(recommendations.count) recommendations")
        print("🧠 [PARSER] - Urgency level: \(urgencyLevel.rawValue)")
        print("🧠 [PARSER] - Overall confidence: \(confidence)")
        
        return result
    }
    
    private func saveAnalysisToHistory() async {
        guard let modelContext = modelContext,
              let result = analysisResult else { return }
        
        // Don't save the full image data to reduce memory usage
        // Just save the analysis results
        
        // Create a conversation for this analysis
        let conversation = Conversation(title: "Skin Analysis - \(Date().formatted())")
        
        // Create initial message with analysis results
        let analysisMessage = Message(
            content: formatAnalysisForChat(result),
            isUser: false
        )
        
        conversation.messages = [analysisMessage]
        
        // Insert into context
        modelContext.insert(conversation)
        
        // Save
        do {
            try modelContext.save()
        } catch {
            print("Failed to save analysis: \(error)")
        }
    }
    
    private func formatAnalysisForChat(_ result: SkinAnalysisResult) -> String {
        var message = "Skin Analysis Results:\n\n"
        
        message += "Potential Conditions:\n"
        for condition in result.conditions {
            message += "• \(condition.name) (\(Int(condition.confidence * 100))% confidence)\n"
            message += "  \(condition.description)\n\n"
        }
        
        message += "Recommendations:\n"
        for recommendation in result.recommendations {
            message += "• \(recommendation)\n"
        }
        
        message += "\nUrgency Level: \(result.urgencyLevel.rawValue)\n"
        message += "\n⚠️ Remember: This analysis is for informational purposes only. Please consult a healthcare professional for proper diagnosis and treatment."
        
        return message
    }
}