# Xcode Project Setup Instructions

## Creating the Xcode Project

1. Open Xcode
2. Choose "Create New Project" 
3. Select "iOS" → "App"
4. Configure:
   - Product Name: `MedGemmaApp`
   - Team: (Your development team)
   - Organization Identifier: `com.yourcompany` 
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Use Core Data: ❌ (Leave unchecked - we're using SwiftData)
   - Include Tests: ✅

## Adding the Files - IMPORTANT GOTCHAS:

### 1. **File Organization**
When adding files, maintain this structure in Xcode:
```
MedGemmaApp/
├── MedGemmaApp.swift (replace default)
├── Models/
│   ├── Message.swift
│   └── Conversation.swift
├── Views/
│   ├── ContentView.swift (replace default)
│   ├── ChatView.swift
│   ├── SymptomCheckerView.swift
│   ├── MedicalReferenceView.swift
│   ├── HistoryView.swift
│   └── SettingsView.swift
├── ViewModels/
│   └── ChatViewModel.swift
├── Services/
│   └── ModelManager.swift
└── Info.plist (will be auto-generated)
```

### 2. **SwiftData Setup**
- SwiftData is built into iOS 17+
- Models are defined as Swift classes with @Model macro
- No .xcdatamodeld files needed
- Persistence is handled automatically

### 3. **File Addition Steps**
1. Delete these auto-generated files first:
   - `ContentView.swift`
   - `Item.swift` (if present)

2. Create folder groups (not folder references):
   - Right-click project → New Group → name it (Models, Views, etc.)

3. Add each Swift file:
   - Right-click folder → New File → Swift File
   - Copy contents from our created files
   - OR drag files from Finder (ensure "Copy items if needed" is checked)

### 4. **Build Settings to Configure**
1. iOS Deployment Target: Set to iOS 17.0
2. Supported Destinations: iPhone, iPad
3. Info.plist: Already created, but Xcode will merge with its settings

### 5. **After Adding Files**
1. Build once (⌘B) to ensure no compilation errors
2. SwiftData models are automatically recognized
   - No need to generate managed object subclasses
   - @Model macro handles everything

### 6. **Adding the CoreML Model**
When ready to add `medgemma_4b_mobile.mlpackage`:
1. Drag the `.mlpackage` file (not .mlmodel) into the project
2. Ensure "Copy items if needed" is checked
3. Add to targets: MedGemmaApp
4. Check that it appears in Build Phases → Copy Bundle Resources

## Common Issues & Solutions

**Issue**: "Cannot find ContentView in scope"
**Solution**: Clean build folder (⌘⇧K) and rebuild

**Issue**: SwiftData models not recognized
**Solution**: Ensure iOS Deployment Target is 17.0+

**Issue**: SwiftUI previews not working
**Solution**: Disable previews initially, focus on simulator/device testing

## Testing the Setup
1. Run on simulator first (iPhone 15 Pro recommended)
2. Check that all tabs appear
3. Try sending a message in the chat (will show placeholder response)
4. Verify no crashes when switching tabs