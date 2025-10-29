//
//  SentimentViewModelTests.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/21/25.
//
import XCTest
@testable import LiquidVision

@MainActor
final class MockSentimentAnalysisService: SentimentAnalysisServicing {
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
final class SentimentViewModelTests: XCTestCase {
    func testAnalyzeSuccessUpdatesState() async throws {
        let mockResult = SentimentAnalysisResult(score: 0.75, sentiment: .positive)
        let service = MockSentimentAnalysisService(result: .success(mockResult))
        let viewModel = SentimentViewModel(service: service)
        viewModel.binding(\.inputText).wrappedValue = "Great experience!"

        viewModel.analyze()

        try await waitForCondition {
            service.analyzeCallCount == 1 && viewModel.state.isAnalyzing == false
        }

        XCTAssertEqual(viewModel.state.sentimentLabel, mockResult.sentiment.displayName)
        XCTAssertEqual(viewModel.state.sentimentScore, mockResult.score, accuracy: 0.001)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.hasResult)
        XCTAssertEqual(service.receivedTexts.last, "Great experience!")
    }

    func testAnalyzeSkipsWhenInputIsBlank() async throws {
        let service = MockSentimentAnalysisService(result: .success(SentimentAnalysisResult(score: 0.4, sentiment: .neutral)))
        let viewModel = SentimentViewModel(service: service)
        viewModel.binding(\.inputText).wrappedValue = ""

        viewModel.analyze()

        try await waitForCondition {
            viewModel.state.isAnalyzing == false
        }

        XCTAssertEqual(service.analyzeCallCount, 0)
        XCTAssertEqual(viewModel.state.errorMessage, SentimentAnalysisError.emptyText.errorDescription)
        XCTAssertFalse(viewModel.hasResult)
        XCTAssertEqual(viewModel.state.sentimentScore, 0)
        XCTAssertEqual(viewModel.state.sentimentLabel, "Enter text and tap Analyze")
    }

    func testAnalyzeTrimsWhitespaceBeforeSending() async throws {
        let mockResult = SentimentAnalysisResult(score: 0.2, sentiment: .negative)
        let service = MockSentimentAnalysisService(result: .success(mockResult))
        let viewModel = SentimentViewModel(service: service)
        viewModel.binding(\.inputText).wrappedValue = "   Needs improvement   "

        viewModel.analyze()

        try await waitForCondition {
            service.analyzeCallCount == 1 && viewModel.state.isAnalyzing == false
        }

        XCTAssertEqual(service.receivedTexts.last, "Needs improvement")
        XCTAssertEqual(viewModel.state.sentimentLabel, mockResult.sentiment.displayName)
    }
}
