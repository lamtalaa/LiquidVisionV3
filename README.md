
# LiquidVision

## Overview
LiquidVision is a SwiftUI iOS application that classifies images with Core ML, evaluates sentiment with Apple’s Natural Language framework, and offers an audio lab that performs on-device speech transcription alongside ambient sound classification. A dedicated root tab view works alongside lightweight coordinators to keep UI, state, and navigation responsibilities clearly separated.

## Tech Stack
- Swift 5.10
- SwiftUI & PhotosUI
- Core ML (MobileNetV2)
- Apple Natural Language (NLTagger + Sentiment)
- Vision (VNCoreMLRequest)
- AVFoundation (Audio capture + file handling)
- SoundAnalysis (Built-in environmental classifier)
- Speech (On-device SFSpeechRecognizer)
- XCTest

## Architecture
LiquidVision follows an MVVM flow supported by slim coordinators:
- **Model / Services**: `ImageClassificationServicing`, `SentimentAnalysisServicing`, `AudioFileAnalyzing`, `LiveAudioAnalyzing`, and `AudioAnalysisLogging` encapsulate ML, NLP, and audio responsibilities.
- **ViewModel**: `ClassificationViewModel`, `SentimentViewModel`, and `AudioAnalyzerViewModel` expose focused state structs so async updates stay consistent.
- **View**: SwiftUI views render that state, own presentation concerns (camera sheets, pickers, file importers), and use key-path bindings for clarity.
- **Coordinator**: `AppCoordinator`, `ClassificationCoordinator`, `SentimentCoordinator`, and `AudioAnalyzerCoordinator` focus purely on dependency wiring while `LiquidVisionRootView` owns the tab layout.

This separation keeps business logic testable, avoids constructing views inside coordinators, and aligns with the Core ML feedback on SRP.

## Project Structure
```
LiquidVision/
├── Coordinators/
│   ├── AppCoordinator.swift
│   ├── AudioAnalyzerCoordinator.swift
│   ├── ClassificationCoordinator.swift
│   └── SentimentCoordinator.swift
├── Services/
│   ├── Audio/
│   │   ├── AudioAnalysisLogger.swift
│   │   ├── AudioAnalysisModels.swift
│   │   ├── AudioFileAnalyzer.swift
│   │   ├── LiveAudioAnalyzer.swift
│   │   ├── SoundClassificationService.swift
│   │   └── SpeechRecognitionService.swift
│   ├── ImageClassificationService.swift
│   └── SentimentAnalysisService.swift
├── ViewModels/
│   ├── Audio/
│   │   └── AudioAnalyzerViewModel.swift
│   ├── ClassificationViewModel.swift
│   └── Sentiment/
│       └── SentimentViewModel.swift
├── Views/
│   ├── Audio/
│   │   └── AudioAnalyzerView.swift
│   ├── Classification/
│   │   └── ClassificationView.swift
│   ├── Root/
│   │   └── LiquidVisionRootView.swift
│   ├── Sentiment/
│   │   └── SentimentView.swift
│   └── Shared/
│       └── CameraView.swift
├── LiquidVisionApp.swift
└── Assets, ML model, and supporting files
```

Unit and UI tests live under `LiquidVisionTests/` and `LiquidVisionUITests/`.

## Features
- **Image Classification**: Pick or capture a photo and run MobileNetV2 inference with Vision + Core ML.
- **Sentiment Insight**: Analyze the predicted label’s sentiment asynchronously and surface score + polarity.
- **Audio Analyzer**: Import `.m4a` files or stream the microphone to generate on-device speech transcripts and the top three ambient sound classifications via SoundAnalysis.
- **Analysis Logging**: Persist every audio session to `analysis_log.json` in the app’s documents directory for auditing or support.
    - Set the `AUDIO_LOG_DIRECTORY` environment variable in your Xcode scheme (for example to `$(PROJECT_DIR)`) to mirror the log into your project folder during development.
- **Camera Support**: SwiftUI-friendly `CameraView` wrapper for `UIImagePickerController`.
- **Theming**: Gradient-backed, glassmorphism-inspired UI shared across features.
- **Root Tab Navigation**: Tab-based experience hosted in `LiquidVisionRootView` with coordinators limited to wiring dependencies.

## Example Usage
1. Launch LiquidVision on an iOS 16+ device or simulator.
2. Select **Vision** tab (default) and tap **Choose Photo** to pick from the library or **Capture Photo** to use the camera.
3. After the image is classified, review the predicted label, confidence, and sentiment summary for that prediction.
4. Switch to the **Sentiment** tab to manually enter text and analyze its polarity using the Natural Language framework.
5. Open the **Audio** tab to import an `.m4a` file from Files or start live analysis; review the running transcript and top three classifications, which are also appended to `analysis_log.json` in the app’s Documents directory.

## Testing
All critical layers are covered with XCTest:

```bash
xcodebuild test \
  -scheme LiquidVision \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES
```

Unit tests validate view-model behaviors, service error handling, and async flows across all three tabs; UI tests are currently optional while the interface evolves. Review the generated coverage report in Xcode’s Report navigator to confirm overall coverage stays at or above the 60% target.
