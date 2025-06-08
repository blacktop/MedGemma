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
        Analyze this dermatological image and provide your assessment:

        1. What skin condition do you think this lesion represents?
        2. Explain your reasoning using dermatological criteria (color, border, size, elevation, etc.)
        3. Provide a percentage of certainty for your diagnosis (e.g., "80% likely to be melanoma")
        4. List important considerations and next steps
        5. Include appropriate medical disclaimers

        Focus on key dermatological features like:
        - ABCDE criteria for melanoma (Asymmetry, Border, Color, Diameter, Evolution)
        - Color variations and patterns
        - Border irregularities
        - Size and elevation
        - Any concerning characteristics

        Please be specific about your confidence level as a percentage and explain what the patient should do next.

        Important: This is for educational purposes only. Always recommend consulting a healthcare professional for proper diagnosis.
        """
    }
    
    nonisolated func parseAnalysisResponse(_ response: String) -> SkinAnalysisResult {
        print("🧠 [PARSER] Starting to parse natural language model response...")
        print("🧠 [PARSER] Response length: \(response.count) characters")
        print("🧠 [PARSER] Full response: \(response)")
        
        var conditions: [PotentialCondition] = []
        var recommendations: [String] = []
        var urgencyLevel: UrgencyLevel = .low
        var confidence: Double = 0.75
        
        let lowercaseResponse = response.lowercased()
        
        // Extract percentage confidence from response
        confidence = extractConfidencePercentage(from: response)
        
        // Identify primary diagnosis from the response
        let primaryDiagnosis = extractPrimaryDiagnosis(from: response)
        
        // Determine urgency based on diagnosis and language
        urgencyLevel = determineUrgencyLevel(from: response, diagnosis: primaryDiagnosis)
        
        // Create main condition based on diagnosis
        if !primaryDiagnosis.isEmpty {
            conditions.append(PotentialCondition(
                name: primaryDiagnosis,
                description: extractReasoningFromResponse(response),
                confidence: confidence
            ))
        } else {
            // Fallback general condition
            conditions.append(PotentialCondition(
                name: "Skin Lesion Assessment",
                description: "Dermatological analysis completed - professional evaluation recommended",
                confidence: confidence
            ))
        }
        
        // Extract recommendations from the response
        recommendations = extractRecommendationsFromResponse(response, urgency: urgencyLevel)
        
        let result = SkinAnalysisResult(
            conditions: conditions,
            recommendations: recommendations,
            urgencyLevel: urgencyLevel,
            confidence: confidence,
            timestamp: Date()
        )
        
        print("🧠 [PARSER] Natural language parsing completed:")
        print("🧠 [PARSER] - Primary diagnosis: \(primaryDiagnosis)")
        print("🧠 [PARSER] - Confidence: \(Int(confidence * 100))%")
        print("🧠 [PARSER] - Urgency: \(urgencyLevel.rawValue)")
        print("🧠 [PARSER] - Recommendations: \(recommendations.count)")
        
        return result
    }
    
    // MARK: - Natural Language Parsing Helpers
    
    nonisolated private func extractConfidencePercentage(from response: String) -> Double {
        // Look for percentage patterns like "80%", ">80%", "likely 80%", etc.
        let percentagePatterns = [
            #"(\d+)%"#,  // "80%"
            #">(\d+)%"#, // ">80%"
            #"(\d+)% likely"#, // "80% likely"
            #"likely.*?(\d+)%"#, // "likely to be 80%"
            #"certainty.*?(\d+)%"#, // "certainty of 80%"
            #"confidence.*?(\d+)%"#  // "confidence level of 80%"
        ]
        
        for pattern in percentagePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: response, options: [], range: NSRange(location: 0, length: response.count)),
               let range = Range(match.range(at: 1), in: response),
               let percentage = Double(String(response[range])) {
                print("🧠 [PARSER] Found confidence percentage: \(percentage)%")
                return percentage / 100.0
            }
        }
        
        // If no percentage found, infer from language
        let lowercaseResponse = response.lowercased()
        if lowercaseResponse.contains("highly likely") || lowercaseResponse.contains("very likely") {
            return 0.85
        } else if lowercaseResponse.contains("likely") || lowercaseResponse.contains("appears to be") {
            return 0.75
        } else if lowercaseResponse.contains("possible") || lowercaseResponse.contains("might be") {
            return 0.65
        } else if lowercaseResponse.contains("unlikely") {
            return 0.3
        }
        
        return 0.75 // Default confidence
    }
    
    nonisolated private func extractPrimaryDiagnosis(from response: String) -> String {
        let lowercaseResponse = response.lowercased()
        
        // Check for specific conditions mentioned
        if lowercaseResponse.contains("melanoma") {
            return "Melanoma"
        } else if lowercaseResponse.contains("basal cell carcinoma") || lowercaseResponse.contains("basal cell") {
            return "Basal Cell Carcinoma"
        } else if lowercaseResponse.contains("squamous cell carcinoma") || lowercaseResponse.contains("squamous cell") {
            return "Squamous Cell Carcinoma"
        } else if lowercaseResponse.contains("seborrheic keratosis") {
            return "Seborrheic Keratosis"
        } else if lowercaseResponse.contains("actinic keratosis") {
            return "Actinic Keratosis"
        } else if lowercaseResponse.contains("benign") && lowercaseResponse.contains("mole") {
            return "Benign Mole"
        } else if lowercaseResponse.contains("mole") || lowercaseResponse.contains("nevus") {
            return "Pigmented Lesion (Mole)"
        } else if lowercaseResponse.contains("lesion") {
            return "Skin Lesion"
        }
        
        return "Dermatological Finding"
    }
    
    nonisolated private func determineUrgencyLevel(from response: String, diagnosis: String) -> UrgencyLevel {
        let lowercaseResponse = response.lowercased()
        
        // Urgent indicators
        if lowercaseResponse.contains("immediately") || 
           lowercaseResponse.contains("urgent") ||
           lowercaseResponse.contains("emergency") ||
           diagnosis.contains("Melanoma") ||
           lowercaseResponse.contains("cancerous") ||
           lowercaseResponse.contains("malignant") {
            return .urgent
        }
        
        // High priority indicators
        if lowercaseResponse.contains("concerning") ||
           lowercaseResponse.contains("suspicious") ||
           lowercaseResponse.contains("irregular") ||
           lowercaseResponse.contains("asymmetric") ||
           diagnosis.contains("Carcinoma") ||
           lowercaseResponse.contains("biopsy") {
            return .high
        }
        
        // Medium priority
        if lowercaseResponse.contains("monitor") ||
           lowercaseResponse.contains("follow up") ||
           lowercaseResponse.contains("track changes") ||
           diagnosis.contains("Keratosis") {
            return .medium
        }
        
        // Low priority for benign findings
        if lowercaseResponse.contains("benign") ||
           lowercaseResponse.contains("routine") ||
           diagnosis.contains("Benign") {
            return .low
        }
        
        // Default to medium for unknown conditions
        return .medium
    }
    
    nonisolated private func extractReasoningFromResponse(_ response: String) -> String {
        // Extract the reasoning section (usually after "Here's why:" or similar)
        let lines = response.components(separatedBy: .newlines)
        var reasoningLines: [String] = []
        var inReasoningSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Start collecting after reasoning indicators
            if trimmedLine.lowercased().contains("here's why") ||
               trimmedLine.lowercased().contains("reasoning") ||
               trimmedLine.lowercased().contains("because") {
                inReasoningSection = true
                continue
            }
            
            // Stop at certain sections
            if trimmedLine.lowercased().contains("important considerations") ||
               trimmedLine.lowercased().contains("what you should do") ||
               trimmedLine.lowercased().contains("disclaimer") ||
               trimmedLine.lowercased().contains("regarding the certainty") {
                break
            }
            
            // Collect reasoning lines
            if inReasoningSection && !trimmedLine.isEmpty {
                reasoningLines.append(trimmedLine)
            }
        }
        
        let reasoning = reasoningLines.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return reasoning.isEmpty ? "AI analysis based on visual assessment of dermatological features" : reasoning
    }
    
    nonisolated private func extractRecommendationsFromResponse(_ response: String, urgency: UrgencyLevel) -> [String] {
        var recommendations: [String] = []
        
        // Extract specific recommendations from the response
        let lines = response.components(separatedBy: .newlines)
        var inRecommendationSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Look for recommendation sections
            if trimmedLine.lowercased().contains("what you should do") ||
               trimmedLine.lowercased().contains("recommendations") ||
               trimmedLine.lowercased().contains("next steps") ||
               trimmedLine.lowercased().contains("important considerations") {
                inRecommendationSection = true
                continue
            }
            
            // Stop at disclaimer
            if trimmedLine.lowercased().contains("disclaimer") {
                break
            }
            
            // Collect bullet points and numbered items
            if inRecommendationSection && !trimmedLine.isEmpty {
                if trimmedLine.contains("•") || trimmedLine.contains("-") || 
                   trimmedLine.matches("^\\d+\\.") || trimmedLine.contains(":") {
                    let cleanedLine = trimmedLine
                        .replacingOccurrences(of: "•", with: "")
                        .replacingOccurrences(of: "-", with: "")
                        .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)
                    
                    if !cleanedLine.isEmpty {
                        recommendations.append(cleanedLine)
                    }
                }
            }
        }
        
        // Add default recommendations based on urgency if none found
        if recommendations.isEmpty {
            switch urgency {
            case .urgent:
                recommendations = [
                    "🚨 Schedule dermatologist appointment IMMEDIATELY",
                    "Seek evaluation within 24-48 hours",
                    "Document any changes with photos",
                    "Avoid sun exposure to the area"
                ]
            case .high:
                recommendations = [
                    "Schedule dermatologist appointment within 1-2 weeks",
                    "Monitor for any changes in size, color, or shape",
                    "Take photos for comparison",
                    "Use broad-spectrum sunscreen SPF 30+"
                ]
            case .medium:
                recommendations = [
                    "Consider dermatologist evaluation within 1 month",
                    "Monitor for changes and document with photos",
                    "Apply sun protection measures",
                    "Follow up if appearance changes"
                ]
            case .low:
                recommendations = [
                    "Routine monitoring recommended",
                    "Annual dermatological check-up",
                    "Daily sun protection (SPF 30+)",
                    "Monthly self-examination"
                ]
            }
        }
        
        // Always add medical disclaimer
        recommendations.append("⚠️ This is AI analysis only - consult a dermatologist for proper diagnosis")
        
        return recommendations
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

// MARK: - String Extensions
extension String {
    func matches(_ pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}

// MARK: - Testing Extensions
extension SkinAnalysisViewModel {
    // Expose internal methods for testing
    nonisolated func testParseAnalysisResponse(_ response: String) -> SkinAnalysisResult {
        return parseAnalysisResponse(response)
    }
}