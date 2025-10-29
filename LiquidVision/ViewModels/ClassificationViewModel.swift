//
//  ClassificationViewModel.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import Foundation
import PhotosUI
import SwiftUI
import UIKit

struct ClassificationViewState {
    struct SentimentState {
        var label: String = ""
        var score: Double = 0
        var isAnalyzing = false
        var errorMessage: String?
    }

    var selectedImage: UIImage?
    var prediction: String = "Tap below to get started"
    var confidence: Double = 0
    var isLoading = false
    var errorMessage: String?
    var sentiment = SentimentState()
}

final class ClassificationViewModel: ObservableObject {
    @Published private(set) var state = ClassificationViewState()

    private let classifier: ImageClassificationServicing
    private let sentimentService: SentimentAnalysisServicing

    init(
        classifier: ImageClassificationServicing = MobileNetImageClassifier(),
        sentimentService: SentimentAnalysisServicing = SentimentAnalysisService()
    ) {
        self.classifier = classifier
        self.sentimentService = sentimentService
    }

    @MainActor
    func binding<Value>(_ keyPath: WritableKeyPath<ClassificationViewState, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in self.state[keyPath: keyPath] = newValue }
        )
    }

    func processPickedItem(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                await updateState { state in
                    state.errorMessage = "Unable to load image."
                }
                return
            }

            await updateState { state in
                state.selectedImage = uiImage
            }

            await classify(image: uiImage)
        } catch {
            await updateState { state in
                state.errorMessage = error.localizedDescription
            }
        }
    }

    func handleCapturedImage(_ image: UIImage) {
        Task {
            await updateState { state in
                state.selectedImage = image
            }
            await classify(image: image)
        }
    }

    private func classify(image: UIImage) async {
        await updateState { state in
            state.isLoading = true
            state.errorMessage = nil
            state.sentiment = ClassificationViewState.SentimentState(isAnalyzing: true)
        }

        do {
            let result = try await classifier.classify(image: image)

            await updateState { state in
                state.prediction = result.identifier.capitalized
                state.confidence = result.confidence
                state.isLoading = false
            }

            await analyzePredictionSentiment(for: result.identifier)
        } catch {
            await updateState { state in
                state.isLoading = false
                state.sentiment.isAnalyzing = false
                state.confidence = 0

                if let classificationError = error as? ImageClassificationError {
                    state.errorMessage = classificationError.errorDescription
                } else {
                    state.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func analyzePredictionSentiment(for text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.isEmpty == false else {
            await updateState { state in
                state.sentiment.errorMessage = SentimentAnalysisError.emptyText.errorDescription
                state.sentiment.label = ""
                state.sentiment.score = 0
                state.sentiment.isAnalyzing = false
            }
            return
        }

        do {
            let sentimentResult = try await sentimentService.analyze(text: trimmed)
            await updateState { state in
                state.sentiment.label = sentimentResult.sentiment.displayName
                state.sentiment.score = sentimentResult.score
                state.sentiment.errorMessage = nil
                state.sentiment.isAnalyzing = false
            }
        } catch let error as SentimentAnalysisError {
            await updateState { state in
                state.sentiment.errorMessage = error.errorDescription
                state.sentiment.label = ""
                state.sentiment.score = 0
                state.sentiment.isAnalyzing = false
            }
        } catch {
            await updateState { state in
                state.sentiment.errorMessage = error.localizedDescription
                state.sentiment.label = ""
                state.sentiment.score = 0
                state.sentiment.isAnalyzing = false
            }
        }
    }

    @MainActor
    private func updateState(_ mutate: (inout ClassificationViewState) -> Void) {
        mutate(&state)
    }
}
