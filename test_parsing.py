#!/usr/bin/env python3
"""
Quick test script for MedGemma parsing logic without needing to build the full iOS app.
This simulates the response parsing that happens in SkinAnalysisViewModel.
"""

def test_melanoma_response_parsing():
    print("🔬 Testing Melanoma Response Parsing...")
    
    melanoma_response = """
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
    
    # Simulate the parsing logic from SkinAnalysisViewModel
    response = melanoma_response.lower()
    conditions = []
    urgency_level = "low"
    recommendations = []
    
    # HIGH PRIORITY: Melanoma and malignant indicators
    if "melanoma" in response or "malignant" in response:
        conditions.append({
            "name": "Possible Melanoma",
            "description": "Suspicious pigmented lesion with concerning features",
            "confidence": 0.9
        })
        urgency_level = "urgent"
    
    # HIGH PRIORITY: ABCDE criteria and concerning features
    if any(word in response for word in ["asymmet", "irregular", "variegated", "suspicious"]):
        conditions.append({
            "name": "Irregular/Asymmetric Features",
            "description": "Lesion shows asymmetrical or irregular characteristics requiring evaluation",
            "confidence": 0.85
        })
        if urgency_level == "low":
            urgency_level = "high"
    
    # MEDIUM PRIORITY: Concerning patterns (but not if negated)
    concerning_words = ["concerning", "notable", "prominent", "complex"]
    has_concerning_features = False
    
    for word in concerning_words:
        if word in response:
            # Check for negations before the word
            word_index = response.find(word)
            before_word = response[:word_index]
            negations = ["no ", "not ", "without ", "lacking ", "absent"]
            is_negated = any(negation in before_word[-20:] for negation in negations)
            # Debug: Found word and checking negation
            if not is_negated:
                has_concerning_features = True
                break
    
    if has_concerning_features:
        conditions.append({
            "name": "Concerning Features", 
            "description": "Notable characteristics detected that warrant professional review",
            "confidence": 0.75
        })
        if urgency_level == "low":
            urgency_level = "medium"
    
    # Emergency indicators
    if any(word in response for word in ["urgent", "immediate", "emergency"]):
        urgency_level = "urgent"
    
    # Generate recommendations based on urgency
    if urgency_level == "urgent":
        recommendations = [
            "⚠️ URGENT: Seek immediate dermatological evaluation",
            "Schedule appointment within 24-48 hours",
            "Consider emergency consultation if rapid changes observed",
            "Document lesion with high-resolution photos"
        ]
    
    # Add specific recommendations
    if "melanoma" in response:
        recommendations.insert(1, "Discuss biopsy options with dermatologist")
    
    if any(word in response for word in ["irregular", "asymmet"]):
        recommendations.append("Pay special attention to border irregularities")
    
    print("✅ Results:")
    print(f"   Urgency: {urgency_level.upper()}")
    print(f"   Conditions: {len(conditions)}")
    for condition in conditions:
        print(f"   - {condition['name']} ({int(condition['confidence'] * 100)}%)")
    print(f"   Recommendations: {len(recommendations)}")
    for i, rec in enumerate(recommendations[:3]):
        print(f"   {i + 1}. {rec}")
    
    # Assertions
    assert urgency_level == "urgent", f"❌ Should detect URGENT for melanoma indicators, got {urgency_level}"
    assert len(conditions) > 0, "❌ Should have detected conditions"
    assert any("irregular" in c["name"].lower() or "asymmetric" in c["name"].lower() for c in conditions), "❌ Should detect irregular features"
    
    print("✅ Melanoma parsing test PASSED")
    return True

def test_benign_response_parsing():
    print("\n🔬 Testing Benign Response Parsing...")
    
    benign_response = """
    **Analysis Summary:**
    • Medical AI model successfully processed the image
    • Standard skin features detected
    • Routine monitoring recommended
    • No concerning characteristics identified
    """
    
    response = benign_response.lower()
    conditions = []
    urgency_level = "low"
    
    # Test that benign features don't trigger high urgency
    if "melanoma" in response or "malignant" in response:
        urgency_level = "urgent"
    elif any(word in response for word in ["asymmet", "irregular", "suspicious"]):
        urgency_level = "high"
    else:
        # Check for concerning patterns with negation handling
        concerning_words = ["concerning", "notable", "prominent", "complex"]
        has_concerning_features = False
        
        for word in concerning_words:
            if word in response:
                word_index = response.find(word)
                before_word = response[:word_index]
                negations = ["no ", "not ", "without ", "lacking ", "absent"]
                is_negated = any(negation in before_word[-20:] for negation in negations)
                # Check for negations properly
                if not is_negated:
                    has_concerning_features = True
                    break
        
        if has_concerning_features:
            urgency_level = "medium"
    
    # Should create general assessment for benign
    if not conditions:
        conditions.append({
            "name": "General Assessment",
            "description": "AI analysis completed - requires professional interpretation",
            "confidence": 0.75
        })
    
    print("✅ Results:")
    print(f"   Urgency: {urgency_level.upper()}")
    print(f"   Conditions: {len(conditions)}")
    print(f"   Should be LOW urgency for benign features")
    
    assert urgency_level == "low", f"❌ Should detect LOW urgency for benign features, got {urgency_level}"
    print("✅ Benign parsing test PASSED")
    return True

def test_logits_analysis_simulation():
    print("\n🔬 Testing Logits Analysis Simulation...")
    
    # Simulate high variance logits (concerning patterns)
    import random
    random.seed(42)  # For reproducible results
    
    logits = [random.uniform(-50, -10) if i % 3 == 0 else random.uniform(10, 50) for i in range(100)]
    
    # Calculate statistics like in the Swift code
    avg_logit = sum(logits) / len(logits)
    max_logit = max(logits)
    variance = sum((x - avg_logit) ** 2 for x in logits) / len(logits)
    
    print(f"   Avg logit: {avg_logit:.2f}")
    print(f"   Max logit: {max_logit:.2f}")  
    print(f"   Variance: {variance:.2f}")
    
    # Generate analysis based on patterns (like Swift code)
    characteristics = []
    urgency_indicators = []
    
    if variance > 50:
        characteristics.append("irregular patterns detected")
        urgency_indicators.append("asymmetrical features")
    
    if max_logit > 10:
        characteristics.append("prominent features identified")
        urgency_indicators.append("notable characteristics")
    
    if avg_logit > 5:
        characteristics.append("complex pigmentation patterns")
        urgency_indicators.append("requires professional evaluation")
    
    urgency_level = "URGENT" if len(urgency_indicators) >= 2 else ("MODERATE" if len(urgency_indicators) == 1 else "LOW")
    
    print(f"   Characteristics: {len(characteristics)}")
    for char in characteristics:
        print(f"   - {char}")
    print(f"   Urgency Level: {urgency_level}")
    
    # High variance should trigger concerning analysis
    assert len(characteristics) > 0, "❌ High variance should trigger characteristic detection"
    assert urgency_level in ["MODERATE", "URGENT"], f"❌ High variance should trigger higher urgency, got {urgency_level}"
    
    print("✅ Logits analysis simulation PASSED")
    return True

def main():
    print("🧪 Starting MedGemma Quick Tests...")
    print("=" * 60)
    
    try:
        test_melanoma_response_parsing()
        test_benign_response_parsing()
        test_logits_analysis_simulation()
        
        print("=" * 60)
        print("🧪 All Quick Tests PASSED! ✅")
        
    except AssertionError as e:
        print(f"❌ Test Failed: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected Error: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)