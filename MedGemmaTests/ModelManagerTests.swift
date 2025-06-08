import XCTest
import UIKit
import CoreML
@testable import MedGemma

class ModelManagerTests: XCTestCase {
    var modelManager: ModelManager!
    
    override func setUpWithError() throws {
        modelManager = ModelManager.shared
    }
    
    override func tearDownWithError() throws {
        modelManager = nil
    }
    
    // MARK: - Logits Decoding Tests
    
    func testLogitsDecodingWithMedicalTerms() throws {
        // Create mock logits that should trigger melanoma detection
        let mockLogits = createMockLogitsForMelanoma()
        
        let result = modelManager.testDecodeLogitsToText(mockLogits)
        
        print("🧪 [TEST] Decoded result: \(result)")
        
        // Check for medical terminology
        XCTAssertTrue(result.contains("irregular") || 
                     result.contains("asymmetric") || 
                     result.contains("concerning") ||
                     result.contains("melanoma"),
                     "Should contain concerning medical terms")
        
        XCTAssertTrue(result.contains("**"), "Should have medical formatting")
    }
    
    func testAnalyticalFallbackForHighVariance() throws {
        // Create logits with high variance (indicating irregular patterns)
        let highVarianceLogits = createHighVarianceLogits()
        
        let result = modelManager.testGenerateAnalyticalFallback(from: highVarianceLogits)
        
        print("🧪 [TEST] High variance result: \(result)")
        
        XCTAssertTrue(result.contains("irregular patterns detected"), 
                     "High variance should trigger irregular pattern detection")
        XCTAssertTrue(result.contains("URGENT") || result.contains("MODERATE"),
                     "High variance should trigger higher urgency")
    }
    
    // MARK: - Image Analysis Tests
    
    func testMelanomaImageAnalysis() async throws {
        // Load melanoma test image
        guard let melanomaImage = await loadMelanomaTestImage() else {
            XCTFail("Could not load melanoma test image")
            return
        }
        
        print("🧪 [TEST] Testing melanoma image analysis...")
        
        do {
            let result = try await modelManager.analyzeImage(
                image: melanomaImage,
                prompt: "Analyze this dermatological image for potential skin cancer"
            )
            
            print("🧪 [TEST] Melanoma analysis result:")
            print(String(repeating: "=", count: 50))
            print(result)
            print(String(repeating: "=", count: 50))
            
            // Verify the response contains concerning indicators
            let lowercaseResult = result.lowercased()
            
            let concerningTerms = [
                "irregular", "asymmetric", "melanoma", "malignant", 
                "suspicious", "concerning", "urgent", "prominent"
            ]
            
            let foundTerms = concerningTerms.filter { lowercaseResult.contains($0) }
            
            XCTAssertFalse(foundTerms.isEmpty, 
                          "Melanoma analysis should contain at least one concerning term. Found: \(foundTerms)")
            
            print("🧪 [TEST] Found concerning terms: \(foundTerms)")
            
        } catch {
            // If model fails, we should still get a fallback response
            print("🧪 [TEST] Model failed, checking fallback...")
            XCTFail("Model analysis failed: \(error)")
        }
    }
    
    // MARK: - Parser Tests
    
    func testSkinAnalysisViewModelParsing() async throws {
        let viewModel = await SkinAnalysisViewModel()
        
        // Test melanoma response parsing
        let melanomaResponse = """
        **Dermatological Analysis Results:**
        
        **Observed Characteristics:**
        • irregular patterns detected
        • asymmetrical features
        • complex pigmentation patterns
        
        **Assessment Indicators:**
        • notable characteristics
        • requires professional evaluation
        
        **Urgency Level:** URGENT
        """
        
        let result = viewModel.testParseAnalysisResponse(melanomaResponse)
        
        print("🧪 [TEST] Parsed melanoma response:")
        print("   Conditions: \(result.conditions.count)")
        for condition in result.conditions {
            print("   - \(condition.name): \(condition.confidence)")
        }
        print("   Urgency: \(result.urgencyLevel.rawValue)")
        print("   Recommendations: \(result.recommendations.count)")
        
        // Verify high urgency detection
        XCTAssertEqual(result.urgencyLevel, .urgent, "Should detect urgent priority for melanoma indicators")
        
        // Check for melanoma-specific conditions
        let hasIrregularFeatures = result.conditions.contains { 
            $0.name.lowercased().contains("irregular") || $0.name.lowercased().contains("asymmetric")
        }
        XCTAssertTrue(hasIrregularFeatures, "Should detect irregular/asymmetric features")
        
        // Verify urgent recommendations
        let hasUrgentRecommendation = result.recommendations.contains {
            $0.lowercased().contains("urgent") || $0.lowercased().contains("immediate")
        }
        XCTAssertTrue(hasUrgentRecommendation, "Should include urgent recommendations")
    }
    
