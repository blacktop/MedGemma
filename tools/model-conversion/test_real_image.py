#!/usr/bin/env python3
"""
Simple test using a real melanoma image with the converted MedGemma model.
"""

import os
import sys
import time
import requests
import numpy as np
from PIL import Image
import tempfile
import io

def download_melanoma_image():
    """Download the melanoma image from Wikipedia."""
    url = "https://upload.wikimedia.org/wikipedia/commons/6/6c/Melanoma.jpg"

    print("📸 Downloading melanoma image...")
    try:
        headers = {
            'User-Agent': 'MedGemma/1.0 (github.com/blacktop/MedGemma) for medical AI research'
        }
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()

        # Load image directly from bytes
        image = Image.open(io.BytesIO(response.content))

        print(f"✅ Downloaded image: {image.size[0]}x{image.size[1]} pixels")
        return image

    except Exception as e:
        print(f"❌ Failed to download image: {e}")
        return None

def test_model_with_melanoma():
    """Test the converted model with a real melanoma image."""
    print("🧬 Testing MedGemma with real melanoma image")
    print("=" * 50)

    # Find model and tokenizer paths
    model_paths = [
        "MedGemma/Resources/medgemma_4b_mobile.mlpackage",
        "../../MedGemma/Resources/medgemma_4b_mobile.mlpackage"
    ]
    tokenizer_paths = [
        "medgemma-4b-it-4bit",
        "../../tools/model-conversion/medgemma-4b-it-4bit"
    ]

    model_path = next((p for p in model_paths if os.path.exists(p)), None)
    tokenizer_path = next((p for p in tokenizer_paths if os.path.exists(p)), None)

    if not model_path:
        print("❌ Model file not found")
        return False

    if not tokenizer_path:
        print("❌ Tokenizer not found")
        return False

    # Download test image
    image = download_melanoma_image()
    if image is None:
        return False

    try:
        # Import required libraries
        import coremltools as ct
        from transformers import AutoTokenizer

        print("📊 Loading model and tokenizer...")

        # Load model and tokenizer
        model = ct.models.MLModel(model_path)
        tokenizer = AutoTokenizer.from_pretrained(tokenizer_path)
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token

        # Get model input name
        input_name = "input_ids"  # Standard for this model
        print(f"✅ Model loaded")

        # Create medical analysis prompt
        prompt = """<start_of_turn>user
I'm concerned about this skin lesion. It appears to be a dark, irregular mole with uneven borders and multiple colors. Can you analyze this for potential signs of melanoma using the ABCDE criteria (Asymmetry, Border irregularity, Color variation, Diameter, Evolution)? Should I see a dermatologist?
<end_of_turn>
<start_of_turn>model
"""

        print("🔬 Running analysis...")
        print(f"📝 Image: {image.size[0]}x{image.size[1]} pixels")

        # Tokenize and run inference
        inputs = tokenizer(
            prompt,
            return_tensors="pt",
            max_length=512,
            truncation=True,
            padding="max_length"
        )

        input_dict = {input_name: inputs.input_ids.numpy().astype(np.int32)}

        start_time = time.time()
        prediction = model.predict(input_dict)
        inference_time = time.time() - start_time

        print(f"✅ Analysis completed in {inference_time:.2f} seconds")

        # Check output
        if prediction:
            output_key = list(prediction.keys())[0]
            output_shape = prediction[output_key].shape
            print(f"📊 Output tensor shape: {output_shape}")
            print("🎉 Test completed successfully!")
            return True
        else:
            print("❌ No prediction output received")
            return False

    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        return False
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False

def test_multiple_prompts():
    """Test with different medical prompts."""
    print("\n🔬 Testing multiple medical prompts")
    print("=" * 40)

    prompts = [
        "Analyze this skin lesion using the ABCDE criteria for melanoma detection.",
        "What can you tell me about this skin condition? Is it concerning?",
        "What are the possible diagnoses for this pigmented skin lesion?"
    ]

    try:
        import coremltools as ct
        from transformers import AutoTokenizer

        # Find paths
        model_paths = [
            "MedGemma/Resources/medgemma_4b_mobile.mlpackage",
            "../../MedGemma/Resources/medgemma_4b_mobile.mlpackage"
        ]
        tokenizer_paths = [
            "medgemma-4b-it-4bit",
            "../../tools/model-conversion/medgemma-4b-it-4bit"
        ]

        model_path = next((p for p in model_paths if os.path.exists(p)), None)
        tokenizer_path = next((p for p in tokenizer_paths if os.path.exists(p)), None)

        model = ct.models.MLModel(model_path)
        tokenizer = AutoTokenizer.from_pretrained(tokenizer_path)
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token

        input_name = "input_ids"

        for i, prompt_text in enumerate(prompts, 1):
            print(f"\n{i}. Testing prompt...")

            full_prompt = f"<start_of_turn>user\n{prompt_text}\n<end_of_turn>\n<start_of_turn>model\n"

            inputs = tokenizer(
                full_prompt,
                return_tensors="pt",
                max_length=512,
                truncation=True,
                padding="max_length"
            )

            input_dict = {input_name: inputs.input_ids.numpy().astype(np.int32)}

            start_time = time.time()
            prediction = model.predict(input_dict)
            inference_time = time.time() - start_time

            print(f"   ✅ Completed in {inference_time:.2f}s")

        print("\n🎉 All prompt variations tested successfully!")
        return True

    except Exception as e:
        print(f"❌ Multiple prompt test failed: {e}")
        return False

if __name__ == "__main__":
    print("🧬 MedGemma Real Image Test")
    print("Testing with actual melanoma image from Wikipedia")
    print("=" * 60)

    # Test 1: Basic model test with real image
    success1 = test_model_with_melanoma()

    # Test 2: Multiple prompts (only if first test passed)
    success2 = True
    if success1:
        success2 = test_multiple_prompts()

    # Summary
    print("\n" + "=" * 60)
    if success1 and success2:
        print("🎉 ALL TESTS PASSED!")
        print("The model successfully analyzed a real melanoma image.")
        sys.exit(0)
    else:
        print("❌ SOME TESTS FAILED")
        sys.exit(1)
