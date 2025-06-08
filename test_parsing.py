#!/usr/bin/env python3
"""
Quick test script for MedGemma parsing logic without needing to build the full iOS app.
This simulates the response parsing that happens in SkinAnalysisViewModel.
"""

def test_json_response_parsing():
    print("🔬 Testing JSON Melanoma Model Response Parsing...")
    
    # JSON response example from the user
    melanoma_json_response = """{
  "diagnosis": "Melanoma",
  "image_analysis": {
    "color": "Dark, irregular, uneven",
    "border": "Irregular and poorly defined",
    "size": "Relatively large",
    "elevation": "Raised"
  },
  "recommendation": "Schedule an immediate appointment with a dermatologist for a clinical examination and biopsy.",
  "confidence_level": "High (likely >80%)",
  "additional_notes": "This is a preliminary assessment based on a single image. A definitive diagnosis requires a clinical examination by a dermatologist."
}"""
    
    # Test JSON parsing (simulating Swift parseJSONResponse function)
    import json
    import re
    
    try:
        # Parse JSON
        data = json.loads(melanoma_json_response)
        
        # Extract fields
        diagnosis = data.get("diagnosis", "Dermatological Finding")
        recommendation = data.get("recommendation", "Consult a dermatologist")
        confidence_level = data.get("confidence_level", "Medium")
        additional_notes = data.get("additional_notes", "Professional evaluation recommended")
        
        # Parse image analysis
        analysis_description = additional_notes
        if "image_analysis" in data:
            image_analysis = data["image_analysis"]
            features = [
                f"Color: {image_analysis.get('color', 'Not specified')}",
                f"Border: {image_analysis.get('border', 'Not specified')}",
                f"Size: {image_analysis.get('size', 'Not specified')}",
                f"Elevation: {image_analysis.get('elevation', 'Not specified')}"
            ]
            analysis_description = ". ".join(features) + ". " + additional_notes
        
        # Extract confidence percentage
        confidence = 0.75  # default
        # Handle special cases like ">80%"
        if "likely >80" in confidence_level.lower():
            confidence = 0.85
        else:
            # Extract percentage if present
            percent_match = re.search(r'(\d+)%', confidence_level)
            if percent_match:
                confidence = float(percent_match.group(1)) / 100.0
            elif "high" in confidence_level.lower():
                confidence = 0.85
            elif "medium" in confidence_level.lower():
                confidence = 0.70
            elif "low" in confidence_level.lower():
                confidence = 0.50
        
        # Determine urgency level from diagnosis and recommendation
        lower_diagnosis = diagnosis.lower()
        lower_recommendation = recommendation.lower()
        
        if ("melanoma" in lower_diagnosis or 
            "immediate" in lower_recommendation or
            "urgent" in lower_recommendation or
            "malignant" in lower_diagnosis):
            urgency_level = "urgent"
        elif ("carcinoma" in lower_diagnosis or
              "suspicious" in lower_diagnosis or
              "biopsy" in lower_recommendation or
              "soon" in lower_recommendation):
            urgency_level = "high"
        elif ("keratosis" in lower_diagnosis or
              "monitor" in lower_recommendation or
              "follow" in lower_recommendation):
            urgency_level = "medium"
        elif ("benign" in lower_diagnosis or
              "routine" in lower_recommendation):
            urgency_level = "low"
        else:
            urgency_level = "medium"
        
        # Create condition
        condition = {
            "name": diagnosis,
            "description": analysis_description,
            "confidence": confidence
        }
        
        # Generate recommendations
        recommendations = [recommendation]
        
        # Add urgency-specific recommendations
        if urgency_level == "urgent":
            recommendations.extend([
                "🚨 This requires IMMEDIATE medical attention",
                "Schedule appointment within 24-48 hours",
                "Consider emergency consultation if rapid changes"
            ])
        elif urgency_level == "high":
            recommendations.extend([
                "Schedule dermatologist appointment within 1-2 weeks",
                "Monitor closely for any changes"
            ])
        elif urgency_level == "medium":
            recommendations.extend([
                "Consider evaluation within 1 month",
                "Monitor for changes and document with photos"
            ])
        else:
            recommendations.extend([
                "Routine monitoring recommended",
                "Annual dermatological check-up"
            ])
        
        # Add general recommendations
        recommendations.extend([
            "Take photos for documentation and comparison",
            "Use broad-spectrum sunscreen daily (SPF 30+)",
            "⚠️ This is AI analysis - consult a dermatologist for diagnosis"
        ])
        
        print("✅ JSON Parsing Results:")
        print(f"   Diagnosis: {diagnosis}")
        print(f"   Urgency: {urgency_level.upper()}")
        print(f"   Confidence: {int(confidence * 100)}%")
        print(f"   Recommendations: {len(recommendations)}")
        for i, rec in enumerate(recommendations[:4]):
            print(f"   {i + 1}. {rec}")
        
        # Assertions for JSON parsing
        assert diagnosis == "Melanoma", f"❌ Should extract 'Melanoma' as diagnosis, got '{diagnosis}'"
        assert urgency_level == "urgent", f"❌ Should detect URGENT for melanoma, got {urgency_level}"
        assert confidence >= 0.8, f"❌ Should extract high confidence (>80%), got {int(confidence * 100)}%"
        assert len(recommendations) > 0, "❌ Should have recommendations"
        assert any("immediate" in rec.lower() for rec in recommendations), "❌ Should have immediate recommendations"
        
        print("✅ JSON parsing test PASSED")
        return True
        
    except json.JSONDecodeError as e:
        print(f"❌ JSON parsing failed: {e}")
        return False

