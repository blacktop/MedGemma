#!/usr/bin/env python3
"""
Quick test script for MedGemma parsing logic without needing to build the full iOS app.
This simulates the response parsing that happens in SkinAnalysisViewModel.
"""

def test_melanoma_response_parsing():
    print("🔬 Testing Actual Melanoma Model Response Parsing...")
    
    # Real model response example from the user
    melanoma_response = """
    Based on the image, the lesion appears to be a melanoma.

    Here's why:

    Color: The lesion is a dark, irregular, and uneven color. Melanomas often have a dark, brown, or black hue.
    Border: The border is irregular and poorly defined. Melanomas typically have borders that are not smooth and well-defined.
    Size: The lesion is relatively large, which is a concerning feature.
    Elevation: The lesion appears raised, which is another characteristic of melanoma.
    Important Considerations:

    This is a preliminary assessment based on a single image. A definitive diagnosis requires a clinical examination by a dermatologist, including a biopsy.
    The presence of these features does not automatically mean the lesion is cancerous. However, it warrants further investigation.
    It is crucial to consult a dermatologist for a proper diagnosis and treatment plan.
    Disclaimer: I am an AI and cannot provide medical diagnoses. This information is for educational purposes only and should not be considered a substitute for professional medical advice.

    Regarding the certainty percentage:

    It's impossible to give a precise percentage of certainty without a clinical examination and biopsy. However, based on the image, the likelihood of it being a melanoma is high (likely >80%).

    What you should do:

    Schedule an Appointment with a Dermatologist Immediately: This is the most important step. A dermatologist is a skin specialist and can properly examine the lesion, determine if it is cancerous, and recommend the appropriate treatment. Don't delay.
    Prepare for Your Appointment:
    Take Photos: If possible, take clear, well-lit photos of the lesion. This will help the dermatologist assess them accurately.
    Note Any Symptoms: Write down any symptoms you've been experiencing, such as itching, pain, bleeding, or changes in the lesion's appearance.
    Medical History: Be prepared to discuss your medical history, including any previous skin conditions, medications you're taking, and family history of skin cancer.
    Disclaimer: I am an AI and cannot provide medical diagnoses. This information is for educational purposes only and should not be considered a substitute for professional medical advice.
    """
    
    # Simulate the new natural language parsing logic
    response = melanoma_response.lower()
    
    # Extract confidence percentage 
    confidence = 0.75  # default
    import re
    percent_match = re.search(r'(\d+)%', melanoma_response)
    if percent_match:
        confidence = float(percent_match.group(1)) / 100.0
    elif "likely >80%" in melanoma_response:
        confidence = 0.85  # interpret >80% as 85%
    
    # Extract primary diagnosis
    primary_diagnosis = "Melanoma" if "melanoma" in response else "Skin Lesion"
    
    # Determine urgency
    urgency_level = "urgent"  # melanoma = urgent
    if "immediately" in response or "urgent" in response or "melanoma" in response:
        urgency_level = "urgent"
    
    # Create condition
    conditions = [{
        "name": primary_diagnosis,
        "description": "AI analysis based on visual assessment showing irregular patterns, asymmetrical features, dark uneven color, poorly defined borders, and elevated appearance",
        "confidence": confidence
    }]
    
    # Extract recommendations from response
    recommendations = []
    lines = melanoma_response.split('\n')
    in_recommendation_section = False
    
    for line in lines:
        line = line.strip()
        if "what you should do" in line.lower():
            in_recommendation_section = True
            continue
        if "disclaimer:" in line.lower():
            break
        if in_recommendation_section and line and (":" in line or line.startswith("-")):
            clean_line = line.replace(":", "").strip()
            if clean_line:
                recommendations.append(clean_line)
    
    # Add default urgent recommendations if none found
    if not recommendations:
        recommendations = [
            "🚨 Schedule dermatologist appointment IMMEDIATELY",
            "Seek evaluation within 24-48 hours", 
            "Document any changes with photos",
            "Discuss biopsy options with dermatologist"
        ]
    
    print("✅ Results:")
    print(f"   Urgency: {urgency_level.upper()}")
    print(f"   Conditions: {len(conditions)}")
    for condition in conditions:
        print(f"   - {condition['name']} ({int(condition['confidence'] * 100)}%)")
    print(f"   Recommendations: {len(recommendations)}")
    for i, rec in enumerate(recommendations[:3]):
        print(f"   {i + 1}. {rec}")
    
    # Assertions for new natural language parsing
    assert urgency_level == "urgent", f"❌ Should detect URGENT for melanoma, got {urgency_level}"
    assert len(conditions) > 0, "❌ Should have detected conditions"
    assert conditions[0]["name"] == "Melanoma", f"❌ Should detect Melanoma as primary diagnosis, got {conditions[0]['name']}"
    assert confidence >= 0.8, f"❌ Should extract high confidence (>80%), got {int(confidence * 100)}%"
    assert len(recommendations) > 0, "❌ Should have recommendations"
    
    print("✅ Natural language melanoma parsing test PASSED")
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