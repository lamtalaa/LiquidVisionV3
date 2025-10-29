//
//  ClassificationViewModelTests.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import UIKit
import XCTest
@testable import LiquidVision

@MainActor
final class MockClassificationService: ImageClassificationServicing {
    var classifyCallCount = 0
    var result: Result<ClassificationResult, Error>

    init(result: Result<ClassificationResult, Error>) {
        self.result = result
    }

    func classify(image: UIImage) async throws -> ClassificationResult {
        classifyCallCount += 1
        return try result.get()
    }
}

@MainActor
final class MockSentimentService: SentimentAnalysisServicing {
    var analyzeCallCount = 0
    var result: Result<SentimentAnalysisResult, Error>
    var receivedTexts: [String] = []

    init(result: Result<SentimentAnalysisResult, Error>) {
        self.result = result
    }

    func analyze(text: String) async throws -> SentimentAnalysisResult {
        analyzeCallCount += 1
        receivedTexts.append(text)
        return try result.get()
    }
}

@MainActor
final class ClassificationViewModelTests: XCTestCase {
    func testHandleCapturedImageUpdatesPredictionAndSentiment() async throws {
        let classificationResult = ClassificationResult(identifier: "happy dog", confidence: 0.92)
        let classifier = MockClassificationService(result: .success(classificationResult))
        let sentimentResult = SentimentAnalysisResult(score: 0.8, sentiment: .positive)
        let sentimentService = MockSentimentService(result: .success(sentimentResult))
        let viewModel = ClassificationViewModel(classifier: classifier, sentimentService: sentimentService)
        let image = TestImageFactory.makeSolidColorImage()

        viewModel.handleCapturedImage(image)

        try await waitForCondition {
            classifier.classifyCallCount == 1 &&
            sentimentService.analyzeCallCount == 1 &&
            viewModel.state.isLoading == false &&
            viewModel.state.sentiment.isAnalyzing == false
        }

        XCTAssertEqual(viewModel.state.prediction, classificationResult.identifier.capitalized)
        XCTAssertEqual(viewModel.state.confidence, classificationResult.confidence, accuracy: 0.001)
        XCTAssertEqual(viewModel.state.sentiment.label, sentimentResult.sentiment.displayName)
        XCTAssertEqual(viewModel.state.sentiment.score, sentimentResult.score, accuracy: 0.001)
        XCTAssertNil(viewModel.state.sentiment.errorMessage)
        XCTAssertEqual(sentimentService.receivedTexts.last, classificationResult.identifier.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func testHandleCapturedImageClassificationFailure() async throws {
        let classifier = MockClassificationService(result: .failure(ImageClassificationError.noResult))
        let sentimentService = MockSentimentService(result: .success(SentimentAnalysisResult(score: 0.2, sentiment: .negative)))
        let viewModel = ClassificationViewModel(classifier: classifier, sentimentService: sentimentService)
        let image = TestImageFactory.makeSolidColorImage()

        viewModel.handleCapturedImage(image)

        try await waitForCondition {
            classifier.classifyCallCount == 1 && viewModel.state.isLoading == false
        }

        XCTAssertEqual(viewModel.state.errorMessage, ImageClassificationError.noResult.errorDescription)
        XCTAssertEqual(sentimentService.analyzeCallCount, 0)
        XCTAssertFalse(viewModel.state.sentiment.isAnalyzing)
        XCTAssertEqual(viewModel.state.sentiment.label, "")
        XCTAssertEqual(viewModel.state.sentiment.score, 0)
    }

    func testSentimentFailureSetsErrorMessage() async throws {
        let classificationResult = ClassificationResult(identifier: "uncertain", confidence: 0.45)
        let classifier = MockClassificationService(result: .success(classificationResult))
        let sentimentService = MockSentimentService(result: .failure(SentimentAnalysisError.noScore))
        let viewModel = ClassificationViewModel(classifier: classifier, sentimentService: sentimentService)
        let image = TestImageFactory.makeSolidColorImage()

        viewModel.handleCapturedImage(image)

        try await waitForCondition {
            sentimentService.analyzeCallCount == 1 && viewModel.state.sentiment.isAnalyzing == false
        }

        XCTAssertEqual(viewModel.state.sentiment.label, "")
        XCTAssertEqual(viewModel.state.sentiment.score, 0)
        XCTAssertEqual(viewModel.state.sentiment.errorMessage, SentimentAnalysisError.noScore.errorDescription)
    }

    func testPredictionSentimentSkipsWhenIdentifierIsBlank() async throws {
        let classificationResult = ClassificationResult(identifier: "   ", confidence: 0.5)
        let classifier = MockClassificationService(result: .success(classificationResult))
        let sentimentService = MockSentimentService(result: .success(SentimentAnalysisResult(score: 0.9, sentiment: .positive)))
        let viewModel = ClassificationViewModel(classifier: classifier, sentimentService: sentimentService)
        let image = TestImageFactory.makeSolidColorImage()

        viewModel.handleCapturedImage(image)

        try await waitForCondition {
            classifier.classifyCallCount == 1 && viewModel.state.sentiment.isAnalyzing == false
        }

        XCTAssertEqual(sentimentService.analyzeCallCount, 0)
        XCTAssertEqual(viewModel.state.sentiment.errorMessage, SentimentAnalysisError.emptyText.errorDescription)
        XCTAssertEqual(viewModel.state.sentiment.label, "")
        XCTAssertEqual(viewModel.state.sentiment.score, 0)
        XCTAssertFalse(viewModel.state.sentiment.isAnalyzing)
    }
}