def test_melanoma_response_parsing():
    print("\n🔬 Testing Natural Language Melanoma Model Response Parsing...")
    
    # Natural language response for fallback testing
    melanoma_natural_response = """
    **Dermatological Analysis Results:**
    
    **Observed Characteristics:**
    • irregular patterns detected
    • asymmetrical features present
    • dark, uneven pigmentation observed
    • poorly defined borders noted
    • elevated surface texture
    
    **Assessment Indicators:**
    • notable concerning characteristics
    • requires immediate professional evaluation
    • melanoma characteristics present (>80% confidence)
    
    **Urgency Level:** URGENT
    
    **What you should do:**
    - Schedule dermatologist appointment IMMEDIATELY
    - Seek evaluation within 24-48 hours
    - Document any changes with photos
    - Discuss biopsy options with dermatologist
    
    **Important:** This analysis requires validation by a qualified healthcare provider.
    """
    
    # Simulate natural language parsing (fallback when JSON fails)
    response = melanoma_natural_response.lower()
    
    # Extract confidence percentage 
    confidence = 0.75  # default
    import re
    percent_match = re.search(r'(\d+)%', melanoma_natural_response)
    if percent_match:
        confidence = float(percent_match.group(1)) / 100.0
    elif "likely >80%" in melanoma_natural_response or ">80%" in melanoma_natural_response:
        confidence = 0.85
    
    # Extract primary diagnosis
    if "melanoma" in response:
        primary_diagnosis = "Melanoma"
    elif "carcinoma" in response:
        primary_diagnosis = "Carcinoma"
    elif "lesion" in response:
        primary_diagnosis = "Skin Lesion"
    else:
        primary_diagnosis = "Dermatological Finding"
    
    # Determine urgency
    if ("immediately" in response or "urgent" in response or 
        "melanoma" in response or "emergency" in response):
        urgency_level = "urgent"
    elif ("concerning" in response or "suspicious" in response or
          "irregular" in response or "asymmetric" in response):
        urgency_level = "high"
    elif "monitor" in response or "follow up" in response:
        urgency_level = "medium"
    elif "benign" in response or "routine" in response:
        urgency_level = "low"
    else:
        urgency_level = "medium"
    
    # Create condition
    conditions = [{
        "name": primary_diagnosis,
        "description": "AI analysis showing irregular patterns, asymmetrical features, dark uneven color, poorly defined borders, and elevated appearance",
        "confidence": confidence
    }]
    
    # Extract recommendations from response
    recommendations = []
    lines = melanoma_natural_response.split('\n')
    in_recommendation_section = False
    
    for line in lines:
        line = line.strip()
        if "what you should do" in line.lower():
            in_recommendation_section = True
            continue
        if "important:" in line.lower():
            break
        if in_recommendation_section and line and (line.startswith("-") or line.startswith("•")):
            clean_line = line.replace("-", "").replace("•", "").strip()
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
    
    print("✅ Natural Language Results:")
    print(f"   Urgency: {urgency_level.upper()}")
    print(f"   Conditions: {len(conditions)}")
    for condition in conditions:
        print(f"   - {condition['name']} ({int(condition['confidence'] * 100)}%)")
    print(f"   Recommendations: {len(recommendations)}")
    for i, rec in enumerate(recommendations[:3]):
        print(f"   {i + 1}. {rec}")
    
    # Assertions for natural language parsing
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
        test_json_response_parsing()
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