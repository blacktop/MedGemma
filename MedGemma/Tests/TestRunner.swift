import Foundation
import UIKit
import CoreML

// Simple test runner for quick model testing without full app build
class TestRunner {
    static func runQuickTests() {
        print("🧪 Starting MedGemma Quick Tests...")
        print(String(repeating: "=", count: 60))
        
        testParserWithMelanomaResponse()
        testParserWithBenignResponse()
        testLogitsDecoding()
        
        print(String(repeating: "=", count: 60))
        print("🧪 Quick Tests Completed!")
    }
    
    static func testParserWithMelanomaResponse() {
        print("\n🔬 Testing Melanoma Response Parsing...")
        
        let melanomaResponse = """
        **Dermatological Analysis Results:**
        
        **Observed Characteristics:**
        • irregular patterns detected
        • asymmetrical features
        • complex pigmentation patterns
        • suspicious lesion characteristics
        
        **Assessment Indicators:**
        • notable characteristics
        • concerning features identified
        • requires urgent professional evaluation
        
        **Urgency Level:** URGENT
        
        **Clinical Recommendations:**
        • Professional dermatological examination recommended
        • Consider melanoma screening
        • Document with high-resolution photography
        """
        
        let viewModel = SkinAnalysisViewModel()
        let result = viewModel.parseAnalysisResponse(melanomaResponse)
        
        print("✅ Results:")
        print("   Urgency: \(result.urgencyLevel.rawValue)")
        print("   Conditions: \(result.conditions.count)")
        for condition in result.conditions {
            print("   - \(condition.name) (\(Int(condition.confidence * 100))%)")
        }
        print("   Recommendations: \(result.recommendations.count)")
        for (i, rec) in result.recommendations.prefix(3).enumerated() {
            print("   \(i + 1). \(rec)")
        }
        
        // Assertions
        assert(result.urgencyLevel == .urgent, "❌ Should detect URGENT for melanoma indicators")
        assert(result.conditions.count > 0, "❌ Should have detected conditions")
        print("✅ Melanoma parsing test PASSED")
    }
    
    static func testParserWithBenignResponse() {
        print("\n🔬 Testing Benign Response Parsing...")
        
        let benignResponse = """
        **Analysis Summary:**
        • Medical AI model successfully processed the image
        • Standard skin features detected
        • Routine monitoring recommended
        • No concerning characteristics identified
        """
        
        let viewModel = SkinAnalysisViewModel()
        let result = viewModel.parseAnalysisResponse(benignResponse)
        
        print("✅ Results:")
        print("   Urgency: \(result.urgencyLevel.rawValue)")
        print("   Conditions: \(result.conditions.count)")
        print("   Recommendations: \(result.recommendations.count)")
        
        // Should be low urgency for benign
        assert(result.urgencyLevel == .low, "❌ Should detect LOW urgency for benign features")
        print("✅ Benign parsing test PASSED")
    }
    
    static func testLogitsDecoding() {
        print("\n🔬 Testing Logits Decoding...")
        
        // Create mock high-variance logits (indicating concerning patterns)
        guard let logits = try? MLMultiArray(shape: [1, 10, 100], dataType: .float32) else {
            print("❌ Could not create test logits")
            return
        }
        
        // Fill with high variance pattern
        for i in 0..<logits.count {
            let value = i % 3 == 0 ? Float.random(in: -50...(-10)) : Float.random(in: 10...50)
            logits[i] = NSNumber(value: value)
        }
        
        let modelManager = ModelManager.shared
        let result = modelManager.generateAnalyticalFallback(from: logits)
        
        print("✅ Logits analysis result:")
        print(String(result.prefix(200)) + "...")
        
        // Should contain analysis indicators
        assert(result.contains("**"), "❌ Should have medical formatting")
        assert(result.contains("Dermatological") || result.contains("Analysis"), "❌ Should contain medical terms")
        print("✅ Logits decoding test PASSED")
    }
}

// Run tests if executed directly
if CommandLine.arguments.contains("--run-tests") {
    TestRunner.runQuickTests()
}