    func testBenignLesionParsing() async throws {
        let viewModel = await SkinAnalysisViewModel()
        
        // Test benign response parsing
        let benignResponse = """
        **Analysis Summary:**
        • Medical AI model successfully processed the image
        • Standard skin features detected
        • Routine monitoring recommended
        """
        
        let result = viewModel.testParseAnalysisResponse(benignResponse)
        
        print("🧪 [TEST] Parsed benign response:")
        print("   Urgency: \(result.urgencyLevel.rawValue)")
        print("   Conditions: \(result.conditions.count)")
        
        // Should be low urgency for benign features
        XCTAssertEqual(result.urgencyLevel, .low, "Benign features should result in low urgency")
        
        // Should have routine recommendations
        let hasRoutineRecommendation = result.recommendations.contains {
            $0.lowercased().contains("routine") || $0.lowercased().contains("annual")
        }
        XCTAssertTrue(hasRoutineRecommendation, "Should include routine recommendations")
    }
    
    // MARK: - Performance Tests
    
    func testAnalysisPerformance() throws {
        guard let testImage = createTestImage() else {
            XCTFail("Could not create test image")
            return
        }
        
        measure {
            Task {
                do {
                    _ = try await modelManager.analyzeImage(
                        image: testImage,
                        prompt: "Quick analysis test"
                    )
                } catch {
                    print("Performance test failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockLogitsForMelanoma() -> MLMultiArray {
        // Create logits that would trigger melanoma detection
        guard let logits = try? MLMultiArray(shape: [1, 512, 256000], dataType: .float32) else {
            fatalError("Could not create mock logits")
        }
        
        // Set high values for melanoma-related token positions
        let melanomaTokenIds = [4, 6, 7, 17, 18] // melanoma, malignant, irregular, concerning, suspicious
        
        for position in 0..<10 {
            for tokenId in melanomaTokenIds {
                let index = position * 256000 + tokenId
                if index < logits.count {
                    logits[index] = NSNumber(value: Float.random(in: 15...25)) // High logit values
                }
            }
        }
        
        return logits
    }
    
    private func createHighVarianceLogits() -> MLMultiArray {
        guard let logits = try? MLMultiArray(shape: [1, 10, 100], dataType: .float32) else {
            fatalError("Could not create high variance logits")
        }
        
        // Create high variance pattern
        for i in 0..<logits.count {
            let value = i % 2 == 0 ? Float.random(in: -50...(-10)) : Float.random(in: 10...50)
            logits[i] = NSNumber(value: value)
        }
        
        return logits
    }
    
    private func loadMelanomaTestImage() async -> UIImage? {
        // Try to load the Wikipedia melanoma image
        let melanomaURL = "https://upload.wikimedia.org/wikipedia/commons/4/4e/Melanoma.jpg"
        
        guard let url = URL(string: melanomaURL) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("🧪 [TEST] Could not load melanoma image from Wikipedia: \(error)")
            // Return a fallback test image
            return createTestImage()
        }
    }
    
    private func createTestImage() -> UIImage? {
        return TestImageGenerator.createMelanomaSimulation()
    }
    
    func testBenignMoleAnalysis() async throws {
        let benignImage = TestImageGenerator.createBenignMole()
        
        do {
            let result = try await modelManager.analyzeImage(
                image: benignImage,
                prompt: "Analyze this skin lesion"
            )
            
            print("🧪 [TEST] Benign mole analysis result:")
            print(result)
            
            // Benign moles should not trigger high urgency
            let lowercaseResult = result.lowercased()
            let urgentTerms = ["urgent", "emergency", "immediate"]
            let hasUrgentTerms = urgentTerms.contains { lowercaseResult.contains($0) }
            
            XCTAssertFalse(hasUrgentTerms, "Benign mole should not trigger urgent warnings")
            
        } catch {
            print("🧪 [TEST] Benign analysis failed: \(error)")
        }
    }
    
    func testInflammatoryLesionAnalysis() async throws {
        let inflammatoryImage = TestImageGenerator.createInflammatoryLesion()
        
        do {
            let result = try await modelManager.analyzeImage(
                image: inflammatoryImage,
                prompt: "Analyze this inflamed skin area"
            )
            
            print("🧪 [TEST] Inflammatory lesion analysis result:")
            print(result)
            
            // Should detect inflammatory terms
            let lowercaseResult = result.lowercased()
            XCTAssertTrue(lowercaseResult.contains("inflam") || 
                         lowercaseResult.contains("red") ||
                         lowercaseResult.contains("irritat"),
                         "Should detect inflammatory characteristics")
            
        } catch {
            print("🧪 [TEST] Inflammatory analysis failed: \(error)")
        }
    }
}