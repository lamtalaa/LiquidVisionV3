//
//  SentimentViewModel.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import Foundation
import SwiftUI

struct SentimentViewState {
    var inputText: String = ""
    var sentimentLabel: String
    var sentimentScore: Double = 0
    var isAnalyzing = false
    var errorMessage: String?
}

final class SentimentViewModel: ObservableObject {
    @Published private(set) var state: SentimentViewState

    private let service: SentimentAnalysisServicing
    private let defaultLabel = "Enter text and tap Analyze"
    private let analyzingLabel = "Analyzing..."

    init(service: SentimentAnalysisServicing = SentimentAnalysisService()) {
        self.service = service
        self.state = SentimentViewState(sentimentLabel: defaultLabel)
    }

    var hasResult: Bool {
        state.sentimentLabel != defaultLabel &&
        state.sentimentLabel != analyzingLabel &&
        state.sentimentLabel.isEmpty == false
    }

    @MainActor
    func binding<Value>(_ keyPath: WritableKeyPath<SentimentViewState, Value>) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { newValue in self.state[keyPath: keyPath] = newValue }
        )
    }

    @MainActor
    func analyze() {
        let trimmed = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.isEmpty == false else {
            state.isAnalyzing = false
            state.errorMessage = SentimentAnalysisError.emptyText.errorDescription
            state.sentimentLabel = defaultLabel
            state.sentimentScore = 0
            return
        }

        state.isAnalyzing = true
        state.errorMessage = nil
        state.sentimentLabel = analyzingLabel

        Task { [weak self] in
            guard let self else { return }

            do {
                let result = try await self.service.analyze(text: trimmed)
                await MainActor.run {
                    self.state.sentimentScore = result.score
                    self.state.sentimentLabel = result.sentiment.displayName
                    self.state.isAnalyzing = false
                }
            } catch let error as SentimentAnalysisError {
                await MainActor.run {
                    self.state.isAnalyzing = false
                    self.state.errorMessage = error.errorDescription
                    self.state.sentimentLabel = self.defaultLabel
                    self.state.sentimentScore = 0
                }
            } catch {
                await MainActor.run {
                    self.state.isAnalyzing = false
                    self.state.errorMessage = error.localizedDescription
                    self.state.sentimentLabel = self.defaultLabel
                    self.state.sentimentScore = 0
                }
            }
        }
    }

    @MainActor
    private func updateState(_ mutate: (inout SentimentViewState) -> Void) {
        mutate(&state)
    }
}
