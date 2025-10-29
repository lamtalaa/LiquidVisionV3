🧠 LiquidVision — “Pairing Computer Vision With Real-Time Sentiment”

🚀 The Challenge
Blending image classification with natural-language sentiment inside one fluid SwiftUI experience felt like juggling two asynchronous pipelines. I wanted the app to snap a photo, understand what it saw, and instantly tell you how people usually feel about that subject — all without blocking the UI.

🔧 What I Built
LiquidVision is an on-device SwiftUI app that classifies images with MobileNetV2 through Vision/Core ML, then pipes the predicted label into Apple’s Natural Language framework for sentiment scoring. The latest update introduces a coordinator registry so new features can register themselves without touching `AppCoordinator`, keeping navigation wiring loosely coupled.

📚 What I Learned
Working on this release reinforced how much state discipline modern Swift concurrency expects. Highlights:
• Caching VNCoreMLModel instances in an actor to avoid repeating heavy initialization.
• Decoupling feature coordinators via type-erased factories so adding modules stays open-closed.
• Leaning on value-style `ViewState` structs to keep `@Published` state minimal and predictable.

🧰 Tech Stack & Architecture
This build leans on Swift 6-era tooling with MVVM + Coordinator boundaries.
• 🧩 Core ML + Vision for inference
• 💬 Natural Language for NLTagger sentiment scoring
• 🏗️ Coordinator registry that hands out view models via cached factories
• ⚙️ SwiftUI + PhotosUI for the capture-to-classify UI

🎬 Visual Snippet
Picture a glassy card UI: tap to choose a photo, LiquidVision surfaces “Golden Retriever” at 91% confidence, and seconds later the sentiment badge fades in with “Positive (0.82)”. A swipe to the Sentiment tab lets you test phrases live.

💭 Reflection
Refactoring the coordinators was a reminder that architectural debt creeps in quietly. Abstracting view-model factories into a registry gave me confidence the next tab or experiment can plug in without rewriting the app shell.

🔗 Call to Action
Curious how the coordinator registry works or want to jam on on-device ML? Dive into the repo or drop me a note — I’d love feedback from fellow SwiftUI + ML explorers.
👉 GitHub: https://github.com/lamtalaa/LiquidVisionV2
