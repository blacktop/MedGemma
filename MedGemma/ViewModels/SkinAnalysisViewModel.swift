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
            analysisResult = parseAnalysisResponse(response)
            
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
        // This is a simplified parser - in production, you'd use more sophisticated NLP
        // For now, we'll create mock results based on the response
        
        // Mock implementation - replace with actual parsing logic
        let conditions = [
            PotentialCondition(
                name: "Benign Nevus (Mole)",
                description: "Common benign skin growth with regular borders and uniform color",
                confidence: 0.85
            ),
            PotentialCondition(
                name: "Seborrheic Keratosis",
                description: "Non-cancerous skin growth common in older adults",
                confidence: 0.45
            )
        ]
        
        let recommendations = [
            "Monitor for any changes in size, color, or shape",
            "Use sunscreen SPF 30+ daily",
            "Consider annual skin check with dermatologist",
            "Document with photos for comparison"
        ]
        
        let urgencyLevel: UrgencyLevel = .low
        
        return SkinAnalysisResult(
            conditions: conditions,
            recommendations: recommendations,
            urgencyLevel: urgencyLevel,
            confidence: 0.85,
            timestamp: Date()
        )
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