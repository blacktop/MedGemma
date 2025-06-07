# MedGemma Model Conversion Tool

This directory contains the tools needed to convert Google's MedGemma 4B medical AI model from MLX format to CoreML format for use in the iOS app.

## Requirements

- Python 3.11+
- uv (Python package manager)
- macOS (for CoreML conversion)
- ~8GB of free disk space

## Usage

From the project root directory:

```bash
# Install dependencies
make setup

# Convert the model
make convert-model
```

Or run directly from this directory:

```bash
# Install dependencies
uv sync

# Run conversion
python convert_model.py
```

## What it does

1. Downloads the quantized MedGemma 4B model from Hugging Face
2. Converts from MLX format to PyTorch format
3. Converts from PyTorch to CoreML format
4. Outputs `medgemma_4b_mobile.mlpackage` for iOS

## Output

The converted model will be placed in:
`MedGemmaApp/MedGemmaApp/Resources/medgemma_4b_mobile.mlpackage`

## Notes

- The conversion process requires significant memory (~8GB)
- The final model is optimized for on-device inference
- Conversion only needs to be done once unless the model is updated