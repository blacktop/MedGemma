# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MedGemma is an iOS application that uses Google's MedGemma 4B medical AI model for on-device skin condition analysis. Users can take photos of skin rashes, moles, or other dermatological concerns and receive AI-powered insights. The app includes supporting tools for converting the AI model from MLX format to CoreML format for iOS deployment.

## Development Commands

```bash
# Setup development environment (Python tools + iOS dependencies)
make setup

# Convert the MedGemma model to CoreML format (one-time setup)
make convert-model

# Build the iOS app
make build-app

# Run tests
make test

# Open in Xcode
open MedGemma.xcodeproj
```

## Architecture

### iOS App Structure
```
MedGemmaApp/
├── Models/              # SwiftData models for persistence
│   ├── Message.swift    # Chat message model
│   └── Conversation.swift # Conversation model
├── Views/               # SwiftUI views
│   ├── ChatView.swift   # Medical chat interface
│   ├── SkinAnalysisView.swift # Photo capture & analysis
│   ├── HistoryView.swift # Conversation history
│   └── ...
├── ViewModels/          # Business logic
│   ├── ChatViewModel.swift
│   └── SkinAnalysisViewModel.swift
└── Services/
    └── ModelManager.swift # CoreML model integration
```

### Model Conversion Pipeline
Located in `tools/model-conversion/`:

1. **Model Download**: Downloads MedGemma 4B from Hugging Face
2. **MLX to PyTorch**: Converts weight formats and mappings
3. **CoreML Conversion**: Creates optimized iOS model
4. **Integration**: Moves model to app resources

## Key Technical Details

- **Platform**: iOS 17+ with SwiftUI and SwiftData
- **AI Model**: MedGemma 4B IT 4-bit (medical-specific Gemma variant)
- **Privacy**: All processing happens on-device
- **Storage**: Local persistence with SwiftData
- **Model Size**: ~2.5GB CoreML package
- **Features**: Photo analysis, medical chat, conversation history