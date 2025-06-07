# MedGemma iOS App

A SwiftUI-based medical AI assistant powered by Google's MedGemma 4B model, running entirely on-device.

## Setup Instructions

1. **Open in Xcode**
   - Open `MedGemmaApp.xcodeproj` in Xcode 15+
   - Select your development team in project settings

2. **Add the CoreML Model**
   - Run the Python conversion script first: `python main.py`
   - Drag `medgemma_4b_mobile.mlpackage` into the Xcode project
   - Ensure "Copy items if needed" is checked
   - Add to target: MedGemmaApp

3. **Build and Run**
   - Select your target device (iPhone/iPad with iOS 17+)
   - Build and run (⌘R)

## Project Structure

```
MedGemmaApp/
├── Models/          # Data models and Core Data
├── Views/           # SwiftUI views
├── ViewModels/      # View models and business logic
├── Services/        # Model manager and persistence
├── Utils/           # Helper utilities
└── Resources/       # Assets and resources
```

## Features

- **Chat Interface**: Medical Q&A with AI
- **Symptom Checker**: Guided symptom analysis (planned)
- **Medical Reference**: Quick medical information (planned)
- **History**: Conversation persistence with Core Data
- **Privacy-First**: All processing on-device

## Requirements

- iOS 17.0+
- Xcode 15+
- ~3GB free space for model
- iPhone 12 or newer (recommended)

## Important Notes

- The app requires the converted CoreML model to function
- First launch may take time to load the model
- All data processing happens on-device
- This is not a replacement for professional medical advice