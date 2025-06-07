.PHONY: help setup convert-model clean-model build-app test lint

# Default target
help:
	@echo "MedGemma iOS App Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  setup              - Install all dependencies (Python and iOS)"
	@echo "  convert-model      - Convert MedGemma model to CoreML format"
	@echo "  build-app          - Build iOS app (warns if no model)"
	@echo "  build-with-model   - Convert model then build app"
	@echo "  all                - Full pipeline: setup + model + build"
	@echo "  clean-model        - Remove converted model files"
	@echo "  test               - Run all tests"
	@echo "  lint               - Run code linters"
	@echo ""
	@echo "Quick start:"
	@echo "  make setup         # One-time setup"
	@echo "  make build-with-model  # Build app with AI model"

# Setup development environment
setup:
	@echo "Setting up development environment..."
	@echo "Installing Python dependencies..."
	cd tools/model-conversion && uv sync
	@echo "✅ Setup complete"

# Convert the model to CoreML
MODEL_OUTPUT = MedGemma/Resources/medgemma_4b_mobile.mlpackage

convert-model:
	@echo "Converting MedGemma model to CoreML..."
	cd tools/model-conversion && python convert_model.py
	@echo "Moving model to iOS app resources..."
	mkdir -p MedGemma/Resources
	mv tools/model-conversion/medgemma_4b_mobile.mlpackage $(MODEL_OUTPUT)
	@echo "✅ Model conversion complete"

# Clean model files
clean-model:
	@echo "Cleaning model files..."
	rm -rf $(MODEL_OUTPUT)
	rm -rf tools/model-conversion/medgemma_4b_mobile.mlpackage
	rm -rf tools/model-conversion/mlx_model
	@echo "✅ Clean complete"

# Build iOS app
build-app:
	@echo "Building iOS app..."
	@if [ ! -f "$(MODEL_OUTPUT)" ]; then \
		echo "⚠️  Model not found. Run 'make convert-model' first to download and convert the AI model."; \
		echo "   The app will build but AI features won't work without the model."; \
	fi
	xcodebuild -project MedGemma.xcodeproj \
		-scheme MedGemma \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
		build
	@echo "✅ Build complete"

# Run tests
test:
	@echo "Running tests..."
	xcodebuild test -project MedGemma.xcodeproj \
		-scheme MedGemma \
		-destination 'platform=iOS Simulator,name=iPhone 16 Pro'
	@echo "✅ Tests complete"

# Run linters
lint:
	@echo "Running SwiftLint..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --path MedGemmaApp; \
	else \
		echo "SwiftLint not installed. Install with: brew install swiftlint"; \
	fi

# Build with model check
build-with-model: convert-model build-app
	@echo "✅ Complete build with model ready"

# Full build pipeline
all: setup convert-model build-app
	@echo "✅ Full build complete"

# Quick build (app only, warns if no model)
build: build-